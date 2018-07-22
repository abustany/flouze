import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/pages/add_transaction.dart';

class TransactionListPage extends StatefulWidget {
  final SledRepository repository;
  final Account account;

  TransactionListPage({Key key, @required this.repository, @required this.account}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new TransactionListPageState(repository: repository, account: account);
}

class TransactionListPageState extends State<TransactionListPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final SledRepository repository;
  final Account account;
  List<Transaction> _transactions;

  TransactionListPageState({@required this.repository, @required this.account});

  Future<void> loadTransactions() async {
    try {
      print('Listing transactions');
      List<Transaction> transactions = await repository.listTransactions(account.uuid);

      if (mounted) {
        setState(() {
          _transactions = transactions ?? [];
        });
      }
    } on PlatformException catch (e) {
      print('Error while listing transactions: ${e.message}');
    }
  }

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> transactionWidgets = (_transactions ?? []).map((tx) =>
        ListTile(
          title: Row(
            children: <Widget>[
              Expanded(child: Text(tx.label)),
              Text(tx.amount.toString())
            ],
          ),
          onTap: () {
          },
        )
    ).toList();

    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(account.label),
      ),
      body: ListView(
        shrinkWrap: false,
        children: transactionWidgets,
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _addTransaction,
        tooltip: 'Add a new transaction',
        child: new Icon(Icons.add),
      ),
    );
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

    transaction.parent = account.latestTransaction;

    final List<int> previousLatestTransaction = account.latestTransaction;

    setState(() {
      _transactions.insert(0, transaction);
      account.latestTransaction = transaction.uuid;
    });

    try {
      await repository.addTransaction(account.uuid, transaction);
    } on PlatformException catch (e) {
      print('Error while saving transaction: ${e.message}');

      if (!mounted) {
        setState(() {
          _transactions.remove(transaction);
          account.latestTransaction = previousLatestTransaction;
        });

        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text('Error while saving transaction'))
        );
      }
    }
  }
}
