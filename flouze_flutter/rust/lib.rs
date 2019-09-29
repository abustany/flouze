extern crate flouze;
#[cfg(feature = "android")]
extern crate jni;
extern crate prost;

use std::os::raw::c_void;

use flouze::jsonrpcremote::Client;
use flouze::model;
use flouze::remote::Remote;
use flouze::repository;
use flouze::repository::{get_transaction_chain, Repository};
use flouze::sledrepository::SledRepository;
use flouze::sync;

use prost::Message;

#[cfg(feature = "android")]
mod android;

#[cfg(feature = "ios")]
mod ios;

mod proto {
    include!(concat!(env!("OUT_DIR"), "/flouze_flutter.rs"));
}

use proto::*;

struct FFIError(String);
type FFIResult<T> = Result<T, FFIError>;

impl std::convert::From<prost::DecodeError> for FFIError {
    fn from(err: prost::DecodeError) -> Self {
        FFIError(format!("{}", err))
    }
}

impl std::convert::From<::flouze::errors::Error> for FFIError {
    fn from(err: ::flouze::errors::Error) -> Self {
        FFIError(format!("{}", err))
    }
}

impl std::convert::AsRef<str> for FFIError {
    fn as_ref(self: &Self) -> &str {
        let FFIError(s) = self;
        s.as_ref()
    }
}

impl std::fmt::Display for FFIError {
    fn fmt(
        self: &Self,
        formatter: &mut std::fmt::Formatter<'_>,
    ) -> std::result::Result<(), std::fmt::Error> {
        let FFIError(s) = self;
        s.fmt(formatter)
    }
}

fn leak_raw<T>(ptr: T) -> *mut c_void {
    Box::into_raw(Box::new(ptr)) as *mut c_void
}

fn sled_repository_temporary() -> FFIResult<*mut c_void> {
    SledRepository::temporary()
        .map(leak_raw)
        .map_err(|e| e.into())
}

fn sled_repository_from_file(path: &str) -> FFIResult<*mut c_void> {
    SledRepository::new(path)
        .map(leak_raw)
        .map_err(|e| e.into())
}

unsafe fn sled_repository_destroy(ptr: *mut c_void) {
    if ptr == std::ptr::null_mut() {
        return;
    }

    let _repo = Box::from_raw(ptr as *mut SledRepository);
}

unsafe fn add_account(repo: *mut c_void, account_data: &[u8]) -> FFIResult<()> {
    let repo = &mut *(repo as *mut SledRepository);
    let account = model::Account::decode(account_data)?;
    repo.add_account(&account).map_err(|e| e.into())
}

unsafe fn delete_account(repo: *mut c_void, account_id: &[u8]) -> FFIResult<()> {
    let repo = &mut *(repo as *mut SledRepository);
    repo.delete_account(&account_id.to_vec())?;
    Ok(())
}

unsafe fn get_account(repo: *mut c_void, account_id: &Vec<u8>) -> FFIResult<Vec<u8>> {
    let repo = &mut *(repo as *mut SledRepository);
    let account = repo.get_account(&account_id)?;

    let mut buf = Vec::new();
    buf.reserve(account.encoded_len());
    account.encode(&mut buf).unwrap();

    Ok(buf)
}

unsafe fn list_accounts(repo: *mut c_void) -> FFIResult<Vec<u8>> {
    let repo = &mut *(repo as *mut SledRepository);
    let accounts = AccountList {
        accounts: repo.list_accounts()?,
    };
    let mut buf = Vec::new();
    buf.reserve(accounts.encoded_len());
    accounts.encode(&mut buf).unwrap();
    Ok(buf)
}

unsafe fn list_transactions(repo: *mut c_void, account_id: &[u8]) -> FFIResult<Vec<u8>> {
    let repo = &mut *(repo as *mut SledRepository);
    let account = repo.get_account(&account_id.to_vec())?;
    let mut transactions: Vec<model::Transaction> = Vec::new();

    for tx in get_transaction_chain(repo, &account) {
        let tx = tx?;
        transactions.push(tx);
    }

    let transaction_list = TransactionList {
        transactions: transactions,
    };

    let mut buf = Vec::new();
    buf.reserve(transaction_list.encoded_len());
    transaction_list.encode(&mut buf).unwrap();
    Ok(buf)
}

unsafe fn add_transaction(
    repo: *mut c_void,
    account_id: &[u8],
    transaction_data: &[u8],
) -> FFIResult<()> {
    let repo = &mut *(repo as *mut SledRepository);
    let transaction = model::Transaction::decode(transaction_data)?;
    let account_id = account_id.to_vec();
    repo.add_transaction(&account_id, &transaction)?;
    repo.set_latest_transaction(&account_id, &transaction.uuid)
        .map_err(|e| e.into())
}

unsafe fn get_balance(repo: *mut c_void, account_id: &[u8]) -> FFIResult<Vec<u8>> {
    let repo = &mut *(repo as *mut SledRepository);
    let account = repo.get_account(&account_id.to_vec())?;
    let balance_entries: Vec<balance::Entry> = repository::get_balance(repo, &account)?
        .into_iter()
        .map(|(k, v)| balance::Entry {
            person: k,
            balance: v,
        })
        .collect();
    let balance = Balance {
        entries: balance_entries,
    };
    let mut buf = Vec::new();
    buf.reserve(balance.encoded_len());
    balance.encode(&mut buf).unwrap();
    Ok(buf)
}

fn json_rpc_client_create(url: &str) -> FFIResult<*mut c_void> {
    Client::new(url).map(leak_raw).map_err(|e| e.into())
}

unsafe fn json_rpc_client_destroy(client: *mut c_void) {
    if client == std::ptr::null_mut() {
        return;
    }

    let _client = Box::from_raw(client as *mut Client);
}

unsafe fn json_rpc_client_create_account(
    client: *mut c_void,
    account_data: &[u8],
) -> FFIResult<()> {
    let client = &mut *(client as *mut Client);
    let account = model::Account::decode(account_data)?;
    client.create_account(&account).map_err(|e| e.into())
}

unsafe fn json_rpc_client_get_account_info(
    client: *mut c_void,
    account_id: &[u8],
) -> FFIResult<Vec<u8>> {
    let client = &mut *(client as *mut Client);
    let account = client.get_account_info(&account_id.to_vec())?;

    let mut buf = Vec::new();
    buf.reserve(account.encoded_len());
    account.encode(&mut buf).unwrap();

    Ok(buf)
}

unsafe fn sync_clone_remote(
    repo: *mut c_void,
    remote: *mut c_void,
    account_id: &[u8],
) -> FFIResult<()> {
    let repo = &mut *(repo as *mut SledRepository);
    let remote = &mut *(remote as *mut Client);

    sync::clone_remote(repo, remote, &account_id.to_vec()).map_err(|e| e.into())
}

unsafe fn sync_sync(repo: *mut c_void, remote: *mut c_void, account_id: &[u8]) -> FFIResult<()> {
    let repo = &mut *(repo as *mut SledRepository);
    let remote = &mut *(remote as *mut Client);

    sync::sync(repo, remote, &account_id.to_vec()).map_err(|e| e.into())
}
