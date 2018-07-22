import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

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

  SledRepository._(int ptr) {
    _ptr = ptr;
  }

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
    return _channel.invokeMethod('SledRepository::listAccounts', _ptr).then((accounts) =>
      (accounts as List<dynamic>).map((account) => Account.fromBuffer(account as List<int>)).toList()
    );
  }

  Future<List<Transaction>> listTransactions(List<int> accountId) async {
    final Map<String, dynamic> params = {
      'ptr': _ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    return _channel.invokeMethod('SledRepository::listTransactions', params).then((transactions) =>
      (transactions as List<dynamic>).map((transaction) => Transaction.fromBuffer(transaction as List<int>)).toList()
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
}