use std::cell::RefCell;
use std::net::SocketAddr;
use std::ops::{Deref, DerefMut};
use std::time::{Duration, Instant};
use std::sync::RwLock;

use jsonrpc_client_http;
use jsonrpc_core;
use jsonrpc_core::futures::Future;
use jsonrpc_core::futures::future::Either;
use jsonrpc_http_server;

use uuid::Uuid;

use super::errors;
use super::model;
use super::remote::Remote;
use super::repository::{Repository, receive_transactions, get_child_transactions};

mod client {
    use super::super::model;

    jsonrpc_client!(pub struct Rpc {
        pub fn create_account(&mut self, account: &model::Account) -> RpcRequest<()>;
        pub fn get_account_info(&mut self, account_id: &model::AccountId) -> RpcRequest<model::Account>;
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
    fn create_account(&mut self, account: &model::Account) -> errors::Result<()> {
        self.client.borrow_mut().create_account(account).call().map_err(|e| e.into())
    }

    fn get_account_info(&self, account_id: &model::AccountId) -> errors::Result<model::Account> {
        self.client.borrow_mut().get_account_info(account_id).call().map_err(|e| e.into())
    }

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
    use jsonrpc_derive::rpc;

    #[rpc]
    pub trait Rpc {
        #[rpc(name="create_account")]
        fn create_account(&self, Account) -> Result<()>;
        #[rpc(name="get_account_info")]
        fn get_account_info(&self, AccountId) -> Result<Account>;
        #[rpc(name="get_latest_transaction")]
        fn get_latest_transaction(&self, AccountId) -> Result<TransactionId>;
        #[rpc(name="receive_transactions")]
        fn receive_transactions(&self, AccountId, Vec<Transaction>) -> Result<()>;
        #[rpc(name="get_child_transactions")]
        fn get_child_transactions(&self, AccountId, TransactionId) -> Result<Vec<Transaction>>;
    }
}

struct ServerRpcImpl<T: Repository> {
    repo: RwLock<T>,
}

fn validate_person(person: &model::Person) -> Result<(), String> {
    if person.uuid.len() != 16 {
        return Err("Person has invalid UUID".to_owned());
    }

    if person.name.len() == 0 {
        return Err("Person has no name".to_owned());
    }

    Ok(())
}

fn validate_account(account: &model::Account) -> Result<(), String> {
    Uuid::from_slice(&account.uuid).map_err(|_| "Invalid account UUID")?;

    if account.label.len() == 0 {
        return Err("Missing account label".to_owned());
    }

    if account.members.len() == 0 {
        return Err("Account has no members".to_owned());
    }

    for member in &account.members {
        validate_person(member)?;
    }

    Ok(())
}

impl<T: Repository + Send + Sync + 'static> server::Rpc for ServerRpcImpl<T> {
    fn create_account(&self, account: model::Account) -> jsonrpc_core::Result<()> {
        validate_account(&account).map_err(|e| {
            let mut err = jsonrpc_core::Error::invalid_request();
            err.message = e;
            err
        })?;

        let mut lock = self.repo.write().unwrap();
        let repo: &mut Repository = lock.deref_mut();
        let account_uuid = Uuid::from_slice(&account.uuid).unwrap_or_else(|_| Uuid::nil()).to_hyphenated();

        // Check that we don't already have an account with this UUID
        match repo.get_account(&account.uuid) {
            Ok(_) => {
                info!("Account creation failed (duplicate UUID): {}", &account_uuid);
                let mut err = jsonrpc_core::Error::invalid_request();
                err.message = "An account with this UUID already exists".to_owned();
                return Err(err);
            },
            Err(errors::Error(errors::ErrorKind::NoSuchAccount(_), _)) => {},
            Err(e) => {
                warn!("Error while creating account with UUID {}: {}", &account_uuid, &e);
                return Err(e.into())
            },
        };

        // Clear the synchronization fields, they'll be set by the synchronization
        let mut account = account;
        account.latest_transaction.clear();
        account.latest_synchronized_transaction.clear();

        let res: jsonrpc_core::Result<()> = repo.add_account(&account).map_err(|e| e.into());

        if let Ok(_) = res {
            info!("Created account with UUID {}", &account_uuid);
        } else if let Err(ref e) = res {
            warn!("Error while creating account with UUID {}: {:?}", &account_uuid, &e);
        }

        res
    }

    fn get_account_info(&self, account_id: model::AccountId) -> jsonrpc_core::Result<model::Account> {
        let lock = self.repo.read().unwrap();
        let repo: &Repository = lock.deref();
        repo.get_account(&account_id).map_err(|e| e.into())
    }

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

#[derive(Clone, Debug, Default)]
struct RequestMeta{}

impl jsonrpc_core::Metadata for RequestMeta {}

#[derive(Default)]
struct LoggingMiddleware{}

fn log_request_start(call: &jsonrpc_core::Call) {
    if let jsonrpc_core::Call::MethodCall(method_call) = call {
        info!("RPC IN  id={:?} method={}", &method_call.id, &method_call.method);
    }
}

fn log_request_end(output: &jsonrpc_core::Output, request_time: &Duration) {
    let request_time_ms = 1000 * request_time.as_secs() + request_time.subsec_millis() as u64;
    let success = match output {
        jsonrpc_core::Output::Success(_) => true,
        _ => false,
    };
    info!("RPC OUT id={:?} elapsed={}ms success={}", output.id(), request_time_ms, success);
}

impl jsonrpc_core::Middleware<RequestMeta> for LoggingMiddleware {
    type Future = jsonrpc_core::FutureResponse;
    type CallFuture = jsonrpc_core::middleware::NoopCallFuture;

    fn on_request<F, X>(&self, request: jsonrpc_core::Request, meta: RequestMeta, next: F) -> Either<Self::Future, X> where
        F: FnOnce(jsonrpc_core::Request, RequestMeta) -> X + Send,
        X: Future<Item=Option<jsonrpc_core::Response>, Error=()> + Send + 'static,
    {
        let start = Instant::now();

        match request {
            jsonrpc_core::Request::Single(ref call) => log_request_start(call),
            jsonrpc_core::Request::Batch(ref calls) => {
                for call in calls {
                    log_request_start(call);
                }
            }
        }

        Either::A(Box::new(next(request, meta).map(move |res| {
            let request_duration = start.elapsed();
            match res {
                Some(jsonrpc_core::Response::Single(ref output)) => log_request_end(output, &request_duration),
                Some(jsonrpc_core::Response::Batch(ref outputs)) => {
                    for output in outputs {
                        log_request_end(output, &request_duration);
                    }
                }
                _ => {}
            }

            res
        })))
    }
}

pub struct Server {
    server: jsonrpc_http_server::Server,
}

impl Server {
    pub fn new<T: Repository + Send + Sync + 'static>(repo: T, listen_address: &str) -> errors::Result<Server> {
        use self::server::*;

        let rpc_impl = ServerRpcImpl{repo: RwLock::new(repo)};
        let mut io = jsonrpc_core::MetaIoHandler::with_middleware(LoggingMiddleware::default());
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
