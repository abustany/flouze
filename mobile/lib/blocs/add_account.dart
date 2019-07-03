import 'package:rxdart/rxdart.dart';

import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

import 'package:flouze/utils/uuid.dart';

class AddAccountBloc {
  final _accountController = BehaviorSubject.seeded(AddAccountState.initial());
  var _memberIdx = 1;

  Stream<AddAccountState> get account => _accountController.stream;

  void setName(String name) {
    final state = _accountController.value;
    _accountController.add(AddAccountState(name, state.members));
  }

  void addMember() {
    final state = _accountController.value;
    final newMembers = Map.from(state.members).cast<int, String>();
    newMembers[_memberIdx++] = '';
    _accountController.add(AddAccountState(state.name, newMembers));
  }

  void removeMember(int idx) {
    final state = _accountController.value;
    final newMembers = Map.from(state.members).cast<int, String>();
    newMembers.remove(idx);
    _accountController.add(AddAccountState(state.name, newMembers));
  }

  void setMemberName(int idx, String name) {
    final state = _accountController.value;
    final newMembers = Map.from(state.members).cast<int, String>();
    newMembers[idx] = name;
    _accountController.add(AddAccountState(state.name, newMembers));
  }

  Flouze.Account makeAccount() {
    final state = _accountController.value;

    assert(state.isNameValid && state.members.isNotEmpty);

    return Flouze.Account.create()
      ..uuid = generateUuid()
      ..label = state.name
      ..members.addAll(state.members.values.map((name) =>
          Flouze.Person.create()
            ..uuid = generateUuid()
            ..name = name
      ));
  }

  void dispose() {
    _accountController.close();
  }
}

class AddAccountState {
  AddAccountState(this.name, this.members) {
    isNameValid = name.isNotEmpty;
  }

  factory AddAccountState.initial() =>
      AddAccountState('', {0: ''}); // First member is the account owner

  final String name;
  bool isNameValid;

  final Map<int, String> members;
}
