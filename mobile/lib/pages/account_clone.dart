import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/account_config.dart';
import 'package:flouze/utils/account_config_store.dart' as AccountConfigStore;
import 'package:flouze/utils/services.dart';
import 'package:flouze/utils/rpc_client.dart';
import 'package:flouze/utils/uuid.dart';

class AccountClonePage extends StatefulWidget {
  final List<int> accountUuid;

  AccountClonePage({Key key, @required this.accountUuid}) : super(key: key);

  @override
  AccountClonePageState createState() => new AccountClonePageState(accountUuid);
}

class AccountClonePageState extends State<AccountClonePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<int> accountUuid;
  List<Account> _accounts;
  Account _remoteAccountInfo;
  bool _cloning = false;

  AccountClonePageState(this.accountUuid);

  Future<void> loadAccounts() async {
    try {
      print('Listing accounts');
      final SledRepository repository = await getRepository();
      List<Account> accounts = await repository.listAccounts();

      if (mounted) {
        setState(() {
          _accounts = accounts ?? [];
        });
      }
    } on PlatformException catch (e) {
      print('Error while listing accounts: ${e.message}');
    }
  }

  Future<void> loadRemoteAccountInfo() async {
    try {
      final client = await getJsonRpcClient();
      final remoteAccountInfo = await client.getAccountInfo(accountUuid);

      if (mounted) {
        setState(() {
          _remoteAccountInfo = remoteAccountInfo;
        });
      }
    } on PlatformException catch (e) {
      print('Error while retrieving remote account info: ${e.message}');
    }
  }

  @override
  void initState() {
    super.initState();
    loadAccounts();
    loadRemoteAccountInfo();
  }

  void _import() async {
    final navigator = Navigator.of(context);

    try {
      setState(() {
        _cloning = true;
      });

      final repository = await getRepository();
      final client = await getJsonRpcClient();
      await Sync.cloneRemote(repository, client, accountUuid);

      final accountConfig = AccountConfig((b) => b..synchronized = true);
      await AccountConfigStore.saveAccountConfig(accountUuid, accountConfig);

      if (mounted) {
        navigator.pop();
      }
    } on PlatformException catch (e) {
      print('Error while cloning account: ${e.message}');

      setState(() {
        _cloning = false;
      });
    }
  }

  Widget mainWidget() {
    if (_accounts == null || _remoteAccountInfo == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_accounts.indexWhere((a) => uuidEquals(a.uuid, accountUuid)) != -1) {
      return Text('This account is already imported');
    }

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text('Ready to import account: ${_remoteAccountInfo.label}'),
          ],
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _cloning ?
              CircularProgressIndicator() :
              RaisedButton(
                onPressed: _import,
                child: Text('Import')
              )
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('Flouze!'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: new EdgeInsets.all(16.0),
            child: Text(
              'Import a remote account',
              style: Theme.of(context).textTheme.title,
            ),
          ),
          Expanded(
            child: Padding(
              padding: new EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: mainWidget()
            )
          )
        ]
      ),
    );
  }
}
