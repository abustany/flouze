extern crate flouze;
extern crate jni;
extern crate prost;

use jni::JNIEnv;
use jni::objects::*;
use jni::sys::*;

use flouze::model;
use flouze::repository;
use flouze::jsonrpcremote::Client;
use flouze::remote::Remote;
use flouze::repository::{Repository, get_transaction_chain};
use flouze::sledrepository::SledRepository;
use flouze::sync;

use prost::Message;

mod proto {
    include!(concat!(env!("OUT_DIR"), "/flouze_flutter.rs"));
}

use proto::*;

const FLOUZE_EXCEPTION_CLASS: &'static str = "org/bustany/flouze/flouzeflutter/FlouzeException";

fn throw_err(env: &JNIEnv, err: ::flouze::errors::Error) {
    let _ = env.throw((FLOUZE_EXCEPTION_CLASS, format!("{}", err)));
}

fn ok_or_throw<T>(env: &JNIEnv, res: ::flouze::errors::Result<T>, default: T) -> T {
    match res {
        Err(e) => {
            throw_err(env, e);
            default
        },
        Ok(v) => v
    }
}

#[no_mangle]
#[allow(non_snake_case)]
pub extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_temporary(env: JNIEnv, _class: JClass) -> jlong {
    match SledRepository::temporary() {
        Ok(repo) => Box::into_raw(Box::new(repo)) as jlong,
        Err(e) => {
            let _ = env.throw((FLOUZE_EXCEPTION_CLASS, format!("Error while creating repository: {}", e)));
            0
        },
    }
}

