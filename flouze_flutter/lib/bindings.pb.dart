///
//  Generated code. Do not modify.
//  source: bindings.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'flouze.pb.dart' as $0;

class AccountList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('AccountList', package: const $pb.PackageName('flouze_flutter'), createEmptyInstance: create)
    ..pc<$0.Account>(1, 'accounts', $pb.PbFieldType.PM, subBuilder: $0.Account.create)
    ..hasRequiredFields = false
  ;

  AccountList._() : super();
  factory AccountList() => create();
  factory AccountList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AccountList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  AccountList clone() => AccountList()..mergeFromMessage(this);
  AccountList copyWith(void Function(AccountList) updates) => super.copyWith((message) => updates(message as AccountList));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AccountList create() => AccountList._();
  AccountList createEmptyInstance() => create();
  static $pb.PbList<AccountList> createRepeated() => $pb.PbList<AccountList>();
  @$core.pragma('dart2js:noInline')
  static AccountList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AccountList>(create);
  static AccountList _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$0.Account> get accounts => $_getList(0);
}

class TransactionList extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('TransactionList', package: const $pb.PackageName('flouze_flutter'), createEmptyInstance: create)
    ..pc<$0.Transaction>(1, 'transactions', $pb.PbFieldType.PM, subBuilder: $0.Transaction.create)
    ..hasRequiredFields = false
  ;

  TransactionList._() : super();
  factory TransactionList() => create();
  factory TransactionList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  TransactionList clone() => TransactionList()..mergeFromMessage(this);
  TransactionList copyWith(void Function(TransactionList) updates) => super.copyWith((message) => updates(message as TransactionList));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TransactionList create() => TransactionList._();
  TransactionList createEmptyInstance() => create();
  static $pb.PbList<TransactionList> createRepeated() => $pb.PbList<TransactionList>();
  @$core.pragma('dart2js:noInline')
  static TransactionList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransactionList>(create);
  static TransactionList _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$0.Transaction> get transactions => $_getList(0);
}

class Balance_Entry extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Balance.Entry', package: const $pb.PackageName('flouze_flutter'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, 'person', $pb.PbFieldType.OY)
    ..aInt64(2, 'balance')
    ..hasRequiredFields = false
  ;

  Balance_Entry._() : super();
  factory Balance_Entry() => create();
  factory Balance_Entry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Balance_Entry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Balance_Entry clone() => Balance_Entry()..mergeFromMessage(this);
  Balance_Entry copyWith(void Function(Balance_Entry) updates) => super.copyWith((message) => updates(message as Balance_Entry));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Balance_Entry create() => Balance_Entry._();
  Balance_Entry createEmptyInstance() => create();
  static $pb.PbList<Balance_Entry> createRepeated() => $pb.PbList<Balance_Entry>();
  @$core.pragma('dart2js:noInline')
  static Balance_Entry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Balance_Entry>(create);
  static Balance_Entry _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get person => $_getN(0);
  @$pb.TagNumber(1)
  set person($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPerson() => $_has(0);
  @$pb.TagNumber(1)
  void clearPerson() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get balance => $_getI64(1);
  @$pb.TagNumber(2)
  set balance($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBalance() => $_has(1);
  @$pb.TagNumber(2)
  void clearBalance() => clearField(2);
}

class Balance extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Balance', package: const $pb.PackageName('flouze_flutter'), createEmptyInstance: create)
    ..pc<Balance_Entry>(1, 'entries', $pb.PbFieldType.PM, subBuilder: Balance_Entry.create)
    ..hasRequiredFields = false
  ;

  Balance._() : super();
  factory Balance() => create();
  factory Balance.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Balance.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Balance clone() => Balance()..mergeFromMessage(this);
  Balance copyWith(void Function(Balance) updates) => super.copyWith((message) => updates(message as Balance));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Balance create() => Balance._();
  Balance createEmptyInstance() => create();
  static $pb.PbList<Balance> createRepeated() => $pb.PbList<Balance>();
  @$core.pragma('dart2js:noInline')
  static Balance getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Balance>(create);
  static Balance _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Balance_Entry> get entries => $_getList(0);
}

