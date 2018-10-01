import 'dart:async';

import 'package:flutter_driver/flutter_driver.dart';

import 'package:test/test.dart';

import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/config.dart';

class TxDescription {
  String label;
  int amount;

  TxDescription(this.label, this.amount);
}

void main() {
  group('user scenarios', () {
    FlutterDriver driver;

    setUpAll(() async {
      // Connects to the app
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        // Closes the connection
        driver.close();
      }
    });

    List<TxDescription> expectedTransactions = [];

    var checkTransactionsMatch = () async {
      await Future.forEach(expectedTransactions.asMap().entries, (entry) async {
        var index = entry.key;
        var tx = entry.value;
        var expectedAmount = amountToString(amountFromString(tx.amount.toString())) + ' ' + AppConfig.currencySymbol;

        await driver.waitFor(find.byValueKey('transactions-$index'));
        expect(await driver.getText(find.byValueKey('transactions-$index-label')), equals(tx.label));
        expect(await driver.getText(find.byValueKey('transactions-$index-amount')), equals(expectedAmount));
      });

      // Check that we don't have more transactions than expected
      await driver.waitForAbsent(find.byValueKey('transactions-${expectedTransactions.length}'));
    };

    test('create an account', () async {
      await driver.tap(find.byTooltip('Add a new account'));
      await driver.tap(find.byValueKey('input-account-name'));
      await driver.enterText('Test account');
      await driver.tap(find.byValueKey('member-0-input-name'));
      await driver.enterText('John');
      await driver.tap(find.byValueKey('member-1-input-name'));
      await driver.enterText('Bob');
      await driver.tap(find.byValueKey('action-save-account'));
      await driver.waitFor(find.byValueKey('account-0'));
      await driver.waitFor(find.text('Test account'));
    });

    test('add a transaction - simple', () async {
      await driver.tap(find.byValueKey('account-0'));

      // Check that there are no transactions
      await checkTransactionsMatch();

      // Create a new transaction
      await driver.tap(find.byTooltip('Add a new transaction'));
      await driver.tap(find.byValueKey('input-description'));
      await driver.enterText('Ice cream');
      await driver.tap(find.byValueKey('input-amount'));
      await driver.enterText('8');
      await driver.tap(find.byValueKey('payed-by-member-1'));
      await driver.tap(find.byValueKey('action-save-transaction'));

      expectedTransactions.add(TxDescription('Ice cream', 8));
      await checkTransactionsMatch();
    });

    test('add a transaction - payed by several people', () async {
      await driver.tap(find.byTooltip('Add a new transaction'));
      await driver.tap(find.byValueKey('input-description'));
      await driver.enterText('Waffles');
      await driver.tap(find.byValueKey('input-amount'));
      await driver.enterText('15');
      await driver.tap(find.byValueKey('payed-by-split'));
      await driver.tap(find.byValueKey('payed-by-member-0'));
      await driver.enterText('10');
      await driver.tap(find.byValueKey('payed-by-member-1'));
      await driver.enterText('5');
      await driver.tap(find.byValueKey('action-save-transaction'));

      expectedTransactions.insert(0, TxDescription('Waffles', 15));
      await checkTransactionsMatch();
    });

    test('add a transaction - payed by several people, split spending', () async {
      await driver.tap(find.byTooltip('Add a new transaction'));
      await driver.tap(find.byValueKey('input-description'));
      await driver.enterText('Burgers');
      await driver.tap(find.byValueKey('input-amount'));
      await driver.enterText('20');
      await driver.tap(find.byValueKey('payed-by-split'));
      await driver.tap(find.byValueKey('payed-by-member-0'));
      await driver.enterText('7');
      await driver.tap(find.byValueKey('payed-by-member-1'));
      await driver.enterText('13');
      await driver.tap(find.byValueKey('payed-for-split'));
      await driver.tap(find.byValueKey('payed-for-member-0'));
      await driver.enterText('13');
      await driver.tap(find.byValueKey('payed-for-member-1'));
      await driver.enterText('7');
      await driver.tap(find.byValueKey('action-save-transaction'));

      expectedTransactions.insert(0, TxDescription('Burgers', 20));
      await checkTransactionsMatch();
    });

    test('edit a transaction', () async {
      await driver.tap(find.byValueKey('transactions-2'));
      await driver.tap(find.byValueKey('input-amount'));
      await driver.enterText('6');
      await driver.tap(find.byValueKey('action-save-transaction'));

      expectedTransactions[2].amount = 6;
      await checkTransactionsMatch();
    });

    test('delete a transaction', () async {
      await driver.tap(find.byValueKey('transactions-2'));
      await driver.tap(find.byValueKey('action-delete-transaction'));
      await driver.tap(find.text('Delete'));

      expectedTransactions.removeAt(2);
      await checkTransactionsMatch();
    });
  });
}
