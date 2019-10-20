///
//  Generated code. Do not modify.
//  source: flouze.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class PayedBy extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('PayedBy', package: const $pb.PackageName('flouze.model'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, 'person', $pb.PbFieldType.OY)
    ..a<$core.int>(2, 'amount', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  PayedBy._() : super();
  factory PayedBy() => create();
  factory PayedBy.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PayedBy.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  PayedBy clone() => PayedBy()..mergeFromMessage(this);
  PayedBy copyWith(void Function(PayedBy) updates) => super.copyWith((message) => updates(message as PayedBy));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PayedBy create() => PayedBy._();
  PayedBy createEmptyInstance() => create();
  static $pb.PbList<PayedBy> createRepeated() => $pb.PbList<PayedBy>();
  @$core.pragma('dart2js:noInline')
  static PayedBy getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PayedBy>(create);
  static PayedBy _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get person => $_getN(0);
  @$pb.TagNumber(1)
  set person($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPerson() => $_has(0);
  @$pb.TagNumber(1)
  void clearPerson() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get amount => $_getIZ(1);
  @$pb.TagNumber(2)
  set amount($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAmount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmount() => clearField(2);
}

class PayedFor extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('PayedFor', package: const $pb.PackageName('flouze.model'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, 'person', $pb.PbFieldType.OY)
    ..a<$core.int>(2, 'amount', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  PayedFor._() : super();
  factory PayedFor() => create();
  factory PayedFor.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PayedFor.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  PayedFor clone() => PayedFor()..mergeFromMessage(this);
  PayedFor copyWith(void Function(PayedFor) updates) => super.copyWith((message) => updates(message as PayedFor));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PayedFor create() => PayedFor._();
  PayedFor createEmptyInstance() => create();
  static $pb.PbList<PayedFor> createRepeated() => $pb.PbList<PayedFor>();
  @$core.pragma('dart2js:noInline')
  static PayedFor getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PayedFor>(create);
  static PayedFor _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get person => $_getN(0);
  @$pb.TagNumber(1)
  set person($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPerson() => $_has(0);
  @$pb.TagNumber(1)
  void clearPerson() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get amount => $_getIZ(1);
  @$pb.TagNumber(2)
  set amount($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAmount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAmount() => clearField(2);
}

class Transaction extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Transaction', package: const $pb.PackageName('flouze.model'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, 'uuid', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(2, 'parent', $pb.PbFieldType.OY)
    ..a<$core.int>(3, 'amount', $pb.PbFieldType.OU3)
    ..pc<PayedBy>(4, 'payedBy', $pb.PbFieldType.PM, subBuilder: PayedBy.create)
    ..pc<PayedFor>(5, 'payedFor', $pb.PbFieldType.PM, subBuilder: PayedFor.create)
    ..aOS(6, 'label')
    ..a<$fixnum.Int64>(7, 'timestamp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOB(8, 'deleted')
    ..a<$core.List<$core.int>>(9, 'replaces', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  Transaction._() : super();
  factory Transaction() => create();
  factory Transaction.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Transaction.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Transaction clone() => Transaction()..mergeFromMessage(this);
  Transaction copyWith(void Function(Transaction) updates) => super.copyWith((message) => updates(message as Transaction));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Transaction create() => Transaction._();
  Transaction createEmptyInstance() => create();
  static $pb.PbList<Transaction> createRepeated() => $pb.PbList<Transaction>();
  @$core.pragma('dart2js:noInline')
  static Transaction getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Transaction>(create);
  static Transaction _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get uuid => $_getN(0);
  @$pb.TagNumber(1)
  set uuid($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get parent => $_getN(1);
  @$pb.TagNumber(2)
  set parent($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasParent() => $_has(1);
  @$pb.TagNumber(2)
  void clearParent() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get amount => $_getIZ(2);
  @$pb.TagNumber(3)
  set amount($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAmount() => $_has(2);
  @$pb.TagNumber(3)
  void clearAmount() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<PayedBy> get payedBy => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<PayedFor> get payedFor => $_getList(4);

  @$pb.TagNumber(6)
  $core.String get label => $_getSZ(5);
  @$pb.TagNumber(6)
  set label($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasLabel() => $_has(5);
  @$pb.TagNumber(6)
  void clearLabel() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get timestamp => $_getI64(6);
  @$pb.TagNumber(7)
  set timestamp($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasTimestamp() => $_has(6);
  @$pb.TagNumber(7)
  void clearTimestamp() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get deleted => $_getBF(7);
  @$pb.TagNumber(8)
  set deleted($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasDeleted() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeleted() => clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.int> get replaces => $_getN(8);
  @$pb.TagNumber(9)
  set replaces($core.List<$core.int> v) { $_setBytes(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasReplaces() => $_has(8);
  @$pb.TagNumber(9)
  void clearReplaces() => clearField(9);
}

class Person extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Person', package: const $pb.PackageName('flouze.model'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, 'uuid', $pb.PbFieldType.OY)
    ..aOS(2, 'name')
    ..hasRequiredFields = false
  ;

  Person._() : super();
  factory Person() => create();
  factory Person.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Person.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Person clone() => Person()..mergeFromMessage(this);
  Person copyWith(void Function(Person) updates) => super.copyWith((message) => updates(message as Person));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Person create() => Person._();
  Person createEmptyInstance() => create();
  static $pb.PbList<Person> createRepeated() => $pb.PbList<Person>();
  @$core.pragma('dart2js:noInline')
  static Person getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Person>(create);
  static Person _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get uuid => $_getN(0);
  @$pb.TagNumber(1)
  set uuid($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);
}

class Account extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Account', package: const $pb.PackageName('flouze.model'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, 'uuid', $pb.PbFieldType.OY)
    ..aOS(2, 'label')
    ..a<$core.List<$core.int>>(3, 'latestTransaction', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(4, 'latestSynchronizedTransaction', $pb.PbFieldType.OY)
    ..pc<Person>(5, 'members', $pb.PbFieldType.PM, subBuilder: Person.create)
    ..hasRequiredFields = false
  ;

  Account._() : super();
  factory Account() => create();
  factory Account.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Account.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Account clone() => Account()..mergeFromMessage(this);
  Account copyWith(void Function(Account) updates) => super.copyWith((message) => updates(message as Account));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Account create() => Account._();
  Account createEmptyInstance() => create();
  static $pb.PbList<Account> createRepeated() => $pb.PbList<Account>();
  @$core.pragma('dart2js:noInline')
  static Account getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Account>(create);
  static Account _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get uuid => $_getN(0);
  @$pb.TagNumber(1)
  set uuid($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get latestTransaction => $_getN(2);
  @$pb.TagNumber(3)
  set latestTransaction($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLatestTransaction() => $_has(2);
  @$pb.TagNumber(3)
  void clearLatestTransaction() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get latestSynchronizedTransaction => $_getN(3);
  @$pb.TagNumber(4)
  set latestSynchronizedTransaction($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLatestSynchronizedTransaction() => $_has(3);
  @$pb.TagNumber(4)
  void clearLatestSynchronizedTransaction() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<Person> get members => $_getList(4);
}

