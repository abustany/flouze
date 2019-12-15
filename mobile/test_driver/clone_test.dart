import 'package:flutter_driver/flutter_driver.dart';

import 'package:test/test.dart';

import 'package:flouze/utils/uuid.dart' as UUID;

import 'test_utils.dart';

void main() {
  group('clone an account', () {
    FlutterDriver driver;
    TransactionCheck txcheck;
    String accountId;
    void Function() unpauseIsolateCleanup;

    setUpAll(() async {
      final accounts = await listServerAccounts();
      expect(accounts.length, 1);

      accountId = UUID.toString(accounts.first.uuid);

      await startFlouzeServer();
      await enableReversePortForwarding();

      // Connects to the app
      driver = await FlutterDriver.connect();
      unpauseIsolateCleanup = await unpauseIsolates(driver);
      txcheck = TransactionCheck(driver);
    });

    test('clone', () async {
      sendCloneAccountIntent(accountId);

      await driver.waitFor(find.byValueKey('account-clone-ready-label'));
      await driver.tap(find.byValueKey('account-clone-ready-import'));

      await driver.waitForAbsent(find.byValueKey('account-clone-importing-label'));

      // Check that the account now appears in the list
      await driver.waitFor(find.byValueKey('account-0'));
      await driver.waitFor(find.text('Test account'));
    });

    test('cloned account contains correct data', () async {
      await driver.tap(find.byValueKey('account-0'));

      txcheck.expectedTransactions.add(TxDescription('Burgers', 20));
      txcheck.expectedTransactions.add(TxDescription('Kites', 35));
      txcheck.expectedTransactions.add(TxDescription('Waffles', 15));
      txcheck.expectedBalance['John'] = 31.5;
      txcheck.expectedBalance['Bob'] = -31.5;

      await txcheck.checkTransactionsMatch();
      await txcheck.checkBalance();

      await pressBackButton();
    });

    test('clone existing account', () async {
      sendCloneAccountIntent(accountId);

      await driver.waitFor(find.byValueKey('account-clone-already-exists'));
      await pressBackButton();
    });

    tearDownAll(() async {
      unpauseIsolateCleanup();
      await stopFlouzeServer();
      await disableReversePortForwarding();

      if (driver != null) {
        // Closes the connection
        driver.close();
      }
    });

    // This test is supposed to be started when the clone dialog is open
  });
}
