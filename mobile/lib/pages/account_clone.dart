import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flouze/blocs/account_clone.dart';

class AccountClonePage extends StatefulWidget {
  final List<int> accountUuid;

  AccountClonePage({Key key, @required this.accountUuid}) : super(key: key);

  @override
  AccountClonePageState createState() => new AccountClonePageState(accountUuid);
}

class AccountClonePageState extends State<AccountClonePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<int> accountUuid;

  AccountCloneBloc _bloc;
  StreamSubscription<AccountCloneState> _accountEvents;

  AccountClonePageState(this.accountUuid);

  @override
  void initState() {
    _bloc = AccountCloneBloc();

    _accountEvents = _bloc.accounts.listen((state) {
      if (state is AccountCloneDoneState) {
        Navigator.of(context).pop();
      }
    });

    _bloc.prepareImport(accountUuid);

    super.initState();
  }

  @override
  void dispose() {
    _accountEvents.cancel();
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
            child: Padding(
              padding: new EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: StreamBuilder<AccountCloneState>(
                stream: _bloc.accounts,
                initialData: AccountCloneLoadingState(),
                builder: (context, snapshot) {
                  if (snapshot.data is AccountCloneLoadingState) {
                    return _buildLoading();
                  }

                  if (snapshot.data is AccountCloneAlreadyExistsState) {
                    return _buildAlreadyExists(snapshot.data);
                  }

                  if (snapshot.data is AccountCloneReadyState) {
                    return _buildReady(snapshot.data);
                  }

                  if (snapshot.data is AccountCloneCloningState) {
                    return _buildCloning(snapshot.data);
                  }

                  if (snapshot.data is AccountCloneErrorState) {
                    return _buildError(snapshot.data);
                  }

                  return Container();
                },
              )
            )
          )
        ]
      ),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      children: <Widget>[
        CircularProgressIndicator(key: Key('account-clone-loading')),
        Text('Retrieving remote account information...')
      ]
    )
  );

  Widget _buildAlreadyExists(AccountCloneAlreadyExistsState state) => Center(
    child: Text(
     'You already have the account "${state.remoteAccount.label}" on your device',
     key: Key('account-clone-already-exists')
   )
  );

  Widget _buildReady(AccountCloneReadyState state) => Column(
    children: <Widget>[
      Text('Ready to import account ${state.remoteAccount.label}', key: Key('account-clone-ready-label')),
      Center(
        child: RaisedButton(
          key: Key('account-clone-ready-import'),
          child: Text('Import'),
          // FIXME: Allow picking meUuid here
          onPressed: () { _bloc.import(state.remoteAccount, null); }
        )
      ),
    ],
  );

  Widget _buildCloning(AccountCloneCloningState state) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      CircularProgressIndicator(),
      Text('Importing account ${state.remoteAccount.label}...', key: Key('account-clone-importing-label'))
    ],
  );

  Widget _buildError(AccountCloneErrorState state) => Center(
    child: Text(state.error),
  );
}
