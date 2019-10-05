import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'bindings.pb.dart';
import 'bytes.dart';
import 'events.dart';
import 'ffi_helpers.dart';
import 'flouze_lib_ffi.dart';
import 'flouze.pb.dart';
import 'utf8.dart';

class NativeSledRepository extends ffi.Struct<NativeSledRepository> {}

typedef flouze_sled_repository_temporary_t = ffi.Pointer<NativeSledRepository>
Function(ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_sled_repository_from_file_t = ffi.Pointer<NativeSledRepository>
Function(ffi.Pointer<Utf8> filename, ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_sled_repository_destroy_t = ffi.Void Function(ffi.Pointer<NativeSledRepository>);
typedef flouze_sled_repository_add_account_t = ffi.Void Function(
    ffi.Pointer<NativeSledRepository>,
    ffi.Pointer<Byte> accountData,
    ffi.IntPtr accountLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_sled_repository_delete_account_t = ffi.Void Function(
    ffi.Pointer<NativeSledRepository>,
    ffi.Pointer<Byte> accountId,
    ffi.IntPtr accountIdLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_sled_repository_list_accounts_t = ffi.Void Function(
    ffi.Pointer<NativeSledRepository>,
    ffi.Pointer<ffi.Pointer<Byte>> accountList,
    ffi.Pointer<ffi.IntPtr> accountListLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_sled_repository_list_transactions_t = ffi.Void Function(
    ffi.Pointer<NativeSledRepository>,
    ffi.Pointer<Byte> accountId,
    ffi.IntPtr accountIdLen,
    ffi.Pointer<ffi.Pointer<Byte>> accountList,
    ffi.Pointer<ffi.IntPtr> accountListLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_sled_repository_add_transaction_t = ffi.Void Function(
    ffi.Pointer<NativeSledRepository>,
    ffi.Pointer<Byte> accountId,
    ffi.IntPtr accountIdLen,
    ffi.Pointer<Byte> txData,
    ffi.IntPtr txDataLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);
typedef flouze_sled_repository_get_balance_t = ffi.Void Function(
    ffi.Pointer<NativeSledRepository>,
    ffi.Pointer<Byte> accountId,
    ffi.IntPtr accountIdLen,
    ffi.Pointer<ffi.Pointer<Byte>> balance,
    ffi.Pointer<ffi.IntPtr> balanceLen,
    ffi.Pointer<ffi.Pointer<Utf8>> error);

class _SledRepositoryBindings {
  ffi.Void Function(ffi.Pointer<NativeSledRepository>) destroy;
  ffi.Pointer<NativeSledRepository> Function(ffi.Pointer<ffi.Pointer<Utf8>>) temporary;
  ffi.Pointer<NativeSledRepository> Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Pointer<Utf8>>) fromFile;
  ffi.Void Function(ffi.Pointer<NativeSledRepository>, ffi.Pointer<Byte>, int, ffi.Pointer<ffi.Pointer<Utf8>>) addAccount;
  ffi.Void Function(ffi.Pointer<NativeSledRepository>, ffi.Pointer<Byte>, int, ffi.Pointer<ffi.Pointer<Utf8>>) deleteAccount;
  ffi.Void Function(ffi.Pointer<NativeSledRepository>, ffi.Pointer<ffi.Pointer<Byte>>, ffi.Pointer<ffi.IntPtr>, ffi.Pointer<ffi.Pointer<Utf8>>) listAccounts;
  ffi.Void Function(ffi.Pointer<NativeSledRepository>, ffi.Pointer<Byte>, int, ffi.Pointer<ffi.Pointer<Byte>>, ffi.Pointer<ffi.IntPtr>, ffi.Pointer<ffi.Pointer<Utf8>>)listTransactions;
  ffi.Void Function(ffi.Pointer<NativeSledRepository>, ffi.Pointer<Byte>, int, ffi.Pointer<Byte>, int, ffi.Pointer<ffi.Pointer<Utf8>>) addTransaction;
  ffi.Void Function(ffi.Pointer<NativeSledRepository>, ffi.Pointer<Byte>, int, ffi.Pointer<ffi.Pointer<Byte>>, ffi.Pointer<ffi.IntPtr>, ffi.Pointer<ffi.Pointer<Utf8>>) getBalance;

  _SledRepositoryBindings() {
    destroy = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sled_repository_destroy_t>>(
        "flouze_sled_repository_destroy")
        .asFunction();

    temporary = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sled_repository_temporary_t>>(
        "flouze_sled_repository_temporary")
        .asFunction();

    fromFile = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sled_repository_from_file_t>>(
        "flouze_sled_repository_from_file")
        .asFunction();

    addAccount = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sled_repository_add_account_t>>(
        "flouze_sled_repository_add_account")
        .asFunction();

    deleteAccount = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sled_repository_delete_account_t>>(
        "flouze_sled_repository_delete_account")
        .asFunction();

    listAccounts = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sled_repository_list_accounts_t>>(
        "flouze_sled_repository_list_accounts")
        .asFunction();

    listTransactions = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sled_repository_list_transactions_t>>(
        "flouze_sled_repository_list_transactions")
        .asFunction();

    addTransaction = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sled_repository_add_transaction_t>>(
        "flouze_sled_repository_add_transaction")
        .asFunction();

    getBalance = flouzeLibrary
        .lookup<ffi.NativeFunction<flouze_sled_repository_get_balance_t>>(
        "flouze_sled_repository_get_balance")
        .asFunction();
  }
}

_SledRepositoryBindings _cachedSledRepositoryBindings;

_SledRepositoryBindings get _sledRepositoryBindings =>
    _cachedSledRepositoryBindings ??= _SledRepositoryBindings();

class _SledRepositoryHelpers {
  static void destroy(ffi.Pointer<NativeSledRepository> ptr) =>
      _sledRepositoryBindings.destroy(ptr);

  static void addAccount(ffi.Pointer<NativeSledRepository> ptr,
      Account account) => addAccountBytes(ptr, account.writeToBuffer());

  static void addAccountBytes(ffi.Pointer<NativeSledRepository> ptr,
      Uint8List account) {
    withError((errPtr) =>
        withCBytes(account, (data, len) =>
            _sledRepositoryBindings.addAccount(ptr, data, len, errPtr)));
  }

  static void deleteAccount(ffi.Pointer<NativeSledRepository> ptr,
      List<int> accountId) =>
    deleteAccountBytes(ptr, Uint8List.fromList(accountId));

  static void deleteAccountBytes(ffi.Pointer<NativeSledRepository> ptr,
      Uint8List accountId) {
    withError((errPtr) =>
        withCBytes(accountId, (data, len) =>
            _sledRepositoryBindings.deleteAccount(ptr, data, len, errPtr)));
  }

  static List<Account> listAccounts(ffi.Pointer<NativeSledRepository> ptr) =>
    AccountList
        .fromBuffer(listAccountsBytes(ptr))
        .accounts;

  static Uint8List listAccountsBytes(ffi.Pointer<NativeSledRepository> ptr) =>
    withOutCBytes((accountDataPtr, accountDataLenPtr) =>
        withError((errPtr) =>
            _sledRepositoryBindings.listAccounts(
                ptr, accountDataPtr, accountDataLenPtr, errPtr)
        )).bytes ?? Uint8List(0);

  static List<Transaction> listTransactions(
      ffi.Pointer<NativeSledRepository> ptr, List<int> accountId) =>
      TransactionList
          .fromBuffer(listTransactionsBytes(ptr, accountId))
          .transactions;

  static Uint8List listTransactionsBytes(ffi.Pointer<NativeSledRepository> ptr,
      List<int> accountId) =>
    withOutCBytes((txDataPtr, txDataLen) =>
        withError((errPtr) =>
            withCBytes(
                Uint8List.fromList(accountId), (cAccountId, cAccountIdLen) =>
                _sledRepositoryBindings.listTransactions(
                    ptr, cAccountId, cAccountIdLen, txDataPtr,
                    txDataLen, errPtr)))
    ).bytes ?? Uint8List(0);

  static void addTransaction(ffi.Pointer<NativeSledRepository> ptr,
      List<int> accountId, Transaction transaction) =>
    addTransactionBytes(ptr, Uint8List.fromList(accountId), transaction.writeToBuffer());

  static void addTransactionBytes(ffi.Pointer<NativeSledRepository> ptr,
      Uint8List accountId, Uint8List transaction) =>
    withError((errPtr) =>
        withCBytes(accountId, (accountId, accountIdLen) =>
            withCBytes(transaction, (txData, txDataLen) =>
                _sledRepositoryBindings.addTransaction(
                    ptr, accountId, accountIdLen, txData, txDataLen,
                    errPtr))));

  static Map<List<int>, int> getBalance(ffi.Pointer<NativeSledRepository> ptr,
      List<int> accountId) =>
      Map.fromEntries(Balance
          .fromBuffer(getBalanceBytes(ptr, Uint8List.fromList(accountId)))
          .entries
          .map((entry) => MapEntry(entry.person, entry.balance.toInt())));

  static Uint8List getBalanceBytes(ffi.Pointer<NativeSledRepository> ptr, Uint8List accountId) {
    final res = withOutCBytes((balanceDataPtr, balanceDataLen) =>
        withError((errPtr) =>
            withCBytes(
                Uint8List.fromList(accountId), (cAccountId, cAccountIdLen) =>
                _sledRepositoryBindings.getBalance(
                    ptr, cAccountId, cAccountIdLen, balanceDataPtr,
                    balanceDataLen, errPtr)))
    );

    return res.bytes ?? Uint8List(0);
  }
}

class _SledRepositoryMainParams extends Call {
  _SledRepositoryMainParams(this.path);
  final String path;
}

class _SledRepositoryListAccounts extends Call {
}

class _SledRepositoryAddAccount extends Call {
  _SledRepositoryAddAccount(this.account);
  final Uint8List account;
}

class _SledRepositoryDeleteAccount extends Call {
  _SledRepositoryDeleteAccount(this.accountId);
  final Uint8List accountId;
}

class _SledRepositoryListTransactions extends Call {
  _SledRepositoryListTransactions(this.accountId);
  final Uint8List accountId;
}

class _SledRepositoryAddTransaction extends Call {
  _SledRepositoryAddTransaction(this.accountId, this.transaction);
  final Uint8List accountId;
  final Uint8List transaction;
}

class _SledRepositoryGetBalance extends Call {
  _SledRepositoryGetBalance(this.accountId);
  final Uint8List accountId;
}

class _SledRepositoryGetNativePointer extends Call{}

class SledRepository extends IsolateProxy {
  //SledRepository._(Future<SendPort> Function() factory) : super(factory);
  SledRepository._(_SledRepositoryMainParams params)
    : super(() => IsolateProxy.spawnInIsolate(params, _isolateMain));

  static void _isolateMain(dynamic params) {
    _SledRepositoryMainParams mainParams = params;

    IsolateProxy.handleCalls(
        mainParams.sender,
        () {
          if (mainParams.path == null) {
            return withError((errPtr) => _sledRepositoryBindings.temporary(errPtr));
          } else {
            return withError((errPtr) => withCStr(mainParams.path, (cPath) => _sledRepositoryBindings.fromFile(cPath, errPtr)));
          }
        },
        _handleCall,
    );
  }

  static dynamic _handleCall(dynamic instance, Call call) {
    ffi.Pointer<NativeSledRepository> ptr = instance;

    switch(call.runtimeType) {
      case DestroyCall:
        return _SledRepositoryHelpers.destroy(ptr);
      case _SledRepositoryListAccounts:
        return _SledRepositoryHelpers.listAccountsBytes(ptr);
      case _SledRepositoryAddAccount:
        return _SledRepositoryHelpers.addAccountBytes(ptr, (call as _SledRepositoryAddAccount).account);
      case _SledRepositoryDeleteAccount:
        return _SledRepositoryHelpers.deleteAccountBytes(ptr, (call as _SledRepositoryDeleteAccount).accountId);
      case _SledRepositoryListTransactions:
        return _SledRepositoryHelpers.listTransactionsBytes(ptr, (call as _SledRepositoryListTransactions).accountId);
      case _SledRepositoryAddTransaction:
        final addCall = (call as _SledRepositoryAddTransaction);
        return _SledRepositoryHelpers.addTransactionBytes(ptr, addCall.accountId, addCall.transaction);
      case _SledRepositoryGetBalance:
        return _SledRepositoryHelpers.getBalanceBytes(ptr, (call as _SledRepositoryGetBalance).accountId);
      case _SledRepositoryGetNativePointer:
        return ptr;
      default:
        throw Exception("Unknown call type ${call.runtimeType.toString()}");
    }
  }

  factory SledRepository.temporary() => SledRepository._(_SledRepositoryMainParams(null));

  factory SledRepository.fromFile(String path) => SledRepository._(_SledRepositoryMainParams(path));

  Future<void> addAccount(Account account) =>
      call(_SledRepositoryAddAccount(account.writeToBuffer())).then((_) {
        Events.post(Events.ACCOUNT_LIST_CHANGED);
      });

  Future<void> deleteAccount(List<int> accountId) =>
      call(_SledRepositoryDeleteAccount(Uint8List.fromList(accountId))).then((_) {
        Events.post(Events.ACCOUNT_LIST_CHANGED);
      });

  Future<List<Account>> listAccounts() =>
      call(_SledRepositoryListAccounts()).then((bytes) =>
      AccountList
          .fromBuffer(bytes)
          .accounts);

  Future<List<Transaction>> listTransactions(List<int> accountId) =>
      call(_SledRepositoryListTransactions(Uint8List.fromList(accountId))).then((bytes) =>
      TransactionList
          .fromBuffer(bytes)
          .transactions);

  Future<void> addTransaction(List<int> accountId, Transaction transaction) =>
      call(_SledRepositoryAddTransaction(Uint8List.fromList(accountId), transaction.writeToBuffer()));

  Future<Map<List<int>, int>> getBalance(List<int> accountId) =>
      call(_SledRepositoryGetBalance(Uint8List.fromList(accountId))).then((bytes) =>
          Map.fromEntries(Balance.fromBuffer(bytes)
              .entries
              .map((entry) => MapEntry(entry.person, entry.balance.toInt())))
      );

  Future<ffi.Pointer<NativeSledRepository>> getNativePointer() =>
      call(_SledRepositoryGetNativePointer());
}
