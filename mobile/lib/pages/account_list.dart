import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/pages/add_account.dart';
import 'package:flouze/pages/account.dart';

class AccountListPage extends StatefulWidget {
  final SledRepository repository;

  AccountListPage({Key key, @required this.repository}) : super(key: key);

  @override
  AccountListPageState createState() => new AccountListPageState(repository);
}

class AccountListPageState extends State<AccountListPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final SledRepository repository;
  List<Account> _accounts;

  AccountListPageState(this.repository);

  Future<void> loadAccounts() async {
    try {
      print('Listing accounts');
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

  void _addAccount() async {
    if (_accounts == null) {
      // Wait until accounts are loaded
      return;
    }

    final Account account = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => new AddAccountPage())
    );

    if (account == null || !mounted) {
      return;
    }

    setState(() {
      _accounts.add(account);
    });

    final ScaffoldState scaffoldState = _scaffoldKey.currentState;

    try {
      await repository.addAccount(account);

      scaffoldState.showSnackBar(
          SnackBar(content: Text('Account saved'))
      );
    } on PlatformException catch (e) {
      print('Error while saving account: ${e.message}');

      if (mounted) {
        setState(() {
          _accounts.remove(account);
        });

        scaffoldState.showSnackBar(
            SnackBar(content: Text('Error while saving account'))
        );
      }
    }
  }

  void _openAccount(Account account) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => new AccountPage(repository: repository, account: account))
    );
  }

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  @override
  void dispose() {
    super.dispose();

    repository?.close();
  }

  @override
  Widget build(BuildContext context) {
    int i = -1;
    final List<Widget> accountWidgets = (_accounts ?? []).map((account) {
      i++;
      return ListTile(
        key: Key("account-$i"),
        title: Text(account.label),
        onTap: () {
          _openAccount(account);
        },
      );
    }).toList();

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
              'Accounts',
              style: Theme.of(context).textTheme.title,
            ),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: accountWidgets,
            ),
          )
        ]
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _addAccount,
        tooltip: 'Add a new account',
        child: new Icon(Icons.add),
      ),
    );
  }
}
