import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/blocs/account_sync.dart';
import 'package:flouze/blocs/transactions.dart';
import 'package:flouze/pages/add_transaction.dart';
import 'package:flouze/widgets/transaction_list.dart';
import 'package:flouze/widgets/sync_indicator.dart';
import 'package:flouze/widgets/reports.dart';

class AccountPage extends StatefulWidget {
  final Account account;

  AccountPage({Key key, @required this.account}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new AccountPageState(account: account);
}

enum PopupMenuAction { delete_account }

class AccountPageState extends State<AccountPage> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AccountSyncBloc _accountSyncBloc;
  TransactionsBloc _transactionsBloc;
  StreamSubscription _transactionsSubscription;
  StreamSubscription _syncSubscription;

  final Account account;

  TabController _tabController;
  final List<Tab> _tabs = [
    Tab(key: Key('tab-transactions'),text: "Transactions"),
    Tab(key: Key('tab-reports'), text: "Reports"),
  ];

  AccountPageState({@required this.account});

  @override
  void initState() {
    _accountSyncBloc = AccountSyncBloc();
    _transactionsBloc = TransactionsBloc(account);
    _transactionsSubscription = _transactionsBloc.transactions.listen((state) {
      if (state is TransactionsSaveErrorState) {
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text(state.error))
        );
      }

      if (state is TransactionsAccountDeletedState) {
        Navigator.of(context).pop();
      }
    });
    _accountSyncBloc.loadAccountConfig(account.uuid);

    var wasSynchronizing = false;

    _syncSubscription = _accountSyncBloc.sync.listen((state) {
      if (state is AccountSyncErrorState) {
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text(state.error))
        );
      }

      if (state is AccountSyncLoadedState && wasSynchronizing) {
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text("Synchronized successfully!"))
        );

        _transactionsBloc.loadTransactions();
      }

      if (state is AccountSyncSynchronizingState) {
        wasSynchronizing = true;
      } else {
        wasSynchronizing = false;
      }
    });
    _transactionsBloc.loadTransactions();
    _tabController = TabController(length: _tabs.length, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _transactionsSubscription.cancel();
    _syncSubscription.cancel();
    _accountSyncBloc.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addTransaction() async {
    final Transaction transaction = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => new AddTransactionPage(members: account.members))
    );

    if (transaction != null) {
      _transactionsBloc.saveTransaction(transaction);
    }
  }

  void _editTransaction(Transaction transaction) async {
    final Transaction newTransaction = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => new AddTransactionPage(members: account.members, transaction: transaction,))
    );

    if (newTransaction != null) {
      _transactionsBloc.saveTransaction(newTransaction);
    }
  }

  void _deleteAccount() async {
    var doDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete the account?'),
          content: Text('All transactions will be lost. This action cannot be undone.'),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () { Navigator.of(context).pop(false); },
            ),
            FlatButton(
              child: Text('Delete the account', style: TextStyle(color: Color(0xFFCC0000))),
              onPressed: () { Navigator.of(context).pop(true); },
            )
          ],
        )
    ) ?? false;

    if (doDelete) {
      _transactionsBloc.deleteAccount();
    }
  }

  Future<List<int>> _pickMember() async {
    final List<Person> members = List.from(account.members);
    members.sort((p1, p2) => p1.name.compareTo(p2.name));

    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Who are you ?'),
        children: [
          for (var person in members)
            SimpleDialogOption(
              child: Text(person.name),
              onPressed: () { Navigator.pop(context, person.uuid); },
            )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) =>
    StreamBuilder<AccountSyncState>(
      stream: _accountSyncBloc.sync,
      initialData: AccountSyncLoadingState(),
      builder: (context, snapshot) =>
        Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(account.label),
            bottom: TabBar(
              controller: _tabController,
              tabs: _tabs,
            ),
            actions: _buildAppBarActions(snapshot.data),
          ),
          body: TabBarView(
              controller: _tabController,
              children: [
                StreamBuilder<TransactionsState>(
                  stream: _transactionsBloc.transactions,
                  initialData: TransactionsLoadingState(),
                  builder: (context, snapshot) {
                    if (snapshot.data is TransactionsLoadingState || snapshot.data is TransactionsSaveErrorState) {
                      return _buildTransactionsLoading();
                    }

                    if (snapshot.data is TransactionsLoadedState) {
                      return _buildTransactionsLoaded(snapshot.data);
                    }

                    if (snapshot.data is TransactionsAccountDeletedState) {
                      return _buildTransactionsDeleting();
                    }

                    if (snapshot.data is TransactionsLoadErrorState) {
                      return _buildTransactionsError(snapshot.data);
                    }
                  }
                ),
                StreamBuilder<TransactionsState>(
                  stream: _transactionsBloc.transactions,
                  initialData: TransactionsLoadingState(),
                  builder: (context, snapshot) {
                    if (snapshot.data is TransactionsLoadingState) {
                      return _buildReportsLoading();
                    }

                    if (snapshot.data is TransactionsLoadedState) {
                      return _buildReportsLoaded(snapshot.data);
                    }

                    if (snapshot.data is TransactionsErrorState) {
                      return _buildReportsError(snapshot.data);
                    }
                  }
                ),
              ]
          ),
          floatingActionButton: new FloatingActionButton(
            onPressed: _addTransaction,
            tooltip: 'Add a new transaction',
            child: new Icon(Icons.add),
          ),
        )
    );

  Widget _buildTransactionsLoading() => Center(child: CircularProgressIndicator(key: Key('transaction-list-loading')));

  Widget _buildTransactionsLoaded(TransactionsLoadedState state) {
    if (state.transactions.isEmpty) {
      return Center(child: Text("No transactions yet..."));
    } else {
      return TransactionList(
          key: Key('transactions'),
          transactions: state.transactions,
          members: account.members,
          onTap: _editTransaction
      );
    }
  }

  Widget _buildTransactionsDeleting() => Center(child: CircularProgressIndicator(key: Key('transaction-list-deleting')));

  Widget _buildTransactionsError(TransactionsLoadErrorState state) => Center(child: Text(state.error));

  List<Widget> _buildAppBarActions(AccountSyncState state) {
    final loaded = state is AccountSyncLoadedState;
    final synchronized =
        ((state is AccountSyncLoadedState) && state.accountConfig.synchronized) ||
            (state is AccountSyncSynchronizingState);

    if (!loaded) {
      return [];
    }

    return [
      if (synchronized)
        IconButton(
          key: Key('action-sync-account'),
          icon: (state is AccountSyncSynchronizingState) ? SyncIndicator() : Icon(Icons.sync),
          onPressed: (state is AccountSyncLoadedState) ?
              () { _accountSyncBloc.synchronize(account); } : null
        ),
      IconButton(
          key: Key('action-share-account'),
          icon: Icon(Icons.share),
          onPressed: (state is AccountSyncLoadedState) ?
              () { _accountSyncBloc.share(account); } : null,
      ),
      PopupMenuButton(
        key: Key('action-others'),
        onSelected: (PopupMenuAction action) {
          switch (action) {
            case PopupMenuAction.delete_account:
              _deleteAccount();
              break;
          }
        },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<PopupMenuAction>>[
            const PopupMenuItem<PopupMenuAction>(
              key: Key('action-delete-account'),
              value: PopupMenuAction.delete_account,
              child: Text('Delete account'),
            )
          ]
      )
    ];
  }

  Widget _buildReportsLoading() => Center(child: CircularProgressIndicator(key: Key('reports-loading')));

  Widget _buildReportsLoaded(TransactionsLoadedState state) =>
      Reports(
          key: Key('reports'),
          members: account.members,
          balance: state.balance,
      );

  Widget _buildReportsError(TransactionsErrorState state) => Center(child: Text(state.error));
}
