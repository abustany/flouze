use std::convert::From;

use prost::Message;
use sled;

use super::errors;
use super::model;
use super::repository::Repository;

// account:
const ACCOUNT_KEY_PREFIX: &[u8] = &[0x61, 0x63, 0x63, 0x6f, 0x75, 0x6e, 0x74, 0x3a];

// tx:
const TX_KEY_PREFIX: &[u8] = &[0x74, 0x78, 0x3a];

impl From<sled::Error> for errors::Error {
    fn from(err: sled::Error) -> Self {
        errors::ErrorKind::Storage(format!("Sled error: {}", err)).into()
    }
}

pub struct SledRepository {
    db: sled::Db,
}

impl SledRepository {
    pub fn new(path: &str) -> errors::Result<SledRepository> {
        let config = sled::ConfigBuilder::new().path(path.to_owned()).build();
        let db = sled::Db::start(config)?;

        Ok(SledRepository { db })
    }

    pub fn temporary() -> errors::Result<SledRepository> {
        let config = sled::ConfigBuilder::new().temporary(true).build();
        let db = sled::Db::start(config)?;

        Ok(SledRepository { db })
    }
}

impl Repository for SledRepository {
    fn add_account(&mut self, account: &model::Account) -> errors::Result<()> {
        let mut buf = Vec::new();
        buf.reserve(account.encoded_len());
        account.encode(&mut buf).unwrap();

        self.db.set(account_key(&account.uuid), buf)?;

        Ok(())
    }

    fn get_account(&self, account_id: &model::AccountId) -> errors::Result<model::Account> {
        let buf = self.db.get(&account_key(account_id))?;

        match buf {
            None => Err(errors::ErrorKind::NoSuchAccount(account_id.clone()).into()),
            Some(ref data) => model::Account::decode(data.as_ref()).map_err(|e| e.into()),
        }
    }

    fn delete_account(&mut self, account_id: &model::AccountId) -> errors::Result<()> {
        match self.db.del(&account_key(account_id))? {
            Some(_) => Ok(()),
            None => Err(errors::ErrorKind::NoSuchAccount(account_id.clone()).into()),
        }
    }

    fn list_accounts(&self) -> errors::Result<Vec<model::Account>> {
        let mut accounts = vec![];

        for it in self.db.scan(ACCOUNT_KEY_PREFIX) {
            if let Err(e) = it {
                return Err(e.into());
            }

            let (key, data) = it.unwrap();

            if !key.starts_with(ACCOUNT_KEY_PREFIX) {
                break;
            }

            let account = model::Account::decode(data.as_ref())?;
            accounts.push(account);
        }

        Ok(accounts)
    }

    fn set_latest_transaction(
        &mut self,
        account_id: &model::AccountId,
        tx_id: &model::TransactionId,
    ) -> errors::Result<()> {
        let mut account = self.get_account(account_id)?;
        account.latest_transaction = tx_id.to_owned();
        self.add_account(&account)
    }

    fn set_latest_synchronized_transaction(
        &mut self,
        account_id: &model::AccountId,
        tx_id: &model::TransactionId,
    ) -> errors::Result<()> {
        let mut account = self.get_account(account_id)?;
        account.latest_synchronized_transaction = tx_id.to_owned();
        self.add_account(&account)
    }

    fn add_transaction(
        &mut self,
        account_uuid: &model::AccountId,
        transaction: &model::Transaction,
    ) -> errors::Result<()> {
        let mut buf = Vec::new();
        buf.reserve(transaction.encoded_len());
        transaction.encode(&mut buf).unwrap();

        self.db.set(tx_key(&account_uuid, &transaction.uuid), buf)?;
        Ok(())
    }

    fn get_transaction(
        &self,
        account_uuid: &model::AccountId,
        transaction_id: &model::TransactionId,
    ) -> errors::Result<model::Transaction> {
        let buf = self.db.get(&tx_key(&account_uuid, &transaction_id))?;

        match buf {
            None => Err(errors::ErrorKind::NoSuchTransaction(transaction_id.clone()).into()),
            Some(ref data) => model::Transaction::decode(data.as_ref()).map_err(|e| e.into()),
        }
    }

    fn delete_transaction(
        &mut self,
        account_id: &model::AccountId,
        transaction_id: &model::TransactionId,
    ) -> errors::Result<()> {
        match self.db.del(&tx_key(account_id, transaction_id))? {
            Some(_) => Ok(()),
            None => Err(errors::ErrorKind::NoSuchTransaction(transaction_id.clone()).into()),
        }
    }
}

fn account_key(id: &[u8]) -> Vec<u8> {
    let mut key = Vec::with_capacity(ACCOUNT_KEY_PREFIX.len() + id.len());
    key.append(ACCOUNT_KEY_PREFIX.to_owned().as_mut());
    key.append(id.to_owned().as_mut());

    key
}

fn tx_key(account_id: &[u8], tx_id: &[u8]) -> Vec<u8> {
    let mut key = Vec::with_capacity(TX_KEY_PREFIX.len() + account_id.len() + 1 + tx_id.len());
    key.append(TX_KEY_PREFIX.to_owned().as_mut());
    key.append(account_id.to_owned().as_mut());
    key.push(b':');
    key.append(tx_id.to_owned().as_mut());

    key
}

#[cfg(test)]
mod tests {
    use super::super::repository::tests;
    use super::*;

    #[test]
    fn test_account_crud() {
        let mut repo = SledRepository::temporary().unwrap();
        tests::test_account_crud(&mut repo);
    }

    #[test]
    fn test_transaction_insert() {
        let mut repo = SledRepository::temporary().unwrap();
        tests::test_transaction_insert(&mut repo);
    }

    #[test]
    fn test_transaction_chain() {
        let mut repo = SledRepository::temporary().unwrap();
        tests::test_transaction_chain(&mut repo);
    }

    #[test]
    fn test_balance() {
        let mut repo = SledRepository::temporary().unwrap();
        tests::test_balance(&mut repo);
    }
}
