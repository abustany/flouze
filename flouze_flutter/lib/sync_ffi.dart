import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'bytes.dart';
import 'events.dart';
import 'ffi_helpers.dart';
import 'flouze_lib_ffi.dart';
import 'json_rpc_client_ffi.dart';
import 'sled_repository_ffi.dart';
import 'utf8.dart';

typedef flouze_sync_clone_remote_t = ffi.Void Function(
    ffi.Pointer<NativeSledRepository>,
    ffi.Pointer<NativeJsonRpcClient>,
    ffi.Pointer<Byte> accountId,
    ffi.IntPtr accountIdLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_sync_sync_t = ffi.Void Function(
    ffi.Pointer<NativeSledRepository>,
    ffi.Pointer<NativeJsonRpcClient>,
    ffi.Pointer<Byte> accountId,
    ffi.IntPtr accountIdLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);

class _SyncBindings {
  void Function(
      ffi.Pointer<NativeSledRepository>,
      ffi.Pointer<NativeJsonRpcClient>,
      ffi.Pointer<Byte>,
      int,
      ffi.Pointer<ffi.Pointer<Utf8>>) cloneRemote;
  void Function(
      ffi.Pointer<NativeSledRepository>,
      ffi.Pointer<NativeJsonRpcClient>,
      ffi.Pointer<Byte>,
      int,
      ffi.Pointer<ffi.Pointer<Utf8>>) sync;

  _SyncBindings() {
    cloneRemote = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sync_clone_remote_t>>(
            "flouze_sync_clone_remote")
        .asFunction();

    sync = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sync_sync_t>>("flouze_sync_sync")
        .asFunction();
  }
}

_SyncBindings _cachedSyncBindings;

_SyncBindings get _syncBindings => _cachedSyncBindings ??= _SyncBindings();

class _SyncHelpers {
  static void cloneRemote(ffi.Pointer<NativeSledRepository> repo,
      ffi.Pointer<NativeJsonRpcClient> client, List<int> accountId) {
    withError((errPtr) => withCBytes(
        Uint8List.fromList(accountId),
        (data, len) =>
            _syncBindings.cloneRemote(repo, client, data, len, errPtr)));
  }

  static void sync(ffi.Pointer<NativeSledRepository> repo,
      ffi.Pointer<NativeJsonRpcClient> client, List<int> accountId) {
    withError((errPtr) => withCBytes(Uint8List.fromList(accountId),
        (data, len) => _syncBindings.sync(repo, client, data, len, errPtr)));
  }
}

class _SyncMainParams extends Call {}

class _SyncCloneRemote extends Call {
  _SyncCloneRemote(this.repo, this.jsonRpcClient, this.accountId);

  final int repo;
  final int jsonRpcClient;
  final Uint8List accountId;
}

class _SyncSync extends Call {
  _SyncSync(this.repo, this.jsonRpcClient, this.accountId);

  final int repo;
  final int jsonRpcClient;
  final Uint8List accountId;
}

Sync _cachedInstance;

Sync get _instance => _cachedInstance ??= Sync();

class Sync extends IsolateProxy {
  Sync()
      : super(
            () => IsolateProxy.spawnInIsolate(_SyncMainParams(), _isolateMain));

  static void _isolateMain(dynamic params) {
    IsolateProxy.handleCalls(
      (params as Call).sender,
      () => null,
      _handleCall,
    );
  }

  static dynamic _handleCall(dynamic instance, Call call) {
    switch (call.runtimeType) {
      case DestroyCall:
        return null; // nothing to free
      case _SyncCloneRemote:
        final cloneCall = (call as _SyncCloneRemote);
        final repoPtr =
            ffi.Pointer<NativeSledRepository>.fromAddress(cloneCall.repo);
        final jsonRpcClientPtr = ffi.Pointer<NativeJsonRpcClient>.fromAddress(
            cloneCall.jsonRpcClient);
        return _SyncHelpers.cloneRemote(
            repoPtr, jsonRpcClientPtr, cloneCall.accountId);
      case _SyncSync:
        final syncCall = (call as _SyncSync);
        final repoPtr =
            ffi.Pointer<NativeSledRepository>.fromAddress(syncCall.repo);
        final jsonRpcClientPtr = ffi.Pointer<NativeJsonRpcClient>.fromAddress(
            syncCall.jsonRpcClient);
        return _SyncHelpers.sync(repoPtr, jsonRpcClientPtr, syncCall.accountId);
      default:
        throw Exception("Unknown call type ${call.runtimeType.toString()}");
    }
  }

  Future<void> _cloneRemote(SledRepository repo, JsonRpcClient client,
          List<int> accountId) async =>
      call(_SyncCloneRemote(
              (await repo.getNativePointer()).address,
              (await client.getNativePointer()).address,
              Uint8List.fromList(accountId)))
          .then((_) {
        Events.post(Events.ACCOUNT_LIST_CHANGED);
      });

  static Future<void> cloneRemote(SledRepository repo, JsonRpcClient client,
          List<int> accountId) async =>
      _instance._cloneRemote(repo, client, accountId);

  Future<void> _sync(SledRepository repo, JsonRpcClient client,
          List<int> accountId) async =>
      call(_SyncSync(
          (await repo.getNativePointer()).address,
          (await client.getNativePointer()).address,
          Uint8List.fromList(accountId)));

  static Future<void> sync(SledRepository repo, JsonRpcClient client,
          List<int> accountId) async =>
      _instance._sync(repo, client, accountId);
}
