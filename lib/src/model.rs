use uuid;

pub type AccountId = Vec<u8>;
pub type TransactionId = Vec<u8>;
pub type PersonId = Vec<u8>;

include!(concat!(env!("OUT_DIR"), "/flouze.model.rs"));

pub fn generate_account_id() -> AccountId {
    uuid::Uuid::new_v4().as_bytes().to_vec()
}

pub fn generate_transaction_id() -> TransactionId {
    uuid::Uuid::new_v4().as_bytes().to_vec()
}

pub fn generate_person_id() -> PersonId {
    uuid::Uuid::new_v4().as_bytes().to_vec()
}
