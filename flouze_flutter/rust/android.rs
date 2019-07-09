use jni::JNIEnv;
use jni::objects::*;
use jni::sys::*;

use super::*;

const FLOUZE_EXCEPTION_CLASS: &'static str = "org/bustany/flouze/flouzeflutter/FlouzeException";

fn ok_or_throw<T>(env: &JNIEnv, res: FFIResult<T>, default: T) -> T {
    res.unwrap_or_else(|e| {
        let _ = env.throw((FLOUZE_EXCEPTION_CLASS, e));
        default
    })

}

fn make_jnull() -> jobject {
    JObject::null().into_inner()
}

macro_rules! convert_jbytearray {
    ($env: expr, $bytearray: expr, $default: expr) => (
        match $env.convert_byte_array($bytearray) {
            Ok(b) => b,
            Err(_) => { return $default; } // An exception has been raised
        };
    )
}

macro_rules! convert_jstring {
    ($env: expr, $string: expr, $default: expr) => (
        match $env.get_string($string) {
            Ok(s) => String::from(s),
            Err(_) => { return $default; } // An exception has been raised
        };
    )
}

macro_rules! res_to_jbytes {
    ($env: expr, $res: expr) => (
        $res.map(|b| $env.byte_array_from_slice(&b).unwrap())
    )
}

#[no_mangle]
#[allow(non_snake_case)]
pub extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_temporary(env: JNIEnv, _class: JClass) -> jlong {
    ok_or_throw(&env, sled_repository_temporary().map(|r| r as jlong), 0)
}

#[no_mangle]
#[allow(non_snake_case)]
pub extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_fromFile(env: JNIEnv, _class: JClass, path: JString) -> jlong {
    let path = convert_jstring!(env, path, 0);
    ok_or_throw(&env, sled_repository_from_file(&path).map(|r| r as jlong), 0)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_destroy(_env: JNIEnv, _instance: JObject, ptr: jlong) {
    sled_repository_destroy(ptr as *mut c_void);
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_addAccount(env: JNIEnv, _class: JClass, instance: jlong, account: jbyteArray) {
    let account_bytes = convert_jbytearray!(env, account, ());
    ok_or_throw(&env, add_account(instance as *mut c_void, &account_bytes), ());
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_deleteAccount(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray) {
    let account_id = convert_jbytearray!(env, jaccount_id, ());
    ok_or_throw(&env, delete_account(instance as *mut c_void, &account_id), ());
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_getAccount(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray) -> jbyteArray {
    let account_id = convert_jbytearray!(env, jaccount_id, make_jnull());

    ok_or_throw(&env, res_to_jbytes!(env, get_account(instance as *mut c_void, &account_id)), make_jnull())
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_listAccounts(env: JNIEnv, _class: JClass, instance: jlong) -> jbyteArray {
    ok_or_throw(&env, res_to_jbytes!(env, list_accounts(instance as *mut c_void)), make_jnull())
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_listTransactions(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray) -> jbyteArray {
    let account_id = convert_jbytearray!(env, jaccount_id, make_jnull());
    ok_or_throw(&env, res_to_jbytes!(env, list_transactions(instance as *mut c_void, &account_id)), make_jnull())
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_SledRepository_addTransaction(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray, transaction: jbyteArray) {
    let account_id = convert_jbytearray!(env, jaccount_id, ());
    let transaction_bytes = convert_jbytearray!(env, transaction, ());
    ok_or_throw(&env, add_transaction(instance as *mut c_void, &account_id, &transaction_bytes), ());
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_Repository_getBalance(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray) -> jbyteArray {
    let account_id = convert_jbytearray!(env, jaccount_id, make_jnull());
    ok_or_throw(&env, res_to_jbytes!(env, get_balance(instance as *mut c_void, &account_id)), make_jnull())
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_JsonRpcClient_create(env: JNIEnv, _class: JClass, url: JString) -> jlong {
    let url = convert_jstring!(env, url, 0);
    ok_or_throw(&env, json_rpc_client_create(&url).map(|r| r as jlong), 0)
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_JsonRpcClient_destroy(env: JNIEnv, _class: JClass, instance: jlong) {
    json_rpc_client_destroy(instance as *mut c_void);
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_JsonRpcClient_createAccount(env: JNIEnv, _class: JClass, instance: jlong, account: jbyteArray) {
    let account_bytes = convert_jbytearray!(env, account, ());
    ok_or_throw(&env, json_rpc_client_create_account(instance as *mut c_void, &account_bytes), ());
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_JsonRpcClient_getAccountInfo(env: JNIEnv, _class: JClass, instance: jlong, jaccount_id: jbyteArray) -> jbyteArray {
    let account_id = convert_jbytearray!(env, jaccount_id, make_jnull());
    ok_or_throw(&env, res_to_jbytes!(env, json_rpc_client_get_account_info(instance as *mut c_void, &account_id)), make_jnull())
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_Sync_cloneRemote(env: JNIEnv, _class: JClass, repoPtr: jlong, remotePtr: jlong, jaccount_id: jbyteArray) {
    let account_id = convert_jbytearray!(env, jaccount_id, ());
    ok_or_throw(&env, sync_clone_remote(repoPtr as *mut c_void, remotePtr as *mut c_void, &account_id), ())
}

#[no_mangle]
#[allow(non_snake_case)]
pub unsafe extern "system" fn Java_org_bustany_flouze_flouzeflutter_Sync_sync(env: JNIEnv, _class: JClass, repoPtr: jlong, remotePtr: jlong, jaccount_id: jbyteArray) {
    let account_id = convert_jbytearray!(env, jaccount_id, ());
    ok_or_throw(&env, sync_sync(repoPtr as *mut c_void, remotePtr as *mut c_void, &account_id), ())
}
