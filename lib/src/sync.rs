use super::errors;
use super::model;
use super::remote::Remote;
use super::repository::{check_chain_consistency, get_transaction_chain, Repository};

fn rebase_local_transactions(
    local: &mut dyn Repository,
    remote: &dyn Remote,
    account: &mut model::Account,
) -> errors::Result<()> {
    let latest_remote = remote.get_latest_transaction(&account.uuid)?;
    debug!(
        "Latest remote transaction is {}",
        model::IdAsHex(&latest_remote)
    );

    if account.latest_synchronized_transaction == latest_remote {
        debug!("... same as our latest_synchronized_transaction, all done");
        return Ok(());
    }

    let remote_transactions =
        remote.get_child_transactions(&account.uuid, &account.latest_synchronized_transaction)?;

    if remote_transactions.is_empty() {
        return Err(errors::ErrorKind::InconsistentServerResponse.into());
    }

    check_transaction_id_uniqueness(
        local,
        &account.uuid,
        &remote_transactions
            .iter()
            .map(|tx| &tx.uuid)
            .collect::<Vec<&model::TransactionId>>(),
    )?;

    if !check_chain_consistency(
        &remote_transactions
            .iter()
            .map(|tx| tx)
            .collect::<Vec<&model::Transaction>>(),
    ) {
        return Err(errors::ErrorKind::InconsistentChain.into());
    }

    debug!(
        "Received {} transactions from remote, rebasing local transactions",
        remote_transactions.len()
    );

    let (rebased_transactions, old_transaction_ids) =
        rebase_transactions(local, &account, &remote_transactions.last().unwrap().uuid)?;
    let latest_id = rebased_transactions
        .last()
        .or(remote_transactions.last())
        .map(|tx| tx.uuid.clone())
        .unwrap();
    let latest_synchronized_id = rebased_transactions
        .first()
        .map(|tx| tx.parent.clone())
        .unwrap_or(remote_transactions.last().unwrap().uuid.clone());

    for tx in remote_transactions {
        debug!(
            "Adding remote transaction {} (parent: {})",
            model::IdAsHex(&tx.uuid),
            model::IdAsHex(&tx.parent)
        );
        local.add_transaction(&account.uuid, &tx)?;
    }

    for tx in rebased_transactions {
        debug!(
            "Adding rebased transaction {} (parent: {})",
            model::IdAsHex(&tx.uuid),
            model::IdAsHex(&tx.parent)
        );
        local.add_transaction(&account.uuid, &tx)?;
    }

    debug!(
        "Setting latest transaction to {}",
        model::IdAsHex(&latest_id)
    );
    debug!(
        "Setting latest synchronized transaction to {}",
        model::IdAsHex(&latest_synchronized_id)
    );
    account.latest_transaction = latest_id;
    account.latest_synchronized_transaction = latest_synchronized_id;
    local.add_account(&account)?;

    for id in old_transaction_ids {
        debug!("Garbage collecting old transaction {}", model::IdAsHex(&id));
        local.delete_transaction(&account.uuid, &id)?;
    }

    Ok(())
}

fn check_transaction_id_uniqueness(
    repo: &dyn Repository,
    account_id: &model::AccountId,
    ids: &[&model::TransactionId],
) -> errors::Result<()> {
    for id in ids {
        match repo.get_transaction(account_id, id) {
            Err(errors::Error(errors::ErrorKind::NoSuchTransaction(_), _)) => {
                continue;
            }
            Ok(_) => {
                return Err(
                    errors::ErrorKind::DuplicateTransactionId(id.to_owned().to_vec()).into(),
                );
            }
            Err(e) => {
                return Err(e);
            }
        }
    }

    return Ok(());
}

pub fn sync(
    local: &mut dyn Repository,
    remote: &mut dyn Remote,
    account_id: &model::AccountId,
) -> errors::Result<()> {
    let mut account = local.get_account(account_id)?;

    debug!("Fetching remote transactions and rebasing local ones");
    rebase_local_transactions(local, remote, &mut account)?;

    let mut local_transactions: Vec<model::Transaction> = Vec::new();

    for tx in get_transaction_chain(local, &account) {
        let tx = tx?;

        if &tx.uuid == &account.latest_synchronized_transaction {
            break;
        }

        local_transactions.push(tx);
    }

    debug!(
        "{} transaction(s) to push to the remote",
        local_transactions.len()
    );

    if local_transactions.is_empty() {
        return Ok(());
    }

    // We must send the transactions in chronological order
    local_transactions.reverse();
    let local_transactions_refs: Vec<&model::Transaction> =
        local_transactions.iter().map(|tx| tx).collect();

    remote.receive_transactions(&account.uuid, &local_transactions_refs)?;

    debug!("Transactions sent, updating local state");
    local.set_latest_synchronized_transaction(&account.uuid, &account.latest_transaction)?;
    account.latest_synchronized_transaction = account.latest_transaction.clone();
    local.add_account(&account)?;

    Ok(())
}

