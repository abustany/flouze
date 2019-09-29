use std::collections::HashMap;

use super::errors;
use super::model;

pub trait Repository {
    fn add_account(&mut self, account: &model::Account) -> errors::Result<()>;
    fn get_account(&self, account_id: &model::AccountId) -> errors::Result<model::Account>;
    fn delete_account(&mut self, account_id: &model::AccountId) -> errors::Result<()>;
    fn list_accounts(&self) -> errors::Result<Vec<model::Account>>;
    fn set_latest_transaction(&mut self, account_id: &model::AccountId, tx_id: &model::TransactionId) -> errors::Result<()>;
    fn set_latest_synchronized_transaction(&mut self, account_id: &model::AccountId, tx_id: &model::TransactionId) -> errors::Result<()>;

    fn add_transaction(&mut self, account_uuid: &model::AccountId, transaction: &model::Transaction) -> errors::Result<()>;
    fn get_transaction(&self, account_uuid: &model::AccountId, transaction_id: &model::TransactionId) -> errors::Result<model::Transaction>;
    fn delete_transaction(&mut self, account_uuid: &model::AccountId, transaction_id: &model::TransactionId) -> errors::Result<()>;
}

pub struct TransactionChain<'a> {
    repo: &'a dyn Repository,
    account_id: model::AccountId,
    id: model::TransactionId,
}

impl<'a> TransactionChain<'a> {
    fn new(repo: &'a dyn Repository, account_id: &model::AccountId, id: &model::TransactionId) -> TransactionChain<'a> {
        TransactionChain{
            repo: repo,
            account_id: account_id.to_owned(),
            id: id.to_owned()
        }
    }
}

impl<'a> Iterator for TransactionChain<'a> {
    type Item = errors::Result<model::Transaction>;

    fn next(&mut self) -> Option<errors::Result<model::Transaction>> {
        if self.id.is_empty() {
            return None;
        }

        let tx = match self.repo.get_transaction(&self.account_id, &self.id) {
            Err(e) => { return Some(Err(e.into())); },
            Ok(tx) => tx,
        };

        self.id = tx.parent.to_owned();

        Some(Ok(tx))
    }
}

pub fn get_transaction_chain<'a>(repo: &'a dyn Repository, account: &model::Account) -> TransactionChain<'a> {
    TransactionChain::new(repo, &account.uuid, &account.latest_transaction)
}

pub fn check_chain_consistency(transactions: &[&model::Transaction]) -> bool {
    if transactions.is_empty() {
        return true;
    }

    let mut base = &transactions[0].parent;

    for tx in transactions {
        if &tx.parent != base {
            return false;
        }

        base = &tx.uuid;
    }

    return true;
}

fn update_balance(balance: &mut HashMap<model::PersonId, i64>, payed_by: &[model::PayedBy], payed_for: &[model::PayedFor], factor: i64) {
    for p in payed_by {
        balance.get_mut(&p.person).map(|b| *b += p.amount as i64 * factor);
    }

    for p in payed_for {
        balance.get_mut(&p.person).map(|b| *b -= p.amount as i64 * factor);
    }
}

fn get_first_non_deleted_ancestor(repo: &dyn Repository, account: &model::Account, deleted: model::Transaction) -> errors::Result<model::Transaction> {
    let mut cur = deleted;

    loop {
        if cur.replaces.len() == 0 {
            return Err(errors::ErrorKind::NoSuchTransaction(cur.replaces.clone()).into());
        }

        cur = repo.get_transaction(&account.uuid, &cur.replaces)?;

        if !cur.deleted {
            break;
        }
    }

    Ok(cur)
}

pub fn get_balance(repo: &dyn Repository, account: &model::Account) -> errors::Result<HashMap<model::PersonId, i64>> {
    let mut balance: HashMap<model::PersonId, i64> = account.members.iter().map(|m| (m.uuid.clone(), 0)).collect();
    let chain = get_transaction_chain(repo, account);

    for tx in chain {
        let tx = tx?;

        if tx.replaces.len() > 0 || tx.deleted {
            if !tx.deleted {
                update_balance(&mut balance, &tx.payed_by, &tx.payed_for, 1);
            }

            let original = get_first_non_deleted_ancestor(repo, account, tx)?;
            update_balance(&mut balance, &original.payed_by, &original.payed_for, -1);

        } else {
            update_balance(&mut balance, &tx.payed_by, &tx.payed_for, 1);
        }
    }

    Ok(balance)
}

