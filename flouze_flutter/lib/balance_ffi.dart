import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

import 'bindings.pb.dart' as Bindings;
import 'bytes.dart';
import 'ffi_helpers.dart';
import 'flouze_lib_ffi.dart';
import 'utf8.dart';

typedef flouze_balance_get_transfers_t = ffi.Void Function(
    ffi.Pointer<Byte> balance,
    ffi.IntPtr balanceLen,
    ffi.Pointer<ffi.Pointer<Byte>> transfers,
    ffi.Pointer<ffi.IntPtr> transfersLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);

class _BalanceBindings {
  ffi.Void Function(ffi.Pointer<Byte>, int, ffi.Pointer<ffi.Pointer<Byte>>,
      ffi.Pointer<ffi.IntPtr>, ffi.Pointer<ffi.Pointer<Utf8>>) getTransfers;

  _BalanceBindings() {
    getTransfers = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_balance_get_transfers_t>>(
            "flouze_balance_get_transfers")
        .asFunction();
  }
}

_BalanceBindings _cachedBalanceBindings;

_BalanceBindings get _balanceBindings =>
    _cachedBalanceBindings ??= _BalanceBindings();

class _BalanceHelpers {
  static Uint8List getTransfersBytes(Uint8List balance) =>
      withOutCBytes((transferDataPtr, transferDataLen) => withError((errPtr) =>
          withCBytes(
              balance,
              (cBalance, cBalanceLen) => _balanceBindings.getTransfers(
                  cBalance,
                  cBalanceLen,
                  transferDataPtr,
                  transferDataLen,
                  errPtr)))).bytes ??
      Uint8List(0);
}

class _BalanceMainParams extends Call {}

class _BalanceGetTransfers extends Call {
  _BalanceGetTransfers(this.balance);

  final Uint8List balance;
}

Balance _cachedInstance;

Balance get _instance => _cachedInstance ??= Balance();

class Balance extends IsolateProxy {
  Balance()
      : super(() =>
            IsolateProxy.spawnInIsolate(_BalanceMainParams(), _isolateMain));

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
        return null;
      case _BalanceGetTransfers:
        return _BalanceHelpers.getTransfersBytes(
            (call as _BalanceGetTransfers).balance);
      default:
        throw Exception("Unknown call type ${call.runtimeType.toString()}");
    }
  }

  Future<List<Bindings.Transfer>> _getTransfers(
      Map<List<int>, int> balance) async {
    final protoBalance = Bindings.Balance.create()
      ..entries
          .addAll(balance.entries.map((e) => Bindings.Balance_Entry.create()
            ..person = e.key
            ..balance = Int64(e.value)));

    return call(_BalanceGetTransfers(protoBalance.writeToBuffer()))
        .then((bytes) => Bindings.Transfers.fromBuffer(bytes).transfers);
  }

  static Future<List<Bindings.Transfer>> getTransfers(
          Map<List<int>, int> balance) async =>
      _instance._getTransfers(balance);
}
