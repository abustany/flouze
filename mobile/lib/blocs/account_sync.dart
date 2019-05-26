import 'package:rxdart/rxdart.dart';

import 'package:share/share.dart';

import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

import 'package:flouze/utils/account_config.dart';
import 'package:flouze/utils/account_config_store.dart' as AccountConfigStore;
import 'package:flouze/utils/rpc_client.dart' as RpcClient;
import 'package:flouze/utils/services.dart';

class AccountSyncBloc {
  AccountSyncBloc();

  final _syncController = BehaviorSubject<AccountSyncState>();

  void loadAccountConfig(List<int> accountUuid) {
    _syncController.add(AccountSyncLoadingState());
    AccountConfigStore.loadAccountConfig(accountUuid)
        .then((accountConfig) {
          _syncController.add(AccountSyncLoadedState(accountConfig));
        })
        .catchError((e) {
          _syncController.add(AccountSyncErrorState(e.toString()));
        });
  }

  Future<AccountConfig> _upload(Flouze.Account account, AccountConfig config) {
    if (config.synchronized) {
      return Future.value(config);
    }

    final newAccountConfig = config.rebuild((b) => b..synchronized = true);

    return RpcClient.getJsonRpcClient()
        .then((client) => client.createAccount(account))
        .then((_) => AccountConfigStore.saveAccountConfig(account.uuid, newAccountConfig))
        .then((_) => newAccountConfig);
  }

  AccountConfig _getLoadedAccountConfig() =>
      (_syncController.value.runtimeType == AccountSyncLoadedState) ?
        (_syncController.value as AccountSyncLoadedState).accountConfig : null;

  void share(Flouze.Account account) {
    final AccountConfig config = _getLoadedAccountConfig();

    if (config == null) {
      // Silently ignore those requests
      return;
    }

    _syncController.add(AccountSyncSynchronizingState(config));

    _upload(account, config)
      .then((newConfig) {
        _syncController.add(AccountSyncLoadedState(newConfig));
        return shareAccountUri(account.uuid);
      })
      .then((uri) {
        Share.share('Get the Flouze app and share the account "${account.label}" with me!'
            '\n\n$uri');
      })
      .catchError((e) {
        _syncController.add(AccountSyncErrorState("Error while sharing account: ${e.toString()}"));
        _syncController.add(AccountSyncLoadedState(config));
      });
  }

  void setMeUuid(Flouze.Account account, List<int> uuid) {
    final AccountSyncState state = _syncController.value;

    if (state is! AccountSyncNeedMeUuidState || uuid == null || uuid.isEmpty) {
      return;
    }

    final AccountConfig config  = (state as AccountSyncNeedMeUuidState).accountConfig;
    final newAccountConfig = config.rebuild((b) => b..meUuid.update((b) => b..clear()..addAll(uuid)));

    AccountConfigStore.saveAccountConfig(account.uuid, newAccountConfig)
      .then((_) => _syncController.add(AccountSyncLoadedState(newAccountConfig)))
      .catchError((e) {
        _syncController.add(AccountSyncErrorState("Error while saving account config: ${e.toString()}"));
        _syncController.add(AccountSyncLoadedState(config));
      });
  }

  void synchronize(Flouze.Account account) {
    final AccountConfig config = _getLoadedAccountConfig();

    if (config == null) {
      // Silently ignore those requests
      return;
    }

    if (config.meUuid?.isEmpty ?? true) {
      _syncController.add(AccountSyncNeedMeUuidState(config));
      // The UI then has to call setMeUuid to return to a loaded state. We need
      // to skip the first state, which will be the current one.
      _syncController.skip(1).first.then((state) {
        synchronize(account);
      });
      return;
    }

    assert(config.synchronized && config.meUuid.isNotEmpty);

    _syncController.add(AccountSyncSynchronizingState(config));

    Future.wait([RpcClient.getJsonRpcClient(), getRepository()])
      .then((ctx) {
        final Flouze.JsonRpcClient client = ctx[0];
        final Flouze.SledRepository repository = ctx[1];

        return Flouze.Sync.sync(repository, client, account.uuid);
      })
      .then((_) => _syncController.add(AccountSyncLoadedState(config)))
      .catchError((e) {
        _syncController.add(AccountSyncErrorState(e.toString()));
        _syncController.add(AccountSyncLoadedState(config));
      });
  }

  Stream<AccountSyncState> get sync => _syncController.stream;

  void dispose() {
    _syncController.close();
  }
}

class AccountSyncState {}

// Loading the account configuration from disk
class AccountSyncLoadingState extends AccountSyncState {}

class AccountSyncLoadedState extends AccountSyncState {
  AccountSyncLoadedState(this.accountConfig);
  final AccountConfig accountConfig;
}

class AccountSyncSynchronizingState extends AccountSyncLoadedState {
  AccountSyncSynchronizingState(AccountConfig accountConfig) : super(accountConfig);
}

class AccountSyncNeedMeUuidState extends AccountSyncLoadedState {
  AccountSyncNeedMeUuidState(AccountConfig accountConfig) : super(accountConfig);
}

class AccountSyncErrorState extends AccountSyncState {
  AccountSyncErrorState(this.error);
  final String error;
}
