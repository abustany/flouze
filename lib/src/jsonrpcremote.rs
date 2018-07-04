use std::cell::RefCell;
use std::net::SocketAddr;
use std::ops::{Deref, DerefMut};
use std::sync::RwLock;

use jsonrpc_client_http;
use jsonrpc_core;
use jsonrpc_http_server;

use super::errors;
use super::model;
use super::remote::Remote;
use super::repository::{Repository, receive_transactions, get_child_transactions};

mod client {
    use super::super::model;

    jsonrpc_client!(pub struct Rpc {
        pub fn get_latest_transaction(&mut self, account_id: &model::AccountId) -> RpcRequest<model::TransactionId>;
        pub fn receive_transactions(&mut self, account_id: &model::AccountId, transactions: &[&model::Transaction]) -> RpcRequest<()>;
        pub fn get_child_transactions(&mut self, account_id: &model::AccountId, base: &model::TransactionId) -> RpcRequest<Vec<model::Transaction>>;
    });
}

pub struct Client {
    client: RefCell<client::Rpc<jsonrpc_client_http::HttpHandle>>,
}

impl Client {
    pub fn new(uri: &str) -> errors::Result<Client> {
        let transport = jsonrpc_client_http::HttpTransport::new().standalone()?;
        let handle = transport.handle(uri)?;

        Ok(Client {
            client: RefCell::new(client::Rpc::new(handle)),
        })
    }
}

impl Remote for Client {
    fn get_latest_transaction(&self, account_id: &model::AccountId) -> errors::Result<model::TransactionId> {
        self.client.borrow_mut().get_latest_transaction(account_id).call().map_err(|e| e.into())
    }

    fn receive_transactions(&mut self, account_id: &model::AccountId, transactions: &[&model::Transaction]) -> errors::Result<()> {
        self.client.borrow_mut().receive_transactions(account_id, transactions).call().map_err(|e| e.into())
    }

    fn get_child_transactions(&self, account_id: &model::AccountId, base: &model::TransactionId) -> errors::Result<Vec<model::Transaction>> {
        self.client.borrow_mut().get_child_transactions(account_id, base).call().map_err(|e| e.into())
    }
}

mod server {
    use super::super::model::*;
    use jsonrpc_core::Result;

    build_rpc_trait!(
        pub trait Rpc {
            #[rpc(name="get_latest_transaction")]
            fn get_latest_transaction(&self, AccountId) -> Result<TransactionId>;
            #[rpc(name="receive_transactions")]
            fn receive_transactions(&self, AccountId, Vec<Transaction>) -> Result<()>;
            #[rpc(name="get_child_transactions")]
            fn get_child_transactions(&self, AccountId, TransactionId) -> Result<Vec<Transaction>>;
        }
    );
}

struct ServerRpcImpl<T: Repository> {
    repo: RwLock<T>,
}

impl<T: Repository + Send + Sync + 'static> server::Rpc for ServerRpcImpl<T> {
    fn get_latest_transaction(&self, account_id: model::AccountId) -> jsonrpc_core::Result<model::TransactionId> {
        let lock = self.repo.read().unwrap();
        let repo: &Repository = lock.deref();
        let account = repo.get_account(&account_id).map_err(|e| e.into())?;
        Ok(account.latest_transaction.clone())
    }

    fn receive_transactions(&self, account_id: model::AccountId, transactions: Vec<model::Transaction>) -> jsonrpc_core::Result<()> {
        let mut lock = self.repo.write().unwrap();
        let repo: &mut Repository = lock.deref_mut();
        let transaction_refs: Vec<&model::Transaction> = transactions.iter().map(|tx| tx).collect();
        receive_transactions(repo, &account_id, &transaction_refs).map_err(|e| e.into())
    }

    fn get_child_transactions(&self, account_id: model::AccountId, base: model::TransactionId) -> jsonrpc_core::Result<Vec<model::Transaction>> {
        let lock = self.repo.read().unwrap();
        let repo: &Repository = lock.deref();
        get_child_transactions(repo, &account_id, &base).map_err(|e| e.into())
    }
}

pub struct Server {
    server: jsonrpc_http_server::Server,
}

impl Server {
    pub fn new<T: Repository + Send + Sync + 'static>(repo: T, listen_address: &str) -> errors::Result<Server> {
        use self::server::*;

        let rpc_impl = ServerRpcImpl{repo: RwLock::new(repo)};
        let mut io = jsonrpc_core::IoHandler::new();
        io.extend_with(rpc_impl.to_delegate());

        let addr: SocketAddr = listen_address.parse()?;
        let server = jsonrpc_http_server::ServerBuilder::new(io)
            .threads(3)
            .start_http(&addr)?;

        Ok(Server{server})
    }

    pub fn wait(self) {
        self.server.wait();
    }

    pub fn close(self) {
        self.server.close();
    }
}
