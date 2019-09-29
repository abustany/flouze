use std::fmt;

use hex;
use uuid;

pub type AccountId = Vec<u8>;
pub type TransactionId = Vec<u8>;
pub type PersonId = Vec<u8>;

include!(concat!(env!("OUT_DIR"), "/flouze.model.rs"));

pub const INVALID_ID: [u8; 0] = [];

pub fn generate_account_id() -> AccountId {
    uuid::Uuid::new_v4().as_bytes().to_vec()
}

pub fn generate_transaction_id() -> TransactionId {
    uuid::Uuid::new_v4().as_bytes().to_vec()
}

pub fn generate_person_id() -> PersonId {
    uuid::Uuid::new_v4().as_bytes().to_vec()
}

pub struct IdAsHex<'a>(pub &'a AccountId);

impl<'a> fmt::Display for IdAsHex<'a> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let id = self.0;

        if id.is_empty() {
            write!(f, "<null>")
        } else {
            write!(f, "{}", hex::encode(self.0))
        }
    }
}