#[no_mangle]
#[allow(non_snake_case)]
pub extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_fromFile(env: JNIEnv, _class: JClass, path: JString) -> jlong {
    let path: String = match env.get_string(path) {
        Ok(p) => p.into(),
        Err(_) => { return 0; }
    };

    match SledRepository::new(&path) {
        Ok(repo) => Box::into_raw(Box::new(repo)) as jlong,
        Err(e) => {
            let _ = env.throw((FLOUZE_EXCEPTION_CLASS, format!("Error while creating repository: {}", e)));
            0
        },
    }
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_destroy(_env: JNIEnv, _instance: JObject, ptr: jlong) {
    if ptr == 0 {
        return;
    }

    let _repo = Box::from_raw(ptr as *mut SledRepository);
}

fn add_account(repo: &mut SledRepository, account_data: &Vec<u8>) -> ::flouze::errors::Result<()> {
    let account = model::Account::decode(account_data)?;
    repo.add_account(&account)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_addAccount(env: JNIEnv, _class: JClass, instance: jlong, account: jbyteArray) {
    let mut repo = &mut *(instance as *mut SledRepository);
    let account_bytes = match env.convert_byte_array(account) {
        Ok(bytes) => bytes,
        Err(_) => { return; } // An exception has been raised
    };
    ok_or_throw(&env, add_account(&mut repo, &account_bytes), ());
}

fn get_account(repo: &SledRepository, account_id: &Vec<u8>) -> ::flouze::errors::Result<Vec<u8>> {
    let account = repo.get_account(&account_id)?;

    let mut buf = Vec::new();
    buf.reserve(account.encoded_len());
    account.encode(&mut buf).unwrap();

    Ok(buf)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_getAccount(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray) -> jbyteArray {
    let repo = &mut *(instance as *mut SledRepository);
    let account_id = match env.convert_byte_array(jaccount_id) {
        Ok(bytes) => bytes,
        Err(_) => { return env.byte_array_from_slice(&vec!()).unwrap(); } // An exception has been raised
    };

    match get_account(&repo, &account_id) {
        Ok(bytes) => env.byte_array_from_slice(&bytes).unwrap(),
        Err(e) => {
            throw_err(&env, e);
            return JObject::null().into_inner();
        }
    }
}

fn list_accounts(repo: &SledRepository) -> ::flouze::errors::Result<Vec<u8>> {
    let accounts = AccountList{
        accounts: repo.list_accounts()?,
    };
    let mut buf = Vec::new();
    buf.reserve(accounts.encoded_len());
    accounts.encode(&mut buf).unwrap();
    Ok(buf)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_listAccounts(env: JNIEnv, _class: JClass, instance: jlong) -> jbyteArray {
    let repo = &mut *(instance as *mut SledRepository);
    match list_accounts(&repo) {
        Ok(bytes) => env.byte_array_from_slice(&bytes).unwrap(),
        Err(e) => {
            throw_err(&env, e);
            return JObject::null().into_inner();
        }
    }
}

fn list_transactions(repo: &SledRepository, account_id: &model::AccountId) -> ::flouze::errors::Result<Vec<u8>> {
    let account = repo.get_account(account_id)?;
    let mut transactions: Vec<model::Transaction> = Vec::new();

    for tx in get_transaction_chain(repo, &account) {
        let tx = tx?;
        transactions.push(tx);
    }

    let transaction_list = TransactionList{
        transactions: transactions,
    };

    let mut buf = Vec::new();
    buf.reserve(transaction_list.encoded_len());
    transaction_list.encode(&mut buf).unwrap();
    Ok(buf)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_listTransactions(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray) -> jbyteArray {
    let repo = &mut *(instance as *mut SledRepository);
    let account_id = match env.convert_byte_array(jaccount_id) {
        Ok(bytes) => bytes,
        Err(_) => { return env.byte_array_from_slice(&vec!()).unwrap(); }
    };
    match list_transactions(&repo, &account_id) {
        Ok(bytes) => env.byte_array_from_slice(&bytes).unwrap(),
        Err(e) => {
            throw_err(&env, e);
            return JObject::null().into_inner();
        }
    }
}

fn add_transaction(repo: &mut SledRepository, account_id: &model::AccountId, transaction_data: &Vec<u8>) -> ::flouze::errors::Result<()> {
    let transaction = model::Transaction::decode(transaction_data)?;
    repo.add_transaction(account_id, &transaction)?;
    repo.set_latest_transaction(account_id, &transaction.uuid)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_addTransaction(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray, transaction: jbyteArray) {
    let mut repo = &mut *(instance as *mut SledRepository);
    let account_id = match env.convert_byte_array(jaccount_id) {
        Ok(bytes) => bytes,
        Err(_) => { return; }
    };
    let transaction_bytes = match env.convert_byte_array(transaction) {
        Ok(bytes) => bytes,
        Err(_) => { return; }
    };
    ok_or_throw(&env, add_transaction(&mut repo, &account_id, &transaction_bytes), ());
}

fn get_balance(repo: &SledRepository, account_id: &model::AccountId) -> ::flouze::errors::Result<Vec<u8>> {
    let account = repo.get_account(account_id)?;
    let balance_entries: Vec<balance::Entry> = repository::get_balance(repo, &account)?
        .into_iter()
        .map(|(k, v)| balance::Entry{person: k, balance: v})
        .collect();
    let balance = Balance{entries: balance_entries};
    let mut buf = Vec::new();
    buf.reserve(balance.encoded_len());
    balance.encode(&mut buf).unwrap();
    Ok(buf)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_Repository_getBalance(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray) -> jbyteArray {
    let repo = &mut *(instance as *mut SledRepository);
    let account_id = match env.convert_byte_array(jaccount_id) {
        Ok(bytes) => bytes,
        Err(_) => { return env.byte_array_from_slice(&vec!()).unwrap(); }
    };
    match get_balance(&repo, &account_id) {
        Ok(bytes) => env.byte_array_from_slice(&bytes).unwrap(),
        Err(e) => {
            throw_err(&env, e);
            return JObject::null().into_inner();
        }
    }
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_JsonRpcClient_create(env: JNIEnv, _class: JClass, url: JString) -> jlong {
    let url: String = match env.get_string(url) {
        Ok(p) => p.into(),
        Err(_) => { return 0; }
    };

    match Client::new(&url) {
        Ok(client) => Box::into_raw(Box::new(client)) as jlong,
        Err(e) => {
            let _ = env.throw((FLOUZE_EXCEPTION_CLASS, format!("Error while creating JsonRpcClient: {}", e)));
            0
        },
    }
}

fn create_account(client: &mut Client, account_data: &Vec<u8>) -> ::flouze::errors::Result<()> {
    let account = model::Account::decode(account_data)?;
    client.create_account(&account)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_JsonRpcClient_createAccount(env: JNIEnv, _class: JClass, instance: jlong, account: jbyteArray) {
    let mut client = &mut *(instance as *mut Client);
    let account_bytes = match env.convert_byte_array(account) {
        Ok(bytes) => bytes,
        Err(_) => { return; }
    };
    ok_or_throw(&env, create_account(&mut client, &account_bytes), ());
}

fn get_account_info(client: &mut Client, account_id: &Vec<u8>) -> ::flouze::errors::Result<Vec<u8>> {
    let account = client.get_account_info(account_id)?;

    let mut buf = Vec::new();
    buf.reserve(account.encoded_len());
    account.encode(&mut buf).unwrap();

    Ok(buf)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_JsonRpcClient_getAccountInfo(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray) -> jbyteArray {
    let mut client = &mut *(instance as *mut Client);
    let account_id = match env.convert_byte_array(jaccount_id) {
        Ok(bytes) => bytes,
        Err(_) => { return env.byte_array_from_slice(&vec!()).unwrap(); }
    };

    match get_account_info(&mut client, &account_id) {
        Ok(bytes) => env.byte_array_from_slice(&bytes).unwrap(),
        Err(e) => {
            throw_err(&env, e);
            return JObject::null().into_inner();
        }
    }
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_Sync_cloneRemote(env: JNIEnv, _class: JClass, repoPtr: jlong, remotePtr: jlong, jaccount_id: jbyteArray) {
    let repo = &mut *(repoPtr as *mut SledRepository);
    let client = &mut *(remotePtr as *mut Client);
    let account_id = match env.convert_byte_array(jaccount_id) {
        Ok(bytes) => bytes,
        Err(_) => { return; }
    };

    ok_or_throw(&env, sync::clone_remote(repo, client, &account_id), ());
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_Sync_sync(env: JNIEnv, _class: JClass, repoPtr: jlong, remotePtr: jlong, jaccount_id: jbyteArray) {
    let repo = &mut *(repoPtr as *mut SledRepository);
    let client = &mut *(remotePtr as *mut Client);
    let account_id = match env.convert_byte_array(jaccount_id) {
        Ok(bytes) => bytes,
        Err(_) => { return; }
    };

    ok_or_throw(&env, sync::sync(repo, client, &account_id), ());
}
