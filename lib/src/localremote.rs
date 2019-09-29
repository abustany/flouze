use super::errors;
use super::model;
use super::remote::Remote;
use super::repository::{get_child_transactions, receive_transactions, Repository};

pub struct LocalRemote<'a> {
    repo: &'a mut dyn Repository,
}

impl<'a> LocalRemote<'a> {
    pub fn new(repo: &'a mut dyn Repository) -> LocalRemote<'a> {
        LocalRemote { repo }
    }
}

impl<'a> Remote for LocalRemote<'a> {
    fn create_account(&mut self, account: &model::Account) -> errors::Result<()> {
        self.repo.add_account(account)
    }

    fn get_account_info(&self, account_id: &model::AccountId) -> errors::Result<model::Account> {
        self.repo.get_account(account_id)
    }

    fn get_latest_transaction(
        &self,
        account_id: &model::AccountId,
    ) -> errors::Result<model::TransactionId> {
        let account = self.repo.get_account(account_id)?;
        Ok(account.latest_transaction.clone())
    }

    fn receive_transactions(
        &mut self,
        account_id: &model::AccountId,
        transactions: &[&model::Transaction],
    ) -> errors::Result<()> {
        receive_transactions(self.repo, account_id, transactions)
    }

    fn get_child_transactions(
        &self,
        account_id: &model::AccountId,
        base: &model::TransactionId,
    ) -> errors::Result<Vec<model::Transaction>> {
        get_child_transactions(self.repo, account_id, base)
    }
}

#[cfg(test)]
mod tests {
    use super::super::remote::tests;
    use super::super::sledrepository::SledRepository;
    use super::*;

    #[test]
    fn test_initial_sync_to_remote() {
        let mut remote_repo = SledRepository::temporary().unwrap();
        let account = tests::test_initial_sync_to_remote_prepare_repo(&mut remote_repo);
        let mut remote = LocalRemote::new(&mut remote_repo);
        tests::test_initial_sync_to_remote(&mut remote, &account.uuid);
    }
}
