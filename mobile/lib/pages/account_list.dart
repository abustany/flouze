import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

import 'package:flouze/pages/add_account.dart';
import 'package:flouze/pages/account.dart';
import 'package:flouze/blocs/account_list.dart';

class AccountListPage extends StatefulWidget {
  AccountListPage({Key key}) : super(key: key);

  @override
  AccountListPageState createState() => new AccountListPageState();
}

class AccountListPageState extends State<AccountListPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AccountListBloc _bloc;
  StreamSubscription _notificationsSub;

  void _saveAccount() async {
    final Flouze.Account account = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => new AddAccountPage())
    );

    if (account != null) {
      _bloc.saveAccount(account);
      return;
    }
  }

  void _openAccount(Flouze.Account account) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => new AccountPage(account: account))
    );
  }

  @override
  void initState() {
    _bloc = AccountListBloc();
    _bloc.loadAccounts();
    _notificationsSub = _bloc.notifications.listen((notification) {
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text(notification))
      );
    });

    super.initState();
  }

  @override
  void dispose() {
    _notificationsSub.cancel();
    _bloc.dispose();
    super.dispose();
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
              'Accounts',
              style: Theme.of(context).textTheme.title,
            ),
          ),
          Expanded(
            child: StreamBuilder<AccountListState>(
              stream: _bloc.accounts,
              initialData: AccountListLoadingState(),
              builder: (context, snapshot) {
                if (snapshot.data is AccountListLoadingState) {
                  return _buildLoading();
                }

                if (snapshot.data is AccountListLoadedState) {
                  return _buildLoaded(snapshot.data);
                }

                if (snapshot.data is AccountListErrorState) {
                  return _buildError(snapshot.data);
                }
              }
            )
          )
        ]
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _saveAccount,
        tooltip: 'Add a new account',
        child: new Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoading() => Center(child: CircularProgressIndicator(key: Key('account-list-loading')));

  Widget _buildLoaded(AccountListLoadedState state) {
    if (state.accounts.isEmpty) {
      return Center(child: Text("Get started by creating a new account"));
    } else {
      return ListView(
        shrinkWrap: true,
        children: state.accounts.asMap().map((idx, account) =>
            MapEntry(
                idx,
                ListTile(
                    key: Key("account-$idx"),
                    title: Text(account.label),
                    onTap: () {
                      _openAccount(account);
                    })
            )
        ).values.toList(),
      );
    }
  }

  Widget _buildError(AccountListErrorState state) => Text(state.error);
}