pub fn receive_transactions(repo: &mut dyn Repository, account_id: &model::AccountId, transactions: &[&model::Transaction]) -> errors::Result<()> {
    let account = repo.get_account(account_id)?;

    if transactions.is_empty() {
        return Ok(());
    }

    if account.latest_transaction != transactions[0].parent {
        return Err(errors::ErrorKind::MustRebase.into());
    }

    if !check_chain_consistency(transactions) {
        return Err(errors::ErrorKind::InconsistentChain.into());
    }

    for tx in transactions {
        repo.add_transaction(&account.uuid, tx.clone())?;
    }

    repo.set_latest_transaction(&account.uuid, &transactions.last().unwrap().uuid)?;

    Ok(())
}

pub fn get_child_transactions(repo: &dyn Repository, account_id: &model::AccountId, base: &model::TransactionId) -> errors::Result<Vec<model::Transaction>> {
    // Check that the base transaction ID is valid, else we'll get a
    // NoSuchTransaction error.
    if !base.is_empty() {
        repo.get_transaction(account_id, base)?;
    }

    let account = repo.get_account(account_id)?;
    let mut transactions: Vec<model::Transaction> = Vec::new();

    for tx in get_transaction_chain(repo, &account) {
        let tx = tx?;

        if &tx.uuid == base {
            break;
        }

        transactions.push(tx);
    }

    // Put the oldest transaction first
    transactions.reverse();

    Ok(transactions)
}

#[cfg(test)]
pub mod tests {
    use std::fmt::Debug;

    use super::*;

    pub fn expect_no_such_account<T: Debug>(r: errors::Result<T>) {
        match r {
            Err(errors::Error(errors::ErrorKind::NoSuchAccount(_), _)) => {},
            _ => { panic!("Expected NoSuchAccount error, got {:?}", r); }
        }
    }

    pub fn expect_no_such_transaction<T: Debug>(r: errors::Result<T>) {
        match r {
            Err(errors::Error(errors::ErrorKind::NoSuchTransaction(_), _)) => {},
            _ => { panic!("Expected NoSuchTransaction error, got {:?}", r); }
        }
    }

    pub fn make_test_account() -> model::Account {
        model::Account{
            uuid: model::generate_account_id(),
            label: "Test account".to_owned(),
            latest_transaction: vec!(),
            latest_synchronized_transaction: vec!(),
            members: vec!(model::Person{
                uuid: model::generate_person_id(),
                name: "Member 1".to_owned(),
            }, model::Person{
                uuid: model::generate_person_id(),
                name: "Member 2".to_owned(),
            }),
        }
    }

    pub fn make_test_transaction_1(account: &model::Account) -> model::Transaction {
         model::Transaction{
            uuid: model::generate_transaction_id(),
            parent: vec!(),
            amount: 35,
            payed_by: vec!(
                model::PayedBy{
                    person: account.members[0].uuid.to_owned(),
                    amount: 35,
                }
            ),
            payed_for: vec!(
                model::PayedFor{
                    person: account.members[0].uuid.to_owned(),
                    amount: 17,
                },
                model::PayedFor{
                    person: account.members[1].uuid.to_owned(),
                    amount: 18,
                },
            ),
            label: "Fish & Chips".to_owned(),
            timestamp: 1530288593,
            deleted: false,
            replaces: vec!(),
        }
    }

    pub fn make_test_transaction_2(account: &model::Account, parent: &model::TransactionId) -> model::Transaction {
         model::Transaction{
            uuid: model::generate_transaction_id(),
            parent: parent.to_owned(),
            amount: 10,
            payed_by: vec!(
                model::PayedBy{
                    person: account.members[1].uuid.to_owned(),
                    amount: 10,
                }
            ),
            payed_for: vec!(
                model::PayedFor{
                    person: account.members[0].uuid.to_owned(),
                    amount: 10,
                },
            ),
            label: "Book".to_owned(),
            timestamp: 1530289903,
            deleted: false,
            replaces: vec!(),
        }
    }

    pub fn make_test_transaction_3(parent: &model::TransactionId) -> model::Transaction {
         model::Transaction{
            uuid: model::generate_transaction_id(),
            parent: parent.to_owned(),
            amount: 0,
            payed_by: vec!(),
            payed_for: vec!(),
            label: "TX".to_owned(),
            timestamp: 0,
            deleted: false,
            replaces: vec!(),
        }
    }