pub fn clone_remote(
    local: &mut dyn Repository,
    remote: &mut dyn Remote,
    account_id: &model::AccountId,
) -> errors::Result<()> {
    let mut account = remote.get_account_info(account_id)?;
    account.latest_transaction = vec![];
    account.latest_synchronized_transaction = vec![];
    local.add_account(&account)?;
    sync(local, remote, account_id)
}

fn rebase_transactions(
    repo: &dyn Repository,
    account: &model::Account,
    new_base: &model::TransactionId,
) -> errors::Result<(Vec<model::Transaction>, Vec<model::TransactionId>)> {
    let mut to_rebase: Vec<model::Transaction> = Vec::new();
    let mut rebased: Vec<model::Transaction> = Vec::new();
    let mut old_ids: Vec<model::TransactionId> = Vec::new();
    let mut parent = new_base.clone();

    debug!(
        "Rebasing local transactions from {} onto {}",
        model::IdAsHex(&account.latest_synchronized_transaction),
        model::IdAsHex(&new_base)
    );

    for tx in get_transaction_chain(repo, account) {
        let tx = tx?;

        if &tx.uuid == &account.latest_synchronized_transaction {
            break;
        }

        to_rebase.push(tx);
    }

    // We want to rebase from the oldest to the newest
    to_rebase.reverse();

    for mut tx in to_rebase {
        let new_id = model::generate_transaction_id();

        debug!(
            "Rebasing transaction {} (old parent: {}) as {} on top of {}",
            model::IdAsHex(&tx.uuid),
            model::IdAsHex(&tx.parent),
            model::IdAsHex(&new_id),
            model::IdAsHex(&parent)
        );

        old_ids.push(tx.uuid);
        tx.uuid = new_id.to_owned();
        tx.parent = parent;
        parent = new_id;

        rebased.push(tx);
    }

    Ok((rebased, old_ids))
}

#[cfg(test)]
mod tests {
    extern crate env_logger;

    use super::super::localremote::LocalRemote;
    use super::super::sledrepository::SledRepository;
    use super::*;

    fn make_account() -> model::Account {
        model::Account {
            uuid: model::generate_account_id(),
            label: "Account".to_owned(),
            latest_transaction: vec![],
            latest_synchronized_transaction: vec![],
            members: vec![],
        }
    }

    fn make_transaction(parent: &model::TransactionId) -> model::Transaction {
        model::Transaction {
            uuid: model::generate_transaction_id(),
            parent: parent.clone(),
            amount: 0,
            payed_by: vec![],
            payed_for: vec![],
            label: "".to_owned(),
            timestamp: 0,
            deleted: false,
            replaces: vec![],
        }
    }

    #[test]
    fn test_sync_initial_pull() {
        let _ = env_logger::try_init();

        let mut account = make_account();
        let mut local_repo = SledRepository::temporary().unwrap();
        let mut remote_repo = SledRepository::temporary().unwrap();

        local_repo.add_account(&account).unwrap();
        remote_repo.add_account(&account).unwrap();

        let tx1 = make_transaction(&vec![]);
        let tx2 = make_transaction(&tx1.uuid);
        let tx3 = make_transaction(&tx2.uuid);

        remote_repo.add_transaction(&account.uuid, &tx1).unwrap();
        remote_repo.add_transaction(&account.uuid, &tx2).unwrap();
        remote_repo.add_transaction(&account.uuid, &tx3).unwrap();
        remote_repo
            .set_latest_transaction(&account.uuid, &tx3.uuid)
            .unwrap();

        let mut remote = LocalRemote::new(&mut remote_repo);

        sync(&mut local_repo, &mut remote, &account.uuid).unwrap();
        account = local_repo.get_account(&account.uuid).unwrap();
        assert_eq!(&account.latest_transaction, &tx3.uuid);
        assert_eq!(&account.latest_synchronized_transaction, &tx3.uuid);
        assert_eq!(
            &remote.get_latest_transaction(&account.uuid).unwrap(),
            &tx3.uuid
        );
    }

