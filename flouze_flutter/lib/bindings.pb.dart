///
//  Generated code. Do not modify.
///
// ignore_for_file: non_constant_identifier_names,library_prefixes

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

import 'flouze.pb.dart' as $flouze$model;

class AccountList extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('AccountList')
    ..pp<$flouze$model.Account>(1, 'accounts', PbFieldType.PM, $flouze$model.Account.$checkItem, $flouze$model.Account.create)
    ..hasRequiredFields = false
  ;

  AccountList() : super();
  AccountList.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  AccountList.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  AccountList clone() => new AccountList()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static AccountList create() => new AccountList();
  static PbList<AccountList> createRepeated() => new PbList<AccountList>();
  static AccountList getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyAccountList();
    return _defaultInstance;
  }
  static AccountList _defaultInstance;
  static void $checkItem(AccountList v) {
    if (v is! AccountList) checkItemFailed(v, 'AccountList');
  }

  List<$flouze$model.Account> get accounts => $_getList(0);
}

class _ReadonlyAccountList extends AccountList with ReadonlyMessageMixin {}

class TransactionList extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('TransactionList')
    ..pp<$flouze$model.Transaction>(1, 'transactions', PbFieldType.PM, $flouze$model.Transaction.$checkItem, $flouze$model.Transaction.create)
    ..hasRequiredFields = false
  ;

  TransactionList() : super();
  TransactionList.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  TransactionList.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  TransactionList clone() => new TransactionList()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static TransactionList create() => new TransactionList();
  static PbList<TransactionList> createRepeated() => new PbList<TransactionList>();
  static TransactionList getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyTransactionList();
    return _defaultInstance;
  }
  static TransactionList _defaultInstance;
  static void $checkItem(TransactionList v) {
    if (v is! TransactionList) checkItemFailed(v, 'TransactionList');
  }

  List<$flouze$model.Transaction> get transactions => $_getList(0);
}

class _ReadonlyTransactionList extends TransactionList with ReadonlyMessageMixin {}

class Balance_Entry extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Balance_Entry')
    ..a<List<int>>(1, 'person', PbFieldType.OY)
    ..aInt64(2, 'balance')
    ..hasRequiredFields = false
  ;

  Balance_Entry() : super();
  Balance_Entry.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Balance_Entry.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Balance_Entry clone() => new Balance_Entry()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static Balance_Entry create() => new Balance_Entry();
  static PbList<Balance_Entry> createRepeated() => new PbList<Balance_Entry>();
  static Balance_Entry getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyBalance_Entry();
    return _defaultInstance;
  }
  static Balance_Entry _defaultInstance;
  static void $checkItem(Balance_Entry v) {
    if (v is! Balance_Entry) checkItemFailed(v, 'Balance_Entry');
  }

  List<int> get person => $_getN(0);
  set person(List<int> v) { $_setBytes(0, v); }
  bool hasPerson() => $_has(0);
  void clearPerson() => clearField(1);

  Int64 get balance => $_getI64(1);
  set balance(Int64 v) { $_setInt64(1, v); }
  bool hasBalance() => $_has(1);
  void clearBalance() => clearField(2);
}

class _ReadonlyBalance_Entry extends Balance_Entry with ReadonlyMessageMixin {}

class Balance extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Balance')
    ..pp<Balance_Entry>(1, 'entries', PbFieldType.PM, Balance_Entry.$checkItem, Balance_Entry.create)
    ..hasRequiredFields = false
  ;

  Balance() : super();
  Balance.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Balance.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Balance clone() => new Balance()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static Balance create() => new Balance();
  static PbList<Balance> createRepeated() => new PbList<Balance>();
  static Balance getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyBalance();
    return _defaultInstance;
  }
  static Balance _defaultInstance;
  static void $checkItem(Balance v) {
    if (v is! Balance) checkItemFailed(v, 'Balance');
  }

  List<Balance_Entry> get entries => $_getList(0);
}

class _ReadonlyBalance extends Balance with ReadonlyMessageMixin {}

