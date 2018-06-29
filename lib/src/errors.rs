use prost;

error_chain! {
    errors {
        NoSuchAccount
        NoSuchTransaction

        Storage(t: String) {
            description("Storage error"),
            display("Storage error: {}", t)
        }

        InvalidEncoding(t: String) {
            description("Invalid Protobuf data"),
            display("Invalid Protobuf data: {}", t)
        }
    }
}

impl From<prost::DecodeError> for Error {
    fn from(err: prost::DecodeError) -> Self {
        ErrorKind::InvalidEncoding(format!("{}", err)).into()
    }
}
