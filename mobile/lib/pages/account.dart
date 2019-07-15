import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/blocs/account_sync.dart';
import 'package:flouze/blocs/transactions.dart';
import 'package:flouze/localization.dart';
import 'package:flouze/pages/add_transaction.dart';
import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/config.dart';
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

  final List<Tab> _tabs = [null, null]; // Will be set in didChangeDependencies
  TabController _tabController;

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
            SnackBar(content: Text(_syncErrorLabel(state)))
        );
      }

      if (state is AccountSyncLoadedState && wasSynchronizing) {
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text(FlouzeLocalizations.of(context).accountPageSynchronizedSuccessfullySnack))
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
  void didChangeDependencies() {
    _tabs[0] = Tab(key: Key('tab-transactions'),text: FlouzeLocalizations.of(context).accountPageTransactionsTab);
    _tabs[1] = Tab(key: Key('tab-reports'), text: FlouzeLocalizations.of(context).accountPageBalanceTab);

    super.didChangeDependencies();
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
          title: Text(FlouzeLocalizations.of(context).accountPageDeleteDialogTitle),
          content: Text(FlouzeLocalizations.of(context).accountPageDeleteDialogBody),
          actions: <Widget>[
            FlatButton(
              child: Text(FlouzeLocalizations.of(context).confirmDialogCancelButton),
              onPressed: () { Navigator.of(context).pop(false); },
            ),
            FlatButton(
              child: Text(
                  FlouzeLocalizations.of(context).accountPageDeleteDialogDeleteButton,
                  style: TextStyle(color: Color(0xFFCC0000))
              ),
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

                    return null;
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

                    return null;
                  }
                ),
              ]
          ),
          floatingActionButton: new FloatingActionButton(
            onPressed: _addTransaction,
            tooltip: FlouzeLocalizations.of(context).accountPageAddTransactionButtonTooltip,
            child: new Icon(Icons.add),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: kElevationToShadow[6],
            ),
            height: 48,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  StreamBuilder<TransactionsState>(
                    stream: _transactionsBloc.transactions,
                    initialData: TransactionsLoadingState(),
                    builder: (context, snapshot) {
                      final totalAmount = (snapshot.data is TransactionsLoadedState) ?
                        (snapshot.data as TransactionsLoadedState).totalAmount : 0;

                      return Text(
                        FlouzeLocalizations.of(context).accountPageTotalAmount(amountToString(totalAmount), AppConfig.currencySymbol),
                        key: Key('total-amount'),
                        style: Theme.of(context).accentTextTheme.body2,
                      );
                    }
                  )
                ],
              ),
            ),
          )
        )
    );

  Widget _buildTransactionsLoading() => Center(child: CircularProgressIndicator(key: Key('transaction-list-loading')));

  Widget _buildTransactionsLoaded(TransactionsLoadedState state) {
    if (state.transactions.isEmpty) {
      return Center(child: Text(FlouzeLocalizations.of(context).accountPageEmptyStateText));
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
          tooltip: FlouzeLocalizations.of(context).accountPageSynchronizeButtonTooltip,
          icon: (state is AccountSyncSynchronizingState) ? SyncIndicator() : Icon(Icons.sync),
          onPressed: (state is AccountSyncLoadedState) ?
              () { _accountSyncBloc.synchronize(account); } : null
        ),
      IconButton(
          key: Key('action-share-account'),
        tooltip: FlouzeLocalizations.of(context).accountPageShareButtonTooltip,
          icon: Icon(Icons.share),
          onPressed: (state is AccountSyncLoadedState) ? () { _accountSyncBloc.share(account, _shareMessage); } : null,
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
            PopupMenuItem<PopupMenuAction>(
              key: Key('action-delete-account'),
              value: PopupMenuAction.delete_account,
              child: Text(FlouzeLocalizations.of(context).accountPageDeleteActionLabel),
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

  String _syncErrorLabel(AccountSyncErrorState state) {
    String prefix;

    switch (state.errorKind) {
      case AccountSyncError.LoadAccountConfigError:
        prefix = FlouzeLocalizations.of(context).accountPageErrorLoadingAccountConfig;
        break;
      case AccountSyncError.SaveAccountConfigError:
        prefix = FlouzeLocalizations.of(context).accountPageErrorSavingAccountConfig;
        break;
      case AccountSyncError.ShareError:
        prefix = FlouzeLocalizations.of(context).accountPageErrorSharing;
        break;
      case AccountSyncError.SynchronizationError:
        prefix = FlouzeLocalizations.of(context).accountPageErrorSynchronizing;
        break;
    }

    return '$prefix: ${state.message}';
  }

  String _shareMessage(String uri) => 'Get the Flouze app and share the account "${account.label}" with me!\n\n$uri';
}
