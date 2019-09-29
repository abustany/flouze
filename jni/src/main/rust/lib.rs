extern crate flouze;
extern crate jni;
extern crate prost;

use jni::objects::*;
use jni::sys::*;
use jni::JNIEnv;

use flouze::model;
use flouze::repository::Repository;
use flouze::sledrepository::SledRepository;

use prost::Message;

const FLOUZE_EXCEPTION_CLASS: &'static str = "flouze/FlouzeException";

fn throw_err(env: &JNIEnv, err: ::flouze::errors::Error) {
    let _ = env.throw((FLOUZE_EXCEPTION_CLASS, format!("{}", err)));
}

fn ok_or_throw<T>(env: &JNIEnv, res: ::flouze::errors::Result<T>, default: T) -> T {
    match res {
        Err(e) => {
            throw_err(env, e);
            default
        }
        Ok(v) => v,
    }
}

#[no_mangle]
#[allow(non_snake_case)]
pub extern "system" fn Java_flouze_SledRepository__1newSledTemporary(
    env: JNIEnv,
    _class: JClass,
) -> jlong {
    match SledRepository::temporary() {
        Ok(repo) => Box::into_raw(Box::new(repo)) as jlong,
        _ => {
            let _ = env.throw((FLOUZE_EXCEPTION_CLASS, "Error while creating repository"));
            0
        }
    }
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_flouze_SledRepository__1destroy(
    _env: JNIEnv,
    _instance: JObject,
    ptr: jlong,
) {
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
pub unsafe extern "system" fn Java_flouze_SledRepository__1addAccount(
    env: JNIEnv,
    _class: JClass,
    instance: jlong,
    account: jbyteArray,
) {
    let mut repo = &mut *(instance as *mut SledRepository);
    let account_bytes = match env.convert_byte_array(account) {
        Ok(bytes) => bytes,
        Err(_) => {
            return;
        } // An exception has been raised
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
pub unsafe extern "system" fn Java_flouze_SledRepository__1getAccount(
    env: JNIEnv,
    _class: JClass,
    instance: jlong,
    jaccount_id: jbyteArray,
) -> jbyteArray {
    let repo = &mut *(instance as *mut SledRepository);
    let account_id = match env.convert_byte_array(jaccount_id) {
        Ok(bytes) => bytes,
        Err(_) => {
            return env.byte_array_from_slice(&vec![]).unwrap();
        } // An exception has been raised
    };

    match get_account(&repo, &account_id) {
        Ok(bytes) => env.byte_array_from_slice(&bytes).unwrap(),
        Err(e) => {
            throw_err(&env, e);
            return env.byte_array_from_slice(&vec![]).unwrap();
        }
    }
}
