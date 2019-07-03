import 'dart:async';

import 'package:collection/collection.dart';

import 'package:rxdart/rxdart.dart';

import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

import 'package:flouze/utils/account_members.dart';
import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/transactions.dart';
import 'package:flouze/utils/uuid.dart' as UUID;

abstract class AbstractPayedBy{
  String validate(int amount);
  List<Flouze.PayedBy> asPayedBy(int amount);
}

class PayedByOne extends AbstractPayedBy {
  final Flouze.Person person;

  PayedByOne._(this.person);

  factory PayedByOne.fromPayedBy(List<Flouze.PayedBy> payedBy, List<Flouze.Person> members) {
    assert(payedBy.length < 2);
    return payedBy.isEmpty ? PayedByOne._(null) : PayedByOne._(findPersonById(members, payedBy.first.person));
  }

  @override
  List<Flouze.PayedBy> asPayedBy(int amount) => [
    if (person != null)
      Flouze.PayedBy.create()
        ..person = person.uuid
        ..amount = amount
  ];

  @override
  String validate(int amount) {
    if (person == null) {
      return 'Please select the person who paid';
    }

    return null;
  }
}

class PayedByMany extends AbstractPayedBy {
  final Map<Flouze.Person, int> amounts;

  PayedByMany._(this.amounts);

  factory PayedByMany.fromPayedBy(List<Flouze.PayedBy> payedBy, List<Flouze.Person> members) {
    final entries = payedBy
        .map((p) => (MapEntry(findPersonById(members, p.person), p.amount)))
        .where((entry) => entry.key != null);
    return PayedByMany._(Map.fromEntries(entries));
  }

  void update(Flouze.Person person, int amount) {
    this.amounts[person] = amount;
  }

  @override
  List<Flouze.PayedBy> asPayedBy(int amount) =>
      amounts.keys.map((person) =>
      Flouze.PayedBy.create()
        ..person = person.uuid
        ..amount = amounts[person]
      ).toList();

  @override
  String validate(int amount) {
    final int total = amounts.isEmpty ? 0 : amounts.values.reduce((acc, v) => acc + (v ?? 0));

    if (amount != total) {
      return 'Sum of "payed by"s does not match total amount';
    }

    return null;
  }
}

abstract class AbstractPayedFor {
  String validate(int amount); // Returns null if no error, error message else
  Iterable<Flouze.Person> members();
  List<Flouze.PayedFor> asPayedFor(int amount);
}

class PayedSplitEven extends AbstractPayedFor {
  final Set<Flouze.Person> persons;

  PayedSplitEven._(this.persons);

  factory PayedSplitEven.fromPayedFor(List<Flouze.PayedFor> payedFor, List<Flouze.Person> members) {
    final who = payedFor.isEmpty ? members.toSet() : payedFor.map((p) => findPersonById(members, p.person)).toSet();
    return PayedSplitEven._(who);
  }

  @override
  String validate(int amount) {
    if (persons.isEmpty) {
      return 'Please select at least one payment recipient';
    }

    return null;
  }

  @override
  Iterable<Flouze.Person> members() => persons;

  List<Flouze.PayedFor> asPayedFor(int amount) {
    List<int> amounts = divideAmount(amount, persons.length);
    return IterableZip(<Iterable<dynamic>>[persons, amounts]).map((entry) =>
    Flouze.PayedFor.create()
      ..person = (entry[0] as Flouze.Person).uuid
      ..amount = (entry[1] as int)
    ).toList();
  }
}

class PayedForSplitCustom extends AbstractPayedFor {
  final Map<Flouze.Person, int> amounts;

  PayedForSplitCustom._(this.amounts);

  factory PayedForSplitCustom.fromPayedFor(List<Flouze.PayedFor> payedFor, Iterable<Flouze.Person> members) {
    final Map<Flouze.Person, int> amounts = Map.fromEntries(payedFor
        .map((p) => (MapEntry(findPersonById(members, p.person), p.amount)))
        .where((entry) => entry.key != null));

    return PayedForSplitCustom._(amounts);
  }

  @override
  Iterable<Flouze.Person> members() => amounts.entries.where((e) => e.value > 0).map((e) => e.key).toSet();

  @override
  List<Flouze.PayedFor> asPayedFor(int amount) =>
      amounts.keys.map((person) =>
      Flouze.PayedFor.create()
        ..person = person.uuid
        ..amount = amounts[person]
      ).toList();

  @override
  String validate(int amount) {
    final int total = amounts.isEmpty ? 0 : amounts.values.reduce((acc, v) => acc + (v ?? 0));

    if (amount != total) {
      return 'Sum of "payed by"s does not match total amount';
    }

    return null;
  }
}

class ValidatedValue<T> {
  final T value;
  final String error;

  ValidatedValue._(this.value, this.error);

  factory ValidatedValue.ok(T value) => ValidatedValue._(value, null);
  factory ValidatedValue.error(T value, String error) => ValidatedValue._(value, error);
}

class TransactionBloc {
  BehaviorSubject<TransactionState> _transactionController;
  final List<int> _replaces;
  final List<Flouze.Person> _members;

