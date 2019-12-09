import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'bytes.dart';
import 'ffi_helpers.dart';
import 'flouze_lib_ffi.dart';
import 'flouze.pb.dart';
import 'utf8.dart';

class NativeJsonRpcClient extends ffi.Struct<NativeJsonRpcClient> {}

typedef flouze_json_rpc_client_create_t = ffi.Pointer<NativeJsonRpcClient>
    Function(ffi.Pointer<Utf8> filename, ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_json_rpc_client_destroy_t = ffi.Void Function(
    ffi.Pointer<NativeJsonRpcClient>);
typedef flouze_json_rpc_client_create_account_t = ffi.Void Function(
    ffi.Pointer<NativeJsonRpcClient>,
    ffi.Pointer<Byte> accountData,
    ffi.IntPtr accountLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_json_rpc_client_get_account_info_t = ffi.Void Function(
    ffi.Pointer<NativeJsonRpcClient>,
    ffi.Pointer<Byte> accountId,
    ffi.IntPtr accountIdLen,
    ffi.Pointer<ffi.Pointer<Byte>> account,
    ffi.Pointer<ffi.IntPtr> accountLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);

class _JsonRpcClientBindings {
  ffi.Pointer<NativeJsonRpcClient> Function(
      ffi.Pointer<Utf8>, ffi.Pointer<ffi.Pointer<Utf8>>) create;
  ffi.Void Function(ffi.Pointer<NativeJsonRpcClient>) destroy;
  ffi.Void Function(ffi.Pointer<NativeJsonRpcClient>, ffi.Pointer<Byte>, int,
      ffi.Pointer<ffi.Pointer<Utf8>>) createAccount;
  ffi.Void Function(
      ffi.Pointer<NativeJsonRpcClient>,
      ffi.Pointer<Byte>,
      int,
      ffi.Pointer<ffi.Pointer<Byte>>,
      ffi.Pointer<ffi.IntPtr>,
      ffi.Pointer<ffi.Pointer<Utf8>>) getAccountInfo;

  _JsonRpcClientBindings() {
    create = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_json_rpc_client_create_t>>(
            "flouze_json_rpc_client_create")
        .asFunction();

    destroy = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_json_rpc_client_destroy_t>>(
            "flouze_json_rpc_client_destroy")
        .asFunction();

    createAccount = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_json_rpc_client_create_account_t>>(
            "flouze_json_rpc_client_create_account")
        .asFunction();

    getAccountInfo = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_json_rpc_client_get_account_info_t>>(
            "flouze_json_rpc_client_get_account_info")
        .asFunction();
  }
}

_JsonRpcClientBindings _cachedJsonRpcClientBindings;

_JsonRpcClientBindings get _jsonRpcClientBindings =>
    _cachedJsonRpcClientBindings ??= _JsonRpcClientBindings();

class _JsonRpcHelpers {
  static void destroy(ffi.Pointer<NativeJsonRpcClient> ptr) =>
      _jsonRpcClientBindings.destroy(ptr);

  static void createAccount(
          ffi.Pointer<NativeJsonRpcClient> ptr, Account account) =>
      createAccountBytes(ptr, account.writeToBuffer());

  static void createAccountBytes(
      ffi.Pointer<NativeJsonRpcClient> ptr, Uint8List account) {
    withError((errPtr) => withCBytes(
        account,
        (data, len) =>
            _jsonRpcClientBindings.createAccount(ptr, data, len, errPtr)));
  }

  static Account getAccountInfo(
          ffi.Pointer<NativeJsonRpcClient> ptr, List<int> accountId) =>
      Account.fromBuffer(
          getAccountInfoBytes(ptr, Uint8List.fromList(accountId)));

  static Uint8List getAccountInfoBytes(
          ffi.Pointer<NativeJsonRpcClient> ptr, Uint8List accountId) =>
      withOutCBytes((accountDataPtr, accountDataLen) => withError((errPtr) =>
          withCBytes(
              accountId,
              (cAccountId, cAccountIdLen) =>
                  _jsonRpcClientBindings.getAccountInfo(
                      ptr,
                      cAccountId,
                      cAccountIdLen,
                      accountDataPtr,
                      accountDataLen,
                      errPtr)))).bytes ??
      Uint8List(0);
}

class _JsonRpcClientMainParams extends Call {
  _JsonRpcClientMainParams(this.url);

  String url;
}

class _JsonRpcClientCreateAccount extends Call {
  _JsonRpcClientCreateAccount(this.account);

  Uint8List account;
}

class _JsonRpcClientGetAccountInfo extends Call {
  _JsonRpcClientGetAccountInfo(this.accountId);

  Uint8List accountId;
}

class _JsonRpcClientGetNativePointer extends Call {}

class JsonRpcClient extends IsolateProxy {
  JsonRpcClient._(Future<SendPort> Function() factory) : super(factory);

  static void _isolateMain(dynamic params) {
    _JsonRpcClientMainParams mainParams = params;

    IsolateProxy.handleCalls(
      mainParams.sender,
      () {
        return withError((errPtr) => withCStr(mainParams.url,
            (cUrl) => _jsonRpcClientBindings.create(cUrl, errPtr)));
      },
      _handleCall,
    );
  }

  static dynamic _handleCall(dynamic instance, Call call) {
    ffi.Pointer<NativeJsonRpcClient> ptr = instance;

    switch (call.runtimeType) {
      case DestroyCall:
        return _JsonRpcHelpers.destroy(ptr);
      case _JsonRpcClientCreateAccount:
        return _JsonRpcHelpers.createAccountBytes(
            ptr, (call as _JsonRpcClientCreateAccount).account);
      case _JsonRpcClientGetAccountInfo:
        return _JsonRpcHelpers.getAccountInfoBytes(
            ptr, (call as _JsonRpcClientGetAccountInfo).accountId);
      case _JsonRpcClientGetNativePointer:
        return ptr.address;
      default:
        throw Exception("Unknown call type ${call.runtimeType.toString()}");
    }
  }

  static Future<SendPort> Function() _withUrlFactory(String url) => () =>
      IsolateProxy.spawnInIsolate(_JsonRpcClientMainParams(url), _isolateMain);

  factory JsonRpcClient.withUrl(String url) =>
      JsonRpcClient._(_withUrlFactory(url));

  Future<void> createAccount(Account account) =>
      call(_JsonRpcClientCreateAccount(account.writeToBuffer()));

  Future<Account> getAccountInfo(List<int> accountId) =>
      call(_JsonRpcClientGetAccountInfo(Uint8List.fromList(accountId)))
          .then((bytes) => Account.fromBuffer(bytes));

  Future<ffi.Pointer<NativeJsonRpcClient>> getNativePointer() =>
      call(_JsonRpcClientGetNativePointer()).then(
          (address) => ffi.Pointer<NativeJsonRpcClient>.fromAddress(address));
}
