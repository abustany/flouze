use super::errors;
use super::model;
use super::remote::{Remote};
use super::repository::{Repository, check_chain_consistency, get_transaction_chain};

pub struct LocalRemote<'a> {
    repo: &'a mut Repository,
}

impl<'a> LocalRemote<'a> {
    pub fn new(repo: &'a mut Repository) -> LocalRemote<'a> {
        LocalRemote{ repo }
    }
}

impl<'a> Remote for LocalRemote<'a> {
    fn get_latest_transaction(&self, account_id: &model::AccountId) -> errors::Result<model::TransactionId> {
        let account = self.repo.get_account(account_id)?;
        Ok(account.latest_transaction.clone())
    }

    fn receive_transactions(&mut self, account_id: &model::AccountId, transactions: &[&model::Transaction]) -> errors::Result<()> {
        let account = self.repo.get_account(account_id)?;

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
            self.repo.add_transaction(&account.uuid, tx.clone())?;
        }

        self.repo.set_latest_transaction(&account.uuid, &transactions.last().unwrap().uuid)?;

        Ok(())
    }

    fn get_child_transactions(&self, account_id: &model::AccountId, base: &model::TransactionId) -> errors::Result<Vec<model::Transaction>> {
        // Check that the base transaction ID is valid, else we'll get a
        // NoSuchTransaction error.
        if !base.is_empty() {
            self.repo.get_transaction(account_id, base)?;
        }

        let account = self.repo.get_account(account_id)?;
        let mut transactions: Vec<model::Transaction> = Vec::new();

        for tx in get_transaction_chain(self.repo, &account) {
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
}

#[cfg(test)]
mod tests {
    use super::*;
    use super::super::sledrepository::{SledRepository};
    use super::super::remote::tests;

    #[test]
    fn test_initial_sync_to_remote() {
        let mut remote_repo = SledRepository::temporary().unwrap();
        let account = tests::test_initial_sync_to_remote_prepare_repo(&mut remote_repo);
        let mut remote = LocalRemote::new(&mut remote_repo);
        tests::test_initial_sync_to_remote(&mut remote, &account.uuid);
    }
}
