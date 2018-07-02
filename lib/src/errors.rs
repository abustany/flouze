use prost;

use super::model;

error_chain! {
    errors {
        NoSuchAccount(id: model::AccountId)

        NoSuchTransaction(id: model::TransactionId) {
            display("No such transaction: {}", model::IdAsHex(&id))
        }

        Storage(t: String) {
            description("Storage error"),
            display("Storage error: {}", t)
        }

        InvalidEncoding(t: String) {
            description("Invalid Protobuf data"),
            display("Invalid Protobuf data: {}", t)
        }

        MustRebase

        InconsistentChain

        InconsistentServerResponse

        DuplicateTransactionId(id: model::TransactionId)
    }
}

impl From<prost::DecodeError> for Error {
    fn from(err: prost::DecodeError) -> Self {
        ErrorKind::InvalidEncoding(format!("{}", err)).into()
    }
}
