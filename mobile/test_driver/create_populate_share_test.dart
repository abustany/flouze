import 'package:flutter_driver/flutter_driver.dart';

import 'package:flouze_flutter/flouze.pb.dart' as Flouze;

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Create, populate and share an account', () {
    FlutterDriver driver;
    TransactionCheck txcheck;

    setUpAll(() async {
      await startFlouzeServer(deleteDataFirst: true);
      await enableReversePortForwarding();

      // Connects to the app
      driver = await FlutterDriver.connect();
      txcheck = TransactionCheck(driver);
    });

    tearDownAll(() async {
      await stopFlouzeServer();
      await disableReversePortForwarding();

      if (driver != null) {
        // Closes the connection
        driver.close();
      }
    });

    test('create an account', () async {
      await driver.waitForAbsent(find.byValueKey('account-list-loading'));
      await driver.tap(find.byTooltip('Add a new account'));
      await driver.tap(find.byValueKey('input-account-name'));
      await driver.enterText('Test account');
      await driver.tap(find.byValueKey('member-0-input-name'));
      await driver.enterText('John');
      await driver.tap(find.byValueKey('member-add'));
      await driver.tap(find.byValueKey('member-1-input-name'));
      await driver.enterText('Bob');
      await driver.tap(find.byValueKey('action-save-account'));
      await driver.waitFor(find.byValueKey('account-0'));
      await driver.waitFor(find.text('Test account'));
    });

    test('add a transaction - simple', () async {
      await driver.tap(find.byValueKey('account-0'));

      // Check that there are no transactions
      await txcheck.checkTransactionsMatch();
      await txcheck.checkBalance();

      // Create a new transaction
      await driver.tap(find.byTooltip('Add a new transaction'));
      await driver.tap(find.byValueKey('input-description'));
      await driver.enterText('Ice cream');
      await driver.tap(find.byValueKey('input-amount'));
      await driver.enterText('8');
      await driver.tap(find.byValueKey('payed-by-member-0')); // Payed by Bob
      await driver.tap(find.byValueKey('action-save-transaction'));

      txcheck.expectedTransactions.add(TxDescription('Ice cream', 8));
      txcheck.expectedBalance['John'] = -4.0;
      txcheck.expectedBalance['Bob'] = 4.0;

      await txcheck.checkTransactionsMatch();
      await txcheck.checkBalance();
    });

    test('add a transaction - payed by several people', () async {
      await driver.tap(find.byTooltip('Add a new transaction'));
      await driver.tap(find.byValueKey('input-description'));
      await driver.enterText('Waffles');
      await driver.tap(find.byValueKey('input-amount'));
      await driver.enterText('15');
      await driver.tap(find.byValueKey('payed-by-split'));
      await driver.tap(find.byValueKey('payed-by-member-0'));
      await driver.enterText('5');
      await driver.tap(find.byValueKey('payed-by-member-1'));
      await driver.enterText('10');
      await driver.tap(find.byValueKey('action-save-transaction'));

      txcheck.expectedTransactions.insert(0, TxDescription('Waffles', 15));
      txcheck.expectedBalance['John'] = -1.5;
      txcheck.expectedBalance['Bob'] = 1.5;

      await txcheck.checkTransactionsMatch();
      await txcheck.checkBalance();
    });

    test('add a transaction - payed for one person', () async {
      await driver.tap(find.byTooltip('Add a new transaction'));
      await driver.tap(find.byValueKey('input-description'));
      await driver.enterText('Kites');
      await driver.tap(find.byValueKey('input-amount'));
      await driver.enterText('35');
      await driver.tap(find.byValueKey('payed-by-member-1')); // Payed by John
      await driver.tap(find.byValueKey('payed-for-member-1')); // Uncheck John
      await driver.tap(find.byValueKey('action-save-transaction'));

      txcheck.expectedTransactions.insert(0, TxDescription('Kites', 35));
      txcheck.expectedBalance['John'] = 33.5;
      txcheck.expectedBalance['Bob'] = -33.5;

      await txcheck.checkTransactionsMatch();
      await txcheck.checkBalance();
    });

    test('add a transaction - payed by several people, split spending', () async {
      await driver.tap(find.byTooltip('Add a new transaction'));
      await driver.tap(find.byValueKey('input-description'));
      await driver.enterText('Burgers');
      await driver.tap(find.byValueKey('input-amount'));
      await driver.enterText('20');
      await driver.tap(find.byValueKey('payed-by-split'));
      await driver.tap(find.byValueKey('payed-by-member-0'));
      await driver.enterText('13');
      await driver.tap(find.byValueKey('payed-by-member-1'));
      await driver.enterText('7');
      await driver.tap(find.byValueKey('payed-for-split'));
      await driver.tap(find.byValueKey('payed-for-member-0'));
      await driver.enterText('7');
      await driver.tap(find.byValueKey('payed-for-member-1'));
      await driver.enterText('13');
      await driver.tap(find.byValueKey('action-save-transaction'));

      txcheck.expectedTransactions.insert(0, TxDescription('Burgers', 20));
      txcheck.expectedBalance['John'] = 27.5;
      txcheck.expectedBalance['Bob'] = -27.5;

      await txcheck.checkTransactionsMatch();
      await txcheck.checkBalance();
    });

    test('edit a transaction', () async {
      await driver.tap(find.byValueKey('transactions-3'));
      await driver.tap(find.byValueKey('input-amount'));
      await driver.enterText('6');
      await driver.tap(find.byValueKey('action-save-transaction'));

      txcheck.expectedTransactions[3].amount = 6;
      txcheck.expectedBalance['John'] = 28.5;
      txcheck.expectedBalance['Bob'] = -28.5;

      await txcheck.checkTransactionsMatch();
      await txcheck.checkBalance();
    });

    test('delete a transaction', () async {
      await driver.tap(find.byValueKey('transactions-3'));
      await driver.tap(find.byValueKey('action-delete-transaction'));
      await driver.tap(find.text('Delete'));

      txcheck.expectedTransactions.removeAt(3);
      txcheck.expectedBalance['John'] = 31.5;
      txcheck.expectedBalance['Bob'] = -31.5;

      await txcheck.checkTransactionsMatch();
      await txcheck.checkBalance();
    });

    test('share the account', () async {
      // The sync button shouldn't be shown if the account hasn't been uploaded
      // already.
      await driver.waitForAbsent(find.byValueKey('action-sync-account'));
      await driver.tap(find.byValueKey('action-share-account'));

      // Leave time for the share dialog to show up
      await Future.delayed(Duration(seconds: 5));

      // Cancel the share dialog
      await pressBackButton();

      // The sync button should now be visible
      await driver.waitFor(find.byValueKey('action-sync-account'));

      // The database we use for now (sled) doesn't support concurrent processes
      // accessing it, so stop the server first.
      await stopFlouzeServer();

      final accounts = await listServerAccounts();
      expect(accounts.length, 1);

      final Flouze.Account account = accounts.first;
      expect(account.members.map((p) => p.name).toList()..sort(), ['Bob', 'John']);

      final transactions = await listServerTransactions(account.label);
      expect(transactions.length, 6);

      // Return to the account list page, where we started
      await pressBackButton();
    });
  });

  group('Create and delete an account', () {
    FlutterDriver driver;

    setUpAll(() async {
      await enableReversePortForwarding();

      // Connects to the app
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        // Closes the connection
        driver.close();
      }
    });

    test('create an account', () async {
      await driver.waitForAbsent(find.byValueKey('account-list-loading'));
      await driver.tap(find.byTooltip('Add a new account'));
      await driver.tap(find.byValueKey('input-account-name'));
      await driver.enterText('Delete me');
      await driver.tap(find.byValueKey('member-0-input-name'));
      await driver.enterText('Eric');
      await driver.tap(find.byValueKey('member-add'));
      await driver.tap(find.byValueKey('member-1-input-name'));
      await driver.enterText('Mary');
      await driver.tap(find.byValueKey('action-save-account'));
      await driver.waitFor(find.byValueKey('account-1'));
      await driver.waitFor(find.text('Delete me'));
    });

    test('delete the account', () async {
      await driver.tap(find.text('Delete me'));
      await driver.tap(find.byValueKey('action-others'));
      await driver.tap(find.byValueKey('action-delete-account'));
      await driver.tap(find.text('Delete the account'));
      await driver.waitForAbsent(find.byValueKey('account-1'));
      await driver.waitForAbsent(find.text('Delete me'));
    });
  });
}
