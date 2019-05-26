import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/blocs/account_sync.dart';
import 'package:flouze/blocs/balance.dart';
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

class AccountPageState extends State<AccountPage> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AccountSyncBloc _accountSyncBloc;
  TransactionsBloc _transactionsBloc;
  BalanceBloc _balanceBloc;
  StreamSubscription _notificationsSub;
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
    _balanceBloc = BalanceBloc(account.uuid);
    _transactionsBloc = TransactionsBloc(account);
    _notificationsSub = _transactionsBloc.transactions.listen((state) {
      if (state is TransactionsSaveErrorState) {
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text(state.error))
        );
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

      if (state is AccountSyncNeedMeUuidState) {
        _pickMember().then((uuid) => _accountSyncBloc.setMeUuid(account, uuid));
      }

      if (state is AccountSyncSynchronizingState) {
        wasSynchronizing = true;
      }

      if (state is AccountSyncLoadedState && wasSynchronizing) {
        wasSynchronizing = false;

        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text("Synchronized successfully!"))
        );
      }
    });
    _balanceBloc.loadBalance();
    _transactionsBloc.loadTransactions();
    _tabController = TabController(length: _tabs.length, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _notificationsSub.cancel();
    _syncSubscription.cancel();
    _accountSyncBloc.dispose();
    _balanceBloc.dispose();
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

                    if (snapshot.data is TransactionsLoadErrorState) {
                      return _buildTransactionsError(snapshot.data);
                    }
                  }
                ),
                StreamBuilder<BalanceState>(
                  stream: _balanceBloc.balance,
                  initialData: BalanceLoadingState(),
                  builder: (context, snapshot) {
                    if (snapshot.data is BalanceLoadingState) {
                      return _buildReportsLoading();
                    }

                    if (snapshot.data is BalanceLoadedState) {
                      return _buildReportsLoaded(snapshot.data);
                    }

                    if (snapshot.data is BalanceErrorState) {
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
          icon: Icon(Icons.share),
          onPressed: (state is AccountSyncLoadedState) ?
              () { _accountSyncBloc.share(account); } : null,
      ),
    ];
  }

  Widget _buildReportsLoading() => Center(child: CircularProgressIndicator(key: Key('reports-loading')));

  Widget _buildReportsLoaded(BalanceLoadedState state) =>
      Reports(
          key: Key('reports'),
          members: account.members,
          balance: state.balance,
      );

  Widget _buildReportsError(BalanceErrorState state) => Center(child: Text(state.error));
}
