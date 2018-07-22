///
//  Generated code. Do not modify.
///
// ignore_for_file: non_constant_identifier_names,library_prefixes

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

class PayedBy extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('PayedBy')
    ..a<List<int>>(1, 'person', PbFieldType.OY)
    ..a<int>(2, 'amount', PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  PayedBy() : super();
  PayedBy.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  PayedBy.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  PayedBy clone() => new PayedBy()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static PayedBy create() => new PayedBy();
  static PbList<PayedBy> createRepeated() => new PbList<PayedBy>();
  static PayedBy getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyPayedBy();
    return _defaultInstance;
  }
  static PayedBy _defaultInstance;
  static void $checkItem(PayedBy v) {
    if (v is! PayedBy) checkItemFailed(v, 'PayedBy');
  }

  List<int> get person => $_getN(0);
  set person(List<int> v) { $_setBytes(0, v); }
  bool hasPerson() => $_has(0);
  void clearPerson() => clearField(1);

  int get amount => $_get(1, 0);
  set amount(int v) { $_setUnsignedInt32(1, v); }
  bool hasAmount() => $_has(1);
  void clearAmount() => clearField(2);
}

class _ReadonlyPayedBy extends PayedBy with ReadonlyMessageMixin {}

class PayedFor extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('PayedFor')
    ..a<List<int>>(1, 'person', PbFieldType.OY)
    ..a<int>(2, 'amount', PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  PayedFor() : super();
  PayedFor.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  PayedFor.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  PayedFor clone() => new PayedFor()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static PayedFor create() => new PayedFor();
  static PbList<PayedFor> createRepeated() => new PbList<PayedFor>();
  static PayedFor getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyPayedFor();
    return _defaultInstance;
  }
  static PayedFor _defaultInstance;
  static void $checkItem(PayedFor v) {
    if (v is! PayedFor) checkItemFailed(v, 'PayedFor');
  }

  List<int> get person => $_getN(0);
  set person(List<int> v) { $_setBytes(0, v); }
  bool hasPerson() => $_has(0);
  void clearPerson() => clearField(1);

  int get amount => $_get(1, 0);
  set amount(int v) { $_setUnsignedInt32(1, v); }
  bool hasAmount() => $_has(1);
  void clearAmount() => clearField(2);
}

class _ReadonlyPayedFor extends PayedFor with ReadonlyMessageMixin {}

class Transaction extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Transaction')
    ..a<List<int>>(1, 'uuid', PbFieldType.OY)
    ..a<List<int>>(2, 'parent', PbFieldType.OY)
    ..a<int>(3, 'amount', PbFieldType.OU3)
    ..pp<PayedBy>(4, 'payedBy', PbFieldType.PM, PayedBy.$checkItem, PayedBy.create)
    ..pp<PayedFor>(5, 'payedFor', PbFieldType.PM, PayedFor.$checkItem, PayedFor.create)
    ..aOS(6, 'label')
    ..a<Int64>(7, 'timestamp', PbFieldType.OU6, Int64.ZERO)
    ..aOB(8, 'deleted')
    ..a<List<int>>(9, 'replaces', PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  Transaction() : super();
  Transaction.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Transaction.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Transaction clone() => new Transaction()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static Transaction create() => new Transaction();
  static PbList<Transaction> createRepeated() => new PbList<Transaction>();
  static Transaction getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyTransaction();
    return _defaultInstance;
  }
  static Transaction _defaultInstance;
  static void $checkItem(Transaction v) {
    if (v is! Transaction) checkItemFailed(v, 'Transaction');
  }

  List<int> get uuid => $_getN(0);
  set uuid(List<int> v) { $_setBytes(0, v); }
  bool hasUuid() => $_has(0);
  void clearUuid() => clearField(1);

  List<int> get parent => $_getN(1);
  set parent(List<int> v) { $_setBytes(1, v); }
  bool hasParent() => $_has(1);
  void clearParent() => clearField(2);

  int get amount => $_get(2, 0);
  set amount(int v) { $_setUnsignedInt32(2, v); }
  bool hasAmount() => $_has(2);
  void clearAmount() => clearField(3);

  List<PayedBy> get payedBy => $_getList(3);

  List<PayedFor> get payedFor => $_getList(4);

  String get label => $_getS(5, '');
  set label(String v) { $_setString(5, v); }
  bool hasLabel() => $_has(5);
  void clearLabel() => clearField(6);

  Int64 get timestamp => $_getI64(6);
  set timestamp(Int64 v) { $_setInt64(6, v); }
  bool hasTimestamp() => $_has(6);
  void clearTimestamp() => clearField(7);

  bool get deleted => $_get(7, false);
  set deleted(bool v) { $_setBool(7, v); }
  bool hasDeleted() => $_has(7);
  void clearDeleted() => clearField(8);

  List<int> get replaces => $_getN(8);
  set replaces(List<int> v) { $_setBytes(8, v); }
  bool hasReplaces() => $_has(8);
  void clearReplaces() => clearField(9);
}

