import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:flouze_flutter/bindings.pb.dart';

import 'package:flouze_flutter/flouze.pb.dart';
export 'package:flouze_flutter/flouze.pb.dart';

const MethodChannel _channel = const MethodChannel('flouze_flutter');

class FlouzeFlutter {
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> init() async {
    await _channel.invokeMethod('init');
  }
}

class SledRepository {
  int _ptr;

  SledRepository._(this._ptr);

  static Future<SledRepository> temporary() async {
    return SledRepository._(await _channel.invokeMethod('SledRepository::temporary'));
  }

  static Future<SledRepository> fromFile(String path) async {
    return SledRepository._(await _channel.invokeMethod('SledRepository::fromFile', path));
  }

  Future<void> close() async {
    await _channel.invokeMethod('SledRepository::close', _ptr);
  }

  Future<void> addAccount(Account account) async {
    final Map<String, dynamic> params = {
      'ptr': _ptr,
      'account': account.writeToBuffer(),
    };

    await _channel.invokeMethod('SledRepository::addAccount', params);
  }

  Future<List<Account>> listAccounts() async {
    return _channel.invokeMethod('SledRepository::listAccounts', _ptr).then((bytes) =>
      AccountList.fromBuffer(bytes).accounts
    );
  }

  Future<List<Transaction>> listTransactions(List<int> accountId) async {
    final Map<String, dynamic> params = {
      'ptr': _ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    return _channel.invokeMethod('SledRepository::listTransactions', params).then((bytes) =>
      TransactionList.fromBuffer(bytes).transactions
    );
  }

  Future<void> addTransaction(List<int> accountId, Transaction transaction) async {
    final Map<String, dynamic> params = {
      'ptr': _ptr,
      'accountId': Uint8List.fromList(accountId),
      'transaction': transaction.writeToBuffer(),
    };

    await _channel.invokeMethod('SledRepository::addTransaction', params);
  }

  Future<Map<List<int>, int>> getBalance(List<int> accountId) async {
    final Map<String, dynamic> params = {
      'ptr': _ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    return _channel.invokeMethod('Repository::getBalance', params).then((bytes) =>
      Map.fromEntries(Balance.fromBuffer(bytes).entries.map((entry) => MapEntry(entry.person, entry.balance.toInt())))
    );
  }
}

class JsonRpcClient {
  int _ptr;

  JsonRpcClient._(this._ptr);

  static Future<JsonRpcClient> create(String url) async {
    return JsonRpcClient._(await _channel.invokeMethod('JsonRpcClient::create', url));
  }

  Future<void> createAccount(Account account) async {
    final Map<String, dynamic> params = {
      'ptr': _ptr,
      'account': account.writeToBuffer(),
    };

    await _channel.invokeMethod('JsonRpcClient::createAccount', params);
  }
}

class Sync {
  static Future<void> sync(SledRepository repository, JsonRpcClient client, List<int> accountId) async {
    final Map<String, dynamic> params = {
      'repoPtr': repository._ptr,
      'remotePtr': client._ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    await _channel.invokeMethod('Sync::sync', params);
  }
}