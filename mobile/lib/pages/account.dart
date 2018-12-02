import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:built_collection/built_collection.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/pages/add_transaction.dart';
import 'package:flouze/utils/account_config.dart';
import 'package:flouze/utils/account_config_store.dart' as AccountConfigStore;
import 'package:flouze/utils/rpc_client.dart';
import 'package:flouze/utils/transactions.dart';
import 'package:flouze/widgets/transaction_list.dart';
import 'package:flouze/widgets/sync_indicator.dart';
import 'package:flouze/widgets/reports.dart';
import 'package:flouze/utils/services.dart';

class AccountPage extends StatefulWidget {
  final Account account;

  AccountPage({Key key, @required this.account}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new AccountPageState(account: account);
}

class AccountPageState extends State<AccountPage> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final Account account;
  AccountConfig _accountConfig;
  BuiltList<Transaction> _transactions;
  Map<List<int>, int> _balance;
  bool _synchronizing = false;

  TabController _tabController;
  final List<Tab> _tabs = [
    Tab(key: Key('tab-transactions'),text: "Transactions"),
    Tab(key: Key('tab-reports'), text: "Reports"),
  ];

  AccountPageState({@required this.account});

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    loadAccountConfig(account.uuid);
    loadTransactions();
    loadBalance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadAccountConfig(List<int> accountUuid) async {
    AccountConfig accountConfig = await AccountConfigStore.loadAccountConfig(accountUuid);

    if (mounted) {
      setState(() {
        _accountConfig = accountConfig;
      });
    }
  }

  Future<void> loadTransactions() async {
    try {
      print('Listing transactions');
      final repository = await getRepository();
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
      final repository = await getRepository();
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
        if (!transaction.deleted) {
          list.insert(idx + 1, transaction);
        }

        if (idx >= 0) {
          list.removeAt(idx);
        }
      });
      account.latestTransaction = transaction.uuid;
    });

    try {
      final repository = await getRepository();
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

  Future<List<int>> _pickMember() async {
    final List<Person> members = List.from(account.members);
    members.sort((p1, p2) => p1.name.compareTo(p2.name));
    final List<Widget> options = members.map((person) =>
      SimpleDialogOption(
        child: Text(person.name),
        onPressed: () { Navigator.pop(context, person.uuid); },
      )).toList();

    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Who are you ?'),
        children: options,
      )
    );
  }

  Future<bool> _ensureMeUuid() async {
    if (_accountConfig.meUuid.isNotEmpty) {
      return true;
    }

    // Who are you ?
    var meUuid = await _pickMember();

    if (meUuid == null) {
      // User canceled
      return false;
    }

    var oldAccountConfig = _accountConfig;

    try {
      var newAccountConfig = _accountConfig.rebuild((b) =>
        b..meUuid.update((b) => b..clear()..addAll(meUuid))
      );

      setState(() {
        _accountConfig = newAccountConfig;
      });

      await AccountConfigStore.saveAccountConfig(account.uuid, newAccountConfig);

      return true;
    } on PlatformException catch (e) {
      print('Error while saving account configuration: ${e.message}');

      setState(() {
        _accountConfig = oldAccountConfig;
      });

      throw e;
    }
  }

  Future<void> _ensureRemoteAccountExists(JsonRpcClient client) async {
    if (_accountConfig.synchronized) {
      return;
    }

    var oldAccountConfig = _accountConfig;

    try {
      var newAccountConfig = _accountConfig.rebuild((b) => b..synchronized = true);

      setState(() {
        _accountConfig = newAccountConfig;
      });

      await client.createAccount(account);
      await AccountConfigStore.saveAccountConfig(account.uuid, newAccountConfig);
    } on PlatformException catch (e) {
      print('Error while creating remote account: ${e.message}');

      setState(() {
        _accountConfig = oldAccountConfig;
      });

      throw e;
    }
  }

  void _uploadAccount() async {
    assert(_accountConfig != null);

    if (_accountConfig.synchronized || _synchronizing) {
      return;
    }

    setState(() {
      _synchronizing = true;
    });

    try {
      var client = await getJsonRpcClient();

      if (!await _ensureMeUuid()) {
        // User cancelled the flow
        return;
      }

      final repository = await getRepository();
      await _ensureRemoteAccountExists(client);
      await Sync.sync(repository, client, account.uuid);
    } on PlatformException catch (e) {
      print('Synchronization failed: ${e.message}');
    } finally {
      setState(() {
        _synchronizing = false;
      });
    }
  }

  void _syncAccount() async {
    assert(_accountConfig.synchronized);

    setState(() {
      _synchronizing = true;
    });

    try {
      final repository = await getRepository();
      final client = await getJsonRpcClient();
      await Sync.sync(repository, client, account.uuid);

      if (mounted) {
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text('Synchronized successfully!'))
        );
      }
    } on PlatformException catch (e) {
      print('Synchronization failed: ${e.message}');

      if (mounted) {
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text('Synchronization failed: ${e.message}'))
        );
      }
    } finally {
      setState(() {
        _synchronizing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = [];

    if (_synchronizing) {
      actions.add(SyncIndicator());
    } else {
      if (!(_accountConfig?.synchronized ?? false)) {
        actions.add(
          IconButton(
            key: Key('action-upload-account'),
            icon: Icon(Icons.cloud_upload),
            onPressed: _uploadAccount,
          ),
        );
      } else {
        actions.add(
          IconButton(
            key: Key('action-sync-account'),
            icon: Icon(Icons.sync),
            onPressed: _syncAccount,
          ),
        );
      }
    }

    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(account.label),
        bottom: TabBar(
            controller: _tabController,
            tabs: _tabs
        ),
        actions: actions,
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
            Reports(
              key: Key('reports'),
              members: account.members,
              balance: _balance ?? {}
            )
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