class _ReadonlyTransaction extends Transaction with ReadonlyMessageMixin {}

class Person extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Person')
    ..a<List<int>>(1, 'uuid', PbFieldType.OY)
    ..aOS(2, 'name')
    ..hasRequiredFields = false
  ;

  Person() : super();
  Person.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Person.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Person clone() => new Person()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static Person create() => new Person();
  static PbList<Person> createRepeated() => new PbList<Person>();
  static Person getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyPerson();
    return _defaultInstance;
  }
  static Person _defaultInstance;
  static void $checkItem(Person v) {
    if (v is! Person) checkItemFailed(v, 'Person');
  }

  List<int> get uuid => $_getN(0);
  set uuid(List<int> v) { $_setBytes(0, v); }
  bool hasUuid() => $_has(0);
  void clearUuid() => clearField(1);

  String get name => $_getS(1, '');
  set name(String v) { $_setString(1, v); }
  bool hasName() => $_has(1);
  void clearName() => clearField(2);
}

class _ReadonlyPerson extends Person with ReadonlyMessageMixin {}

class Account extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Account')
    ..a<List<int>>(1, 'uuid', PbFieldType.OY)
    ..aOS(2, 'label')
    ..a<List<int>>(3, 'latestTransaction', PbFieldType.OY)
    ..a<List<int>>(4, 'latestSynchronizedTransaction', PbFieldType.OY)
    ..pp<Person>(5, 'members', PbFieldType.PM, Person.$checkItem, Person.create)
    ..hasRequiredFields = false
  ;

  Account() : super();
  Account.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Account.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Account clone() => new Account()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static Account create() => new Account();
  static PbList<Account> createRepeated() => new PbList<Account>();
  static Account getDefault() {
    if (_defaultInstance == null) _defaultInstance = new _ReadonlyAccount();
    return _defaultInstance;
  }
  static Account _defaultInstance;
  static void $checkItem(Account v) {
    if (v is! Account) checkItemFailed(v, 'Account');
  }

  List<int> get uuid => $_getN(0);
  set uuid(List<int> v) { $_setBytes(0, v); }
  bool hasUuid() => $_has(0);
  void clearUuid() => clearField(1);

  String get label => $_getS(1, '');
  set label(String v) { $_setString(1, v); }
  bool hasLabel() => $_has(1);
  void clearLabel() => clearField(2);

  List<int> get latestTransaction => $_getN(2);
  set latestTransaction(List<int> v) { $_setBytes(2, v); }
  bool hasLatestTransaction() => $_has(2);
  void clearLatestTransaction() => clearField(3);

  List<int> get latestSynchronizedTransaction => $_getN(3);
  set latestSynchronizedTransaction(List<int> v) { $_setBytes(3, v); }
  bool hasLatestSynchronizedTransaction() => $_has(3);
  void clearLatestSynchronizedTransaction() => clearField(4);

  List<Person> get members => $_getList(4);
}

class _ReadonlyAccount extends Account with ReadonlyMessageMixin {}

