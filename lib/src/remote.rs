use super::errors;
use super::model;

pub trait Remote {
    fn get_account_info(&self, account_id: &model::AccountId) -> errors::Result<model::Account>;
    fn get_latest_transaction(&self, account_id: &model::AccountId) -> errors::Result<model::TransactionId>;
    fn receive_transactions(&mut self, account_id: &model::AccountId, transactions: &[&model::Transaction]) -> errors::Result<()>;
    fn get_child_transactions(&self, account_id: &model::AccountId, base: &model::TransactionId) -> errors::Result<Vec<model::Transaction>>;
}

#[cfg(test)]
pub mod tests {
    use std::fmt::Debug;

    use super::*;
    use super::model;
    use super::super::repository::{Repository};

    pub fn expect_inconsistent_chain<T: Debug>(r: errors::Result<T>) {
        match r {
            Err(errors::Error(errors::ErrorKind::InconsistentChain, _)) => {},
            _ => { panic!("Expected InconsistentChain error, got {:?}", r); }
        }
    }

    pub fn expect_must_rebase<T: Debug>(r: errors::Result<T>) {
        match r {
            Err(errors::Error(errors::ErrorKind::MustRebase, _)) => {},
            _ => { panic!("Expected MustRebase error, got {:?}", r); }
        }
    }

    pub fn make_transaction(parent: &model::TransactionId) -> model::Transaction {
        model::Transaction{
            uuid: model::generate_transaction_id(),
            parent: parent.clone(),
            amount: 0,
            payed_by: vec!(),
            payed_for: vec!(),
            label: "".to_owned(),
            timestamp: 0,
            deleted: false,
            replaces: vec!(),
        }
    }

    pub fn test_initial_sync_to_remote_prepare_repo(remote_repo: &mut Repository) -> model::Account {
        let account = model::Account{
            uuid: model::generate_account_id(),
            label: "Account".to_owned(),
            latest_transaction: vec!(),
            latest_synchronized_transaction: vec!(),
            members: vec!(
                model::Person{
                    uuid: model::generate_person_id(),
                    name: "P1".to_owned(),
                },
                model::Person{
                    uuid: model::generate_person_id(),
                    name: "P2".to_owned(),
                },
            ),
        };

        remote_repo.add_account(&account).unwrap();

        account
    }

    pub fn test_initial_sync_to_remote(remote: &mut Remote, account_id: &model::AccountId) {
        assert_eq!(remote.get_latest_transaction(&account_id).unwrap(), model::INVALID_ID);
        assert_eq!(remote.get_child_transactions(&account_id, &vec!()).unwrap(), vec!());

        let tx1 = make_transaction(&vec!());
        let tx2 = make_transaction(&tx1.uuid);
        let tx3 = make_transaction(&tx2.uuid);

        expect_inconsistent_chain(remote.receive_transactions(account_id, &vec!(&tx1, &tx3)));
        assert_eq!(remote.get_latest_transaction(&account_id).unwrap(), model::INVALID_ID);
        assert_eq!(remote.get_child_transactions(&account_id, &vec!()).unwrap(), vec!());

        expect_must_rebase(remote.receive_transactions(account_id, &vec!(&tx2)));
        assert_eq!(remote.get_latest_transaction(&account_id).unwrap(), model::INVALID_ID);
        assert_eq!(remote.get_child_transactions(&account_id, &vec!()).unwrap(), vec!());

        remote.receive_transactions(account_id, &vec!(&tx1, &tx2, &tx3)).unwrap();
        assert_eq!(&remote.get_latest_transaction(&account_id).unwrap(), &tx3.uuid);
        assert_eq!(remote.get_child_transactions(account_id, &vec!()).unwrap(), vec!(tx1.clone(), tx2.clone(), tx3.clone()));
        assert_eq!(remote.get_child_transactions(account_id, &tx1.uuid).unwrap(), vec!(tx2.clone(), tx3.clone()));
        assert_eq!(remote.get_child_transactions(account_id, &tx3.uuid).unwrap(), vec!());
    }
}