    pub fn test_account_crud(repo: &mut dyn Repository) {
        let account = make_test_account();

        expect_no_such_account(repo.get_account(&account.uuid));
        assert_eq!(repo.list_accounts().unwrap(), vec!());
        repo.add_account(&account).unwrap();

        let mut fetched = repo.get_account(&account.uuid).unwrap();
        assert_eq!(fetched, account);
        assert_eq!(repo.list_accounts().unwrap(), vec!(account.clone()));

        fetched.label = "New fancy name".to_owned();
        repo.add_account(&fetched).unwrap();

        let fetched2 = repo.get_account(&account.uuid).unwrap();
        assert_eq!(fetched2, fetched);

        expect_no_such_account(repo.delete_account(&model::generate_account_id()));
        repo.delete_account(&account.uuid).unwrap();
        expect_no_such_account(repo.delete_account(&account.uuid));
        expect_no_such_account(repo.get_account(&account.uuid));
    }

    pub fn test_transaction_insert(repo: &mut dyn Repository) {
        let account = make_test_account();
        repo.add_account(&account).unwrap();

        let tx = make_test_transaction_1(&account);

        expect_no_such_transaction(repo.get_transaction(&account.uuid, &tx.uuid));
        repo.add_transaction(&account.uuid, &tx).unwrap();

        let mut fetched = repo.get_transaction(&account.uuid, &tx.uuid).unwrap();
        assert_eq!(fetched, tx);

        fetched.timestamp = 1530289104;
        repo.add_transaction(&account.uuid, &fetched).unwrap();

        let fetched2 = repo.get_transaction(&account.uuid, &tx.uuid).unwrap();
        assert_eq!(fetched2, fetched);
    }

    pub fn test_transaction_chain(repo: &mut dyn Repository) {
        let mut account = make_test_account();
        repo.add_account(&account).unwrap();

        {
            let mut chain = get_transaction_chain(repo, &account);
            assert!(chain.next().is_none());
        }

        let tx1 = make_test_transaction_1(&account);

        {
            repo.add_transaction(&account.uuid, &tx1).unwrap();
            account.latest_transaction = tx1.uuid.to_owned();

            let mut chain = get_transaction_chain(repo, &account);
            assert_eq!(chain.next().unwrap().unwrap(), tx1);
            assert!(chain.next().is_none());
        }

        let tx2 = make_test_transaction_2(&account, &tx1.uuid);

        {
            repo.add_transaction(&account.uuid, &tx2).unwrap();
            account.latest_transaction = tx2.uuid.to_owned();

            let mut chain = get_transaction_chain(repo, &account);
            assert_eq!(chain.next().unwrap().unwrap(), tx2);
            assert_eq!(chain.next().unwrap().unwrap(), tx1);
            assert!(chain.next().is_none());
        }
    }

    #[test]
    fn test_check_chain_consistency() {
        let account = make_test_account();
        let tx1 = make_test_transaction_1(&account);
        let tx2 = make_test_transaction_2(&account, &tx1.uuid);
        let tx3 = make_test_transaction_3(&tx2.uuid);

        assert_eq!(check_chain_consistency(&vec!()), true);
        assert_eq!(check_chain_consistency(&vec!(&tx1, &tx2, &tx3)), true);
        assert_eq!(check_chain_consistency(&vec!(&tx2, &tx3)), true);
        assert_eq!(check_chain_consistency(&vec!(&tx1)), true);
        assert_eq!(check_chain_consistency(&vec!(&tx1, &tx3)), false);
    }

    pub fn test_balance(repo: &mut dyn Repository) {
        let mut account = make_test_account();
        let tx1 = make_test_transaction_1(&account);
        let tx2 = make_test_transaction_2(&account, &tx1.uuid);

        repo.add_account(&account).unwrap();
        repo.add_transaction(&account.uuid, &tx1).unwrap();
        repo.add_transaction(&account.uuid, &tx2).unwrap();
        account.latest_transaction = tx2.uuid.to_owned();

        let balance = get_balance(repo, &account).unwrap();
        assert_eq!(balance.get(&account.members[0].uuid).unwrap(), &8);
        assert_eq!(balance.get(&account.members[1].uuid).unwrap(), &-8);

        let mut tx1_edit = tx1.clone();
        tx1_edit.uuid = model::generate_transaction_id();
        tx1_edit.parent = tx2.uuid.clone();
        tx1_edit.amount = 25;
        tx1_edit.payed_by[0].amount = 25;
        tx1_edit.payed_for[0].amount = 12;
        tx1_edit.payed_for[1].amount = 13;
        tx1_edit.replaces = tx1.uuid.clone();
        repo.add_transaction(&account.uuid, &tx1_edit).unwrap();
        account.latest_transaction = tx1_edit.uuid.to_owned();

        let balance = get_balance(repo, &account).unwrap();
        assert_eq!(balance.get(&account.members[0].uuid).unwrap(), &3);
        assert_eq!(balance.get(&account.members[1].uuid).unwrap(), &-3);
    }
}
