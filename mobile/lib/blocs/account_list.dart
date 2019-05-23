import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:flouze/utils/services.dart' as Services;
import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

class AccountListBloc {
  var _repository = Services.getRepository();
  var _accountsController = BehaviorSubject<AccountListState>();
  var _notificationController = StreamController<String>.broadcast();

  StreamSubscription<String> _accountEvents;

  void loadAccounts() {
    if (_accountEvents == null) {
      _accountEvents = Flouze.Events.stream().listen((event) {
        switch (event) {
          case Flouze.Events.ACCOUNT_LIST_CHANGED:
            loadAccounts();
            break;
          default:
            return;
        }
      });
    }

    _accountsController.add(AccountListLoadingState());
    _repository
        .then((repo) => repo.listAccounts())
        .then((accounts) {
          _accountsController.add(AccountListLoadedState(accounts));
        })
        .catchError((e) => _accountsController.add(AccountListErrorState("Error while loading accounts: ${e.toString()}")));
  }

  void saveAccount(Flouze.Account account) {
    final currentAccounts = (_accountsController.value is AccountListLoadedState) ?
      (_accountsController.value as AccountListLoadedState).accounts : [];
    _accountsController.add(AccountListLoadedState([...currentAccounts, account]));

    _repository
        .then((repo) => repo.addAccount(account))
        .catchError((e) {
          loadAccounts();
          _notificationController.add("Error while adding account: ${e.toString()}");
        });
  }

  Stream<AccountListState> get accounts => _accountsController.stream;
  Stream<String> get notifications => _notificationController.stream;

  void dispose() {
    _accountEvents.cancel();
    _accountsController.close();
    _notificationController.close();
  }
}

class AccountListState {}

class AccountListLoadingState extends AccountListState {}

class AccountListLoadedState extends AccountListState {
  AccountListLoadedState(this.accounts);
  final List<Flouze.Account> accounts;
}

class AccountListErrorState extends AccountListState{
  AccountListErrorState(this.error);
  final String error;
}
