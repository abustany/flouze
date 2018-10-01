import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:built_collection/built_collection.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/pages/add_transaction.dart';
import 'package:flouze/utils/transactions.dart';
import 'package:flouze/widgets/transaction_list.dart';
import 'package:flouze/widgets/reports.dart';

class AccountPage extends StatefulWidget {
  final SledRepository repository;
  final Account account;

  AccountPage({Key key, @required this.repository, @required this.account}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new AccountPageState(repository: repository, account: account);
}

class AccountPageState extends State<AccountPage> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final SledRepository repository;
  final Account account;
  BuiltList<Transaction> _transactions;
  Map<List<int>, int> _balance;

  TabController _tabController;
  final List<Tab> _tabs = [
    Tab(text: "Transactions"),
    Tab(text: "Reports"),
  ];

  AccountPageState({@required this.repository, @required this.account});

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    loadTransactions();
    loadBalance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadTransactions() async {
    try {
      print('Listing transactions');
      List<Transaction> transactions = await repository.listTransactions(account.uuid);

      if (mounted) {
        setState(() {
          _transactions = BuiltList(flattenHistory(transactions) ?? []);
        });
      }
    } on PlatformException catch (e) {
      print('Error while listing transactions: ${e.message}');
    }
  }

  Future<void> loadBalance() async {
    try {
      Map<List<int>, int> balance = await repository.getBalance(account.uuid);

      if (mounted) {
        setState(() {
          _balance = balance ?? {};
        });
      }
    } on PlatformException catch (e) {
      print('Error while retrieving balance: ${e.message}');
    }
  }

  void _addTransaction() async {
    if (_transactions == null) {
      // Wait until transactions are loaded
      return;
    }

    final Transaction transaction = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => new AddTransactionPage(members: account.members))
    );

    if (transaction == null || !mounted) {
      return;
    }

    _appendTransaction(transaction);
  }

  void _editTransaction(Transaction transaction) async {
    final Transaction newTransaction = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => new AddTransactionPage(members: account.members, transaction: transaction,))
    );

    if (newTransaction == null || !mounted) {
      return;
    }

    _appendTransaction(newTransaction);
  }

  void _appendTransaction(Transaction transaction) async {
    final BuiltList<Transaction> previousTransactions = _transactions;
    final List<int> previousLatestTransaction = account.latestTransaction;

    transaction.parent = account.latestTransaction;

    setState(() {
      final int idx = transaction.replaces.isNotEmpty ? _transactions.indexWhere((tx) => transactionHasId(tx, transaction.replaces)) : -1;
      _transactions = _transactions.rebuild((list) {
        list.insert(idx+1, transaction);

        if (idx > 0) {
          list.removeAt(idx);
        }
      });
      account.latestTransaction = transaction.uuid;
    });

    try {
      await repository.addTransaction(account.uuid, transaction);
    } on PlatformException catch (e) {
      print('Error while saving transaction: ${e.message}');

      if (!mounted) {
        setState(() {
          _transactions = previousTransactions;
          account.latestTransaction = previousLatestTransaction;
        });

        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text('Error while saving transaction'))
        );
      }
    }

    loadBalance();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(account.label),
        bottom: TabBar(
            controller: _tabController,
            tabs: _tabs
        ),
      ),
      body: TabBarView(
          controller: _tabController,
          children: [
            TransactionList(
              key: Key('transactions'),
              transactions: _transactions,
              members: account.members,
              onTap: _editTransaction
            ),
            Reports(members: account.members, balance: _balance ?? {})
          ]
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _addTransaction,
        tooltip: 'Add a new transaction',
        child: new Icon(Icons.add),
      ),
    );
  }
}