  TransactionBloc(Flouze.Transaction transaction, this._members)
      : _replaces = (transaction.uuid ?? [])
  {
    final label = transaction.label ?? '';
    final date = ((transaction.timestamp ?? 0) == 0) ? DateTime.now() : dateFromTimestamp(transaction.timestamp);
    final amount = transaction.amount ?? 0;
    final payedBySplit = (transaction.payedBy ?? []).where((p) => p.amount > 0).length > 1;
    final payedBy = payedBySplit ?
      PayedByMany.fromPayedBy(transaction.payedBy, _members)
        : PayedByOne.fromPayedBy(transaction.payedBy, _members);

    final payedForSplit = (transaction.payedFor ?? []).map((p) => p.amount).toSet().length > 1;
    final payedFor = payedForSplit ?
      PayedForSplitCustom.fromPayedFor(transaction.payedFor, _members)
        : PayedSplitEven.fromPayedFor(transaction.payedFor, _members);
    final canDelete = transaction.uuid?.isNotEmpty ?? false;

    final state = TransactionLoadedState(
      label,
      date,
      amount,
      payedBy,
      payedFor,
      canDelete,
    );

    _transactionController = BehaviorSubject.seeded(state);
  }

  Stream<TransactionState> get transaction => _transactionController.stream;

  void dispose() {
    _transactionController.close();
  }

  void _update(void Function(TransactionLoadedState state) transform) {
    final newState = TransactionLoadedState.clone(_transactionController.value);
    transform(newState);
    _transactionController.add(newState);
  }

  void setLabel(String label) {
    _update((s) => s..label = _validateLabel(label));
  }

  void setAmount(int amount) {
    _update((s) => s..amount = amount);
  }

  void setDate(DateTime dt) {
    _update((s) => s..date = dt);
  }

  void setPayedBySingle(Flouze.Person p) {
    _update((s) => s..payedBy = _validatePayedBy(PayedByOne._(p), s.amount));
  }

  void splitPayedBy() {
    _update((s) {
      final p = s.payedBy.value;
      s..payedBy = _validatePayedBy(PayedByMany.fromPayedBy(p.asPayedBy(s.amount), _members), s.amount);
    });
  }

  void setPayedBy(Flouze.Person p, int amount) {
    _update((s) {
      final payedBy = s.payedBy.value as PayedByMany;

      if (amount != null) {
        payedBy.amounts[p] = amount;
      } else {
        payedBy.amounts.remove(p);
      }

      s.payedBy = _validatePayedBy(payedBy, s.amount);
    });
  }

  void setPayedForEven(Set<Flouze.Person> members) {
    _update((s) => s..payedFor = _validatePayedFor(PayedSplitEven._(members), s.amount));
  }

  void splitPayedFor() {
    _update((s) {
      final p = s.payedFor.value;
      s.payedFor = _validatePayedFor(PayedForSplitCustom.fromPayedFor(p.asPayedFor(s.amount), p.members()), s.amount);
    });
  }

  void setPayedFor(Flouze.Person person, int amount) {
    _update((s) {
      final payedFor = s.payedFor.value as PayedForSplitCustom;

      if (amount != null) {
        payedFor.amounts[person] = amount;
      } else {
        payedFor.amounts.remove(person);
      }

      s.payedFor = _validatePayedFor(payedFor, s.amount);
    });
  }

  void deleteTransaction() {
    if (_transactionController.value is! TransactionLoadedState) {
      return;
    }

    assert(_replaces.isNotEmpty);

    final tx = Flouze.Transaction.create()
      ..uuid = UUID.generateUuid()
      ..deleted = true
      ..timestamp = timestampFromDate(DateTime.now())
      ..replaces = _replaces;

    _transactionController.add(TransactionSaveState(tx));
  }

  void saveTransaction() {
    if (_transactionController.value is! TransactionLoadedState) {
      return;
    }

    final state = (_transactionController.value as TransactionLoadedState);

    if (state.label.error != null || state.payedBy.error != null || state.payedFor.error != null) {
      return;
    }

    final tx = Flouze.Transaction.create()
      ..uuid = UUID.generateUuid()
      ..label = state.label.value
      ..amount = state.amount
      ..timestamp = timestampFromDate(state.date)
      ..payedBy.addAll(state.payedBy.value.asPayedBy(state.amount))
      ..payedFor.addAll(state.payedFor.value.asPayedFor(state.amount))
      ..replaces = _replaces;

    _transactionController.add(TransactionSaveState(tx));
  }
}

class TransactionState {}

ValidatedValue<String> _validateLabel(String label) =>
  label.isNotEmpty ? ValidatedValue.ok(label) : ValidatedValue.error(label, 'Description cannot be empty');

ValidatedValue<AbstractPayedBy> _validatePayedBy(AbstractPayedBy payedBy, int amount) =>
  ValidatedValue.error(payedBy, payedBy.validate(amount));

ValidatedValue<AbstractPayedFor> _validatePayedFor(AbstractPayedFor payedFor, int amount) =>
    ValidatedValue.error(payedFor, payedFor.validate(amount));

class TransactionLoadedState extends TransactionState {
  ValidatedValue<String> label;
  DateTime date;
  int amount;
  ValidatedValue<AbstractPayedBy> payedBy;
  ValidatedValue<AbstractPayedFor> payedFor;
  bool canDelete;

  TransactionLoadedState(String label, this.date, this.amount, AbstractPayedBy payedBy, AbstractPayedFor payedFor, this.canDelete):
        label = _validateLabel(label),
        payedBy = _validatePayedBy(payedBy, amount),
        payedFor = _validatePayedFor(payedFor, amount);

  factory TransactionLoadedState.clone(TransactionLoadedState other) =>
      TransactionLoadedState(other.label.value, other.date, other.amount, other.payedBy.value, other.payedFor.value, other.canDelete);
}

class TransactionSaveState extends TransactionState {
  final Flouze.Transaction transaction;
  TransactionSaveState(this.transaction);
}