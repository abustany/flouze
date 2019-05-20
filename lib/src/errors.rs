use std::io;
use std::net::AddrParseError;

use jsonrpc_core;
use jsonrpc_ws_client;
use jsonrpc_ws_server;
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

        IOError(t: String) {
            description("Input output error"),
            display("Input output error: {}", t)
        }

        InvalidIpAddress(t: String) {
            description("Invalid IP address"),
            display("Invalid IP address: {}", t)
        }

        WebsocketClientError(t: String) {
            description("Websocket client error"),
            display("Error in the websocket client: {}", t)
        }

        WebsocketServerError(t: String) {
            description("Websocket server error"),
            display("Error in the websocket server: {}", t)
        }

        GenericError(t: String) {
            description("Generic error"),
            display("Generic error: {}", t)
        }
    }
}

impl From<io::Error> for Error {
    fn from(err: io::Error) -> Self {
        ErrorKind::IOError(format!("{}", err)).into()
    }
}

impl From<prost::DecodeError> for Error {
    fn from(err: prost::DecodeError) -> Self {
        ErrorKind::InvalidEncoding(format!("{}", err)).into()
    }
}

impl From<AddrParseError> for Error {
    fn from(err: AddrParseError) -> Self {
        ErrorKind::InvalidIpAddress(format!("{}", err)).into()
    }
}

impl From<jsonrpc_ws_client::RpcError> for Error {
    fn from(err: jsonrpc_ws_client::RpcError) -> Self {
        ErrorKind::WebsocketClientError(format!("{}", err)).into()
    }
}

impl From<jsonrpc_ws_server::Error> for Error {
    fn from(err: jsonrpc_ws_server::Error) -> Self {
        ErrorKind::WebsocketServerError(format!("{}", err)).into()
    }
}

impl From<failure::Error> for Error {
    fn from(err: failure::Error) -> Self {
        ErrorKind::GenericError(format!("{}", err)).into()
    }
}

impl Into<jsonrpc_core::Error> for Error {
    fn into(self) -> jsonrpc_core::Error {
        let mut err = jsonrpc_core::Error::invalid_request();
        err.message = format!("{}", self);
        err
    }
}
