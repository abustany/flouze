use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_void};

use super::*;

fn forward_error<T>(res: &FFIResult<T>, c_err: *mut *mut c_char) {
    if !c_err.is_null() {
        unsafe {
            *c_err = match *res {
                Ok(_) => std::ptr::null_mut(),
                Err(ref e) => CString::new(e.as_ref()).unwrap().into_raw(),
            }
        }
    }
}

fn vec_to_c<T>(mut vec: Vec<T>, c_data: *mut *mut T, c_len: *mut usize) {
    unsafe {
        *c_len = vec.len();
        *c_data = if vec.is_empty() {
            std::ptr::null_mut()
        } else {
            vec.as_mut_ptr()
        };
        drop(Vec::from_raw_parts(*c_data, 0, 0));
    }

    std::mem::forget(vec);
}

#[no_mangle]
pub extern "C" fn flouze_error_free(err: *mut c_char) {
    if !err.is_null() {
        unsafe {
            CString::from_raw(err);
        }
    }
}

#[no_mangle]
pub extern "C" fn flouze_sled_repository_temporary(error: *mut *mut c_char) -> *mut c_void {
    let res = sled_repository_temporary();
    forward_error(&res, error);
    res.unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "C" fn flouze_sled_repository_from_file(
    path: *const c_char,
    error: *mut *mut c_char,
) -> *mut c_void {
    let path = unsafe { CStr::from_ptr(path).to_string_lossy() };
    let res = sled_repository_from_file(&path);
    forward_error(&res, error);
    res.unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "C" fn flouze_sled_repository_destroy(repo: *mut c_void) {
    unsafe {
        sled_repository_destroy(repo);
    }
}

#[no_mangle]
pub extern "C" fn flouze_sled_repository_add_account(
    repo: *mut c_void,
    account_data: *const u8,
    account_len: usize,
    error: *mut *mut c_char,
) {
    let account_data = unsafe { std::slice::from_raw_parts(account_data, account_len as usize) };
    let res = unsafe { add_account(repo, &account_data) };
    forward_error(&res, error);
}

#[no_mangle]
pub extern "C" fn flouze_sled_repository_delete_account(
    repo: *mut c_void,
    account_id: *const u8,
    account_id_len: usize,
    error: *mut *mut c_char,
) {
    let account_id = unsafe { std::slice::from_raw_parts(account_id, account_id_len) };
    let res = unsafe { delete_account(repo, &account_id) };
    forward_error(&res, error);
}

#[no_mangle]
pub extern "C" fn flouze_sled_repository_list_accounts(
    repo: *mut c_void,
    account_list: *mut *mut u8,
    account_list_len: *mut usize,
    error: *mut *mut c_char,
) {
    let res = unsafe { list_accounts(repo) };
    forward_error(&res, error);

    if let Ok(data) = res {
        vec_to_c(data, account_list, account_list_len);
    }
}

#[no_mangle]
pub extern "C" fn flouze_sled_repository_list_transactions(
    repo: *mut c_void,
    account_id: *const u8,
    account_id_len: usize,
    tx_list: *mut *mut u8,
    tx_list_len: *mut usize,
    error: *mut *mut c_char,
) {
    let account_id = unsafe { std::slice::from_raw_parts(account_id, account_id_len) };
    let res = unsafe { list_transactions(repo, &account_id) };
    forward_error(&res, error);

    if let Ok(data) = res {
        vec_to_c(data, tx_list, tx_list_len);
    }
}

#[no_mangle]
pub extern "C" fn flouze_sled_repository_add_transaction(
    repo: *mut c_void,
    account_id: *const u8,
    account_id_len: usize,
    tx: *const u8,
    tx_len: usize,
    error: *mut *mut c_char,
) {
    let account_id = unsafe { std::slice::from_raw_parts(account_id, account_id_len) };
    let tx = unsafe { std::slice::from_raw_parts(tx, tx_len as usize) };
    let res = unsafe { add_transaction(repo, &account_id, tx) };
    forward_error(&res, error);
}

#[no_mangle]
pub extern "C" fn flouze_sled_repository_get_balance(
    repo: *mut c_void,
    account_id: *const u8,
    account_id_len: usize,
    balance: *mut *mut u8,
    balance_len: *mut usize,
    error: *mut *mut c_char,
) {
    let account_id = unsafe { std::slice::from_raw_parts(account_id, account_id_len) };
    let res = unsafe { get_balance(repo, &account_id) };
    forward_error(&res, error);

    if let Ok(data) = res {
        vec_to_c(data, balance, balance_len);
    }
}

#[no_mangle]
pub extern "C" fn flouze_json_rpc_client_create(
    url: *const c_char,
    error: *mut *mut c_char,
) -> *mut c_void {
    let url = unsafe { CStr::from_ptr(url).to_string_lossy() };
    let res = json_rpc_client_create(&url);
    forward_error(&res, error);
    res.unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "C" fn flouze_json_rpc_client_destroy(client: *mut c_void) {
    unsafe { json_rpc_client_destroy(client) };
}

#[no_mangle]
pub extern "C" fn flouze_json_rpc_client_create_account(
    client: *mut c_void,
    account_data: *const u8,
    account_len: usize,
    error: *mut *mut c_char,
) {
    let account_data = unsafe { std::slice::from_raw_parts(account_data, account_len as usize) };
    let res = unsafe { json_rpc_client_create_account(client, &account_data) };
    forward_error(&res, error);
}

#[no_mangle]
pub extern "C" fn flouze_json_rpc_client_get_account_info(
    client: *mut c_void,
    account_id: *const u8,
    account_id_len: usize,
    account: *mut *mut u8,
    account_len: *mut usize,
    error: *mut *mut c_char,
) {
    let account_id = unsafe { std::slice::from_raw_parts(account_id, account_id_len) };
    let res = unsafe { json_rpc_client_get_account_info(client, &account_id) };
    forward_error(&res, error);

    if let Ok(data) = res {
        vec_to_c(data, account, account_len);
    }
}

#[no_mangle]
pub extern "C" fn flouze_sync_clone_remote(
    repo: *mut c_void,
    client: *mut c_void,
    account_id: *const u8,
    account_id_len: usize,
    error: *mut *mut c_char,
) {
    let account_id = unsafe { std::slice::from_raw_parts(account_id, account_id_len as usize) };
    let res = unsafe { sync_clone_remote(repo, client, &account_id) };
    forward_error(&res, error);
}

#[no_mangle]
pub extern "C" fn flouze_sync_sync(
    repo: *mut c_void,
    client: *mut c_void,
    account_id: *const u8,
    account_id_len: usize,
    error: *mut *mut c_char,
) {
    let account_id = unsafe { std::slice::from_raw_parts(account_id, account_id_len as usize) };
    let res = unsafe { sync_sync(repo, client, &account_id) };
    forward_error(&res, error);
}
