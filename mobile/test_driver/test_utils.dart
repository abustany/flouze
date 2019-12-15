import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

import 'package:test/test.dart';

import 'package:flouze_flutter/flouze.pb.dart' as Flouze;

import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/config.dart';

class TxDescription {
  String label;
  int amount;

  TxDescription(this.label, this.amount);
}

final flouzeCli = File("${Directory.current.path}/../target/debug/flouze-cli").absolute;
final flouzeDbName = 'user_scenarios_test.flouze';
final testServerPort = 3142;

Process _flouzeServer;

class TransactionCheck {
  final FlutterDriver driver;
  final List<TxDescription> expectedTransactions = [];
  final Map<String, double> expectedBalance = {'Bob': 0.0, 'John': 0.0};

  TransactionCheck(this.driver);

  Future<void> checkBalance() async {
    await driver.tap(find.byValueKey('tab-reports'));

    for (var i = 0; i < expectedBalance.length; i++) {
      final name = await driver.getText(find.byValueKey('reports-$i-name'));
      final expectedAmount = expectedBalance[name];
      expect(expectedAmount, isNotNull);

      final expectedAmountString = amountToString(amountFromString(expectedAmount.toString())) + ' ' + AppConfig.currencySymbol;
      expect(await driver.getText(find.byValueKey('reports-$i-balance')), equals(expectedAmountString),
          reason: 'Balance for $name does not match');
    }

    await driver.tap(find.byValueKey('tab-transactions'));
  }

  Future<void> checkTransactionsMatch() async {
    await Future.forEach(expectedTransactions.asMap().entries, (entry) async {
      final index = entry.key;
      final tx = entry.value;
      final expectedAmount = amountToString(amountFromString(tx.amount.toString())) + ' ' + AppConfig.currencySymbol;

      await driver.waitFor(find.byValueKey('transactions-$index'));
      expect(await driver.getText(find.byValueKey('transactions-$index-label')), equals(tx.label));
      expect(await driver.getText(find.byValueKey('transactions-$index-amount')), equals(expectedAmount));
    });

    // Check that we don't have more transactions than expected
    await driver.waitForAbsent(find.byValueKey('transactions-${expectedTransactions.length}'));

    // Check that the total matches
    final expectedTotal = expectedTransactions.isEmpty ? 0 : expectedTransactions.map((t) => t.amount).reduce((a, b) => a + b);
    final expectedTotalText = 'Total: ${amountToString(amountFromString(expectedTotal.toString()))} ${AppConfig.currencySymbol}';
    expect(await driver.getText(find.byValueKey('total-amount')), equals(expectedTotalText));
  }
}

Future<void> enableReversePortForwarding() {
  disableReversePortForwarding(); // just to be sure

  return Process.run('adb', ['reverse', 'tcp:$testServerPort', 'tcp:$testServerPort'])
      .then((result) {
    if (result.exitCode != 0) {
      throw 'Cannot set up reverse port forwarding: ${result.stderr}';
    }
  });
}

Future<void> disableReversePortForwarding() {
  return Process.run('adb', ['reverse', '--remove', 'tcp:$testServerPort']);
}

Future<void> sendCloneAccountIntent(String accountId) {
  return Process.run('adb', ['shell', 'am', 'start',
    '-a', 'android.intent.action.VIEW',
    '-c', 'android.intent.category.BROWSABLE',
    '-d', 'https://flouze.bustany.org/mobile/clone?accountId=$accountId']);
}

Future<void> startFlouzeServer({bool deleteDataFirst = false}) async {
  if (_flouzeServer != null) {
    await stopFlouzeServer();
  }

  if (!await flouzeCli.exists()) {
    throw "flouze-cli not found in ${flouzeCli.path}";
  }

  if (deleteDataFirst) {
    try {
      Directory(flouzeDbName).deleteSync(recursive: true);
    } catch (e) {
      // ignore
    }
  }

  _flouzeServer = await Process.start(flouzeCli.path, [flouzeDbName, 'serve', '127.0.0.1:$testServerPort']);
  _flouzeServer.stdout.transform(utf8.decoder).listen((s) => print("Server stdout: ${s.trimRight()}"));
  _flouzeServer.stderr.transform(utf8.decoder).listen((s) => print("Server stderr: ${s.trimRight()}"));

  print("Started test server on port $testServerPort");
}

Future<void> stopFlouzeServer() async {
  if (_flouzeServer == null) {
    return;
  }

  _flouzeServer.kill();
  _flouzeServer = null;
  print('Killed test server');
}

Future<void> pressBackButton() {
  return Process.run('adb', ['shell', 'input', 'keyevent', 'KEYCODE_BACK']);
}

Flouze.Person parsePerson(dynamic p) =>
    Flouze.Person.create()
      ..uuid = p['uuid'].cast<int>()
      ..name = p['name'];

Future<List<Flouze.Account>> listServerAccounts() {
  return Process.run(flouzeCli.path, [flouzeDbName, 'list-accounts', '--json'])
      .then((result) {
    if (result.exitCode != 0) {
      throw 'Flouze exited with code ${result.exitCode} (stderr: ${result.stderr as String})';
    }

    return (result.stdout as String).trim().split('\n')
        .map((j) {
      final decoded = json.decode(j);
      return Flouze.Account.create()
        ..uuid = decoded['uuid'].cast<int>()
        ..label = decoded['label']
        ..latestTransaction = decoded['latest_transaction'].cast<int>()
        ..latestSynchronizedTransaction = decoded['latest_synchronized_transaction'].cast<int>()
        ..members.addAll((decoded['members'] as List<dynamic>).map(parsePerson));
    }).toList();
  });
}

Future<List<Flouze.Transaction>> listServerTransactions(String accountName) {
  return Process.run(flouzeCli.path, [flouzeDbName, 'list-transactions', accountName, '--json'])
      .then((result) {
    if (result.exitCode != 0) {
      throw 'Flouze exited with code ${result.exitCode} (stderr: ${result.stderr as String})';
    }

    return (result.stdout as String).trim().split('\n')
        .map((j) {
      final decoded = json.decode(j);
      return Flouze.Transaction.create()
        ..uuid = decoded['uuid'].cast<int>()
        ..parent = decoded['parent'].cast<int>()
        ..amount = decoded['amount']
        ..label = decoded['label']
        ..deleted = decoded['deleted']
        ..replaces = decoded['replaces'].cast<int>()
        ..payedBy.addAll((decoded['payed_by'] as List<dynamic>).map((p) =>
        Flouze.PayedBy.create()
          ..person = p['person'].cast<int>()
          ..amount = p['amount']
        )
        )
        ..payedFor.addAll((decoded['payed_for'] as List<dynamic>).map((p) =>
        Flouze.PayedFor.create()
          ..person = p['person'].cast<int>()
          ..amount = p['amount']
        )
        );
    }).toList();
  });
}

// Workaround for https://github.com/flutter/flutter/issues/24703
Future<void> unpauseIsolates(FlutterDriver driver) async {
  (await driver.serviceClient.getVM()).isolates.forEach((isolateRef) async {
    final isolate = await isolateRef.load();
    if (isolate.isPaused) {
      isolate.resume();
    }
  });

  driver.serviceClient.onIsolateRunnable
      .asBroadcastStream()
      .listen((isolateRef) async {
    final isolate = await isolateRef.load();
    if (isolate.isPaused) {
      isolate.resume();
    }
  });
}
