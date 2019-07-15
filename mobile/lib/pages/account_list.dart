import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

import 'package:flouze/localization.dart';
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
    _notificationsSub = _bloc.accounts.listen((state) {
      if (state is AccountListSaveErrorState) {
        final prefix = FlouzeLocalizations.of(context).accountListPageErrorSaving;
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text('$prefix: ${state.message}'))
        );
      }
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
          Expanded(
            child: StreamBuilder<AccountListState>(
              stream: _bloc.accounts,
              initialData: AccountListLoadingState(),
              builder: (context, snapshot) {
                if (snapshot.data is AccountListLoadingState || snapshot.data is AccountListSaveErrorState) {
                  return _buildLoading();
                }

                if (snapshot.data is AccountListLoadedState) {
                  return _buildLoaded(snapshot.data);
                }

                if (snapshot.data is AccountListLoadErrorState) {
                  return _buildError(snapshot.data);
                }

                return null;
              }
            )
          )
        ]
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _saveAccount,
        tooltip: FlouzeLocalizations.of(context).accountListPageAddAccountButtonTooltip,
        child: new Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoading() => Center(child: CircularProgressIndicator(key: Key('account-list-loading')));

  Widget _buildLoaded(AccountListLoadedState state) {
    if (state.accounts.isEmpty) {
      return Center(child: Text(FlouzeLocalizations.of(context).accountListPageEmptyStateText));
    } else {
      return ListView(
        shrinkWrap: true,
        children: state.accounts.asMap().map((idx, account) =>
            MapEntry(
                idx,
                ListTile(
                    key: Key("account-$idx"),
                    leading: Icon(Icons.attach_money),
                    title: Text(account.label),
                    onTap: () {
                      _openAccount(account);
                    })
            )
        ).values.toList(),
      );
    }
  }

  Widget _buildError(AccountListLoadErrorState state) {
    final prefix = FlouzeLocalizations.of(context).accountListPageErrorLoading;
    return Text('$prefix: ${state.message}');
  }
}
