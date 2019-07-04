import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:flouze/utils/account_config.dart';
import 'package:flouze/utils/account_config_store.dart' as AccountConfigStore;
import 'package:flouze/utils/rpc_client.dart';
import 'package:flouze/utils/services.dart' as Services;
import 'package:flouze/utils/uuid.dart' as UUID;
import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

enum AccountCloneError {
  ImportPreparationError,
  ImportError,
}

class AccountCloneBloc {
  var _accountsController = BehaviorSubject<AccountCloneState>();

  Future<List<Flouze.Account>> _loadAccountList() =>
      Services.getRepository().then((repo) => repo.listAccounts());

  Future<Flouze.Account> _loadRemoteAccount(List<int> accountUuid) =>
      getJsonRpcClient()
          .then((client) => client.getAccountInfo(accountUuid));

  void prepareImport(List<int> remoteAccountUuid) {
    _accountsController.add(AccountCloneLoadingState());
    Future.wait([_loadAccountList(), _loadRemoteAccount(remoteAccountUuid)])
      .then((ctx) {
        final List<Flouze.Account> accounts = ctx[0];
        final Flouze.Account remoteAccount = ctx[1];

        if (accounts.indexWhere((a) => UUID.uuidEquals(a.uuid, remoteAccount.uuid)) != -1) {
          _accountsController.add(AccountCloneAlreadyExistsState(remoteAccount));
        } else {
          _accountsController.add(AccountCloneReadyState(remoteAccount));
        }
      })
      .catchError((e) =>
        _accountsController.add(AccountCloneErrorState(AccountCloneError.ImportPreparationError, e.toString())));
  }

  void import(Flouze.Account remoteAccount, List<int> meUuid) {
    final accountConfig = AccountConfig((b) {
      b.synchronized = true;

      if (meUuid != null && meUuid.isNotEmpty) {
        b.meUuid.addAll(meUuid);
      }
    });

    // We save the account config first, if that fails the account itself will
    // not be saved, and the user will try again. If account saving fails, we'll
    // leave behind a stray account config, not a huge deal.
    _accountsController.add(AccountCloneCloningState(remoteAccount));

    Future.wait(<Future<dynamic>>[
      AccountConfigStore.saveAccountConfig(remoteAccount.uuid, accountConfig),
      Services.getRepository(),
      getJsonRpcClient(),
    ])
    .then((ctx) {
      final Flouze.SledRepository repository = ctx[1];
      final Flouze.JsonRpcClient client = ctx[2];

      return Flouze.Sync.cloneRemote(repository, client, remoteAccount.uuid);
    })
    .then((_) => _accountsController.add(AccountCloneDoneState()))
    .catchError((e) => _accountsController.add(AccountCloneErrorState(AccountCloneError.ImportError, e.toString())));
  }

  Stream<AccountCloneState> get accounts => _accountsController.stream;

  void dispose() {
    _accountsController.close();
  }
}

class AccountCloneState {}

class AccountCloneLoadingState extends AccountCloneState {}

class AccountCloneAlreadyExistsState extends AccountCloneState {
  AccountCloneAlreadyExistsState(this.remoteAccount);
  final Flouze.Account remoteAccount;
}

class AccountCloneReadyState extends AccountCloneState {
  AccountCloneReadyState(this.remoteAccount);
  final Flouze.Account remoteAccount;
}

class AccountCloneCloningState extends AccountCloneState {
  AccountCloneCloningState(this.remoteAccount);
  final Flouze.Account remoteAccount;
}

class AccountCloneDoneState extends AccountCloneState {}

class AccountCloneErrorState extends AccountCloneState{
  AccountCloneErrorState(this.errorKind, this.message);
  final AccountCloneError errorKind;
  final String message;
}