    #[test]
    fn test_sync_initial_push() {
        let _ = env_logger::try_init();

        let mut account = make_account();
        let mut local_repo = SledRepository::temporary().unwrap();
        let mut remote_repo = SledRepository::temporary().unwrap();

        local_repo.add_account(&account).unwrap();
        remote_repo.add_account(&account).unwrap();

        let mut remote = LocalRemote::new(&mut remote_repo);
        let tx1 = make_transaction(&vec![]);
        let tx2 = make_transaction(&tx1.uuid);
        let tx3 = make_transaction(&tx2.uuid);

        local_repo.add_transaction(&account.uuid, &tx1).unwrap();
        local_repo.add_transaction(&account.uuid, &tx2).unwrap();
        local_repo.add_transaction(&account.uuid, &tx3).unwrap();
        local_repo
            .set_latest_transaction(&account.uuid, &tx3.uuid)
            .unwrap();

        sync(&mut local_repo, &mut remote, &account.uuid).unwrap();
        account = local_repo.get_account(&account.uuid).unwrap();
        assert_eq!(&account.latest_transaction, &tx3.uuid);
        assert_eq!(&account.latest_synchronized_transaction, &tx3.uuid);
        assert_eq!(
            &remote.get_latest_transaction(&account.uuid).unwrap(),
            &tx3.uuid
        );
    }

    #[test]
    fn test_sync_append_transactions() {
        let _ = env_logger::try_init();

        let mut account = make_account();
        let mut local_repo = SledRepository::temporary().unwrap();
        let mut remote_repo = SledRepository::temporary().unwrap();

        local_repo.add_account(&account).unwrap();
        remote_repo.add_account(&account).unwrap();

        let tx1 = make_transaction(&vec![]);
        let tx2 = make_transaction(&tx1.uuid);
        let tx3 = make_transaction(&tx2.uuid);

        local_repo.add_transaction(&account.uuid, &tx1).unwrap();
        remote_repo.add_transaction(&account.uuid, &tx1).unwrap();
        local_repo.add_transaction(&account.uuid, &tx2).unwrap();
        remote_repo.add_transaction(&account.uuid, &tx2).unwrap();
        remote_repo
            .set_latest_transaction(&account.uuid, &tx2.uuid)
            .unwrap();
        local_repo.add_transaction(&account.uuid, &tx3).unwrap();
        local_repo
            .set_latest_transaction(&account.uuid, &tx3.uuid)
            .unwrap();
        local_repo
            .set_latest_synchronized_transaction(&account.uuid, &tx2.uuid)
            .unwrap();

        let mut remote = LocalRemote::new(&mut remote_repo);

        sync(&mut local_repo, &mut remote, &account.uuid).unwrap();
        account = local_repo.get_account(&account.uuid).unwrap();
        assert_eq!(&account.latest_transaction, &tx3.uuid);
        assert_eq!(&account.latest_synchronized_transaction, &tx3.uuid);
        assert_eq!(
            &remote.get_latest_transaction(&account.uuid).unwrap(),
            &tx3.uuid
        );
    }

    #[test]
    fn test_sync_empty() {
        let _ = env_logger::try_init();

        let mut account = make_account();
        let mut local_repo = SledRepository::temporary().unwrap();
        let mut remote_repo = SledRepository::temporary().unwrap();

        local_repo.add_account(&account).unwrap();
        remote_repo.add_account(&account).unwrap();

        let mut remote = LocalRemote::new(&mut remote_repo);

        sync(&mut local_repo, &mut remote, &account.uuid).unwrap();
        account = local_repo.get_account(&account.uuid).unwrap();
        assert_eq!(&account.latest_transaction, &model::INVALID_ID);
        assert_eq!(&account.latest_synchronized_transaction, &model::INVALID_ID);
        assert_eq!(
            &remote.get_latest_transaction(&account.uuid).unwrap(),
            &model::INVALID_ID
        );
    }

    #[test]
    fn test_sync_rebase() {
        let _ = env_logger::try_init();

        let mut account = make_account();
        let mut local_repo = SledRepository::temporary().unwrap();
        let mut remote_repo = SledRepository::temporary().unwrap();

        local_repo.add_account(&account).unwrap();
        remote_repo.add_account(&account).unwrap();

        let tx1 = make_transaction(&vec![]);
        let tx2 = make_transaction(&tx1.uuid);
        let tx3 = make_transaction(&tx1.uuid);

        local_repo.add_transaction(&account.uuid, &tx1).unwrap();
        local_repo.add_transaction(&account.uuid, &tx2).unwrap();
        remote_repo.add_transaction(&account.uuid, &tx1).unwrap();
        remote_repo.add_transaction(&account.uuid, &tx3).unwrap();
        local_repo
            .set_latest_transaction(&account.uuid, &tx2.uuid)
            .unwrap();
        remote_repo
            .set_latest_transaction(&account.uuid, &tx3.uuid)
            .unwrap();
        local_repo
            .set_latest_synchronized_transaction(&account.uuid, &tx1.uuid)
            .unwrap();

        let mut remote = LocalRemote::new(&mut remote_repo);

        sync(&mut local_repo, &mut remote, &account.uuid).unwrap();
        account = local_repo.get_account(&account.uuid).unwrap();
    }
}
