import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:flouze/utils/account_config.dart';
import 'package:flouze/utils/account_config_store.dart' as AccountConfigStore;
import 'package:flouze/utils/services.dart' as Services;
import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

class AccountListBloc {
  var _accountsController = BehaviorSubject<AccountListState>();

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
    Services.getRepository()
        .then((repo) => repo.listAccounts())
        .then((accounts) {
          accounts.sort((a1, a2) => a1.label.toLowerCase().compareTo(a2.label.toLowerCase()));
          _accountsController.add(AccountListLoadedState(accounts));
        })
        .catchError((e) => _accountsController.add(AccountListLoadErrorState(e.toString())));
  }

  void saveAccount(Flouze.Account account) {
    final currentAccounts = (_accountsController.value is AccountListLoadedState) ?
      (_accountsController.value as AccountListLoadedState).accounts : [];
    _accountsController.add(AccountListLoadedState([...currentAccounts, account]));

    final accountConfig = AccountConfig((b) =>
        b
          ..meUuid.addAll(account.members.first.uuid)
          ..synchronized = false
    );

    // We save the account config first, if that fails the account itself will
    // not be saved, and the user will try again. If account saving fails, we'll
    // leave behind a stray account config, not a huge deal.
    AccountConfigStore.saveAccountConfig(account.uuid, accountConfig)
      .then((_) => Services.getRepository())
      .then((repo) => repo.addAccount(account))
      .catchError((e) {
        _accountsController.add(AccountListSaveErrorState(e.toString()));
        loadAccounts();
      });
  }

  Stream<AccountListState> get accounts => _accountsController.stream;

  void dispose() {
    _accountEvents.cancel();
    _accountsController.close();
  }
}

class AccountListState {}

class AccountListLoadingState extends AccountListState {}

class AccountListLoadedState extends AccountListState {
  AccountListLoadedState(this.accounts);
  final List<Flouze.Account> accounts;
}

class AccountListErrorState extends AccountListState {
  AccountListErrorState(this.message);
  final String message;
}

class AccountListLoadErrorState extends AccountListErrorState{
  AccountListLoadErrorState(String message) : super(message);
}

class AccountListSaveErrorState extends AccountListErrorState{
  AccountListSaveErrorState(String message) : super(message);
}
