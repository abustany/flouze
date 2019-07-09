import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:flouze_flutter/bindings.pb.dart';

import 'package:flouze_flutter/flouze.pb.dart';
export 'package:flouze_flutter/flouze.pb.dart';

const MethodChannel _channel = const MethodChannel('flouze_flutter');

const EventChannel _eventChannel = const EventChannel('flouze_flutter/events');
Stream<String> _eventStream;

class FlouzeFlutter {
  static Future<void> init() async {
    await _channel.invokeMethod('init');
  }
}

class _ClosablePointer {
  Future<int> _ptr;

  Future<int> Function() _factory;
  void Function(int) _close;

  _ClosablePointer(this._factory, this._close);

  Future<int> get ptr {
    if (_ptr == null) {
      _ptr = _factory();
    }

    return _ptr;
  }

  void close() {
    if (_ptr != null) {
      _ptr.then((ptr) => _close(ptr));
      _ptr = null;
    }
  }
}

class SledRepository {
  final _ClosablePointer _handle;

  SledRepository._(this._handle);

  static void Function(int) _closer() =>
      (ptr) => _channel.invokeMethod('SledRepository::close', {'ptr': ptr});

  static Future<int> Function() _temporaryFactory() =>
      () => _channel.invokeMethod('SledRepository::temporary');

  static Future<int> Function() _fromFileFactory(String path) =>
      () => _channel.invokeMethod('SledRepository::fromFile', {'path': path});

  factory SledRepository.temporary() =>
    SledRepository._(_ClosablePointer(_temporaryFactory(), _closer()));

  factory SledRepository.fromFile(String path) =>
    SledRepository._(_ClosablePointer(_fromFileFactory(path), _closer()));

  void close() {
    _handle.close();
  }

  Future<void> addAccount(Account account) async {
    final Map<String, dynamic> params = {
      'ptr': await _handle.ptr,
      'account': account.writeToBuffer(),
    };

    await _channel.invokeMethod('SledRepository::addAccount', params);
  }

  Future<void> deleteAccount(List<int> accountId) async {
    final Map<String, dynamic> params = {
      'ptr': await _handle.ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    await _channel.invokeMethod('SledRepository::deleteAccount', params);
  }

  Future<List<Account>> listAccounts() async {
    final Map<String, dynamic> params = {
      'ptr': await _handle.ptr,
    };

    return _channel
        .invokeMethod('SledRepository::listAccounts', params)
        .then((bytes) => AccountList.fromBuffer(bytes).accounts);
  }

  Future<List<Transaction>> listTransactions(List<int> accountId) async {
    final Map<String, dynamic> params = {
      'ptr': await _handle.ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    return _channel
        .invokeMethod('SledRepository::listTransactions', params)
        .then((bytes) => TransactionList.fromBuffer(bytes).transactions);
  }

  Future<void> addTransaction(
      List<int> accountId, Transaction transaction) async {
    final Map<String, dynamic> params = {
      'ptr': await _handle.ptr,
      'accountId': Uint8List.fromList(accountId),
      'transaction': transaction.writeToBuffer(),
    };

    await _channel.invokeMethod('SledRepository::addTransaction', params);
  }

  Future<Map<List<int>, int>> getBalance(List<int> accountId) async {
    final Map<String, dynamic> params = {
      'ptr': await _handle.ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    return _channel.invokeMethod('Repository::getBalance', params).then(
        (bytes) => Map.fromEntries(Balance.fromBuffer(bytes)
            .entries
            .map((entry) => MapEntry(entry.person, entry.balance.toInt()))));
  }
}

class JsonRpcClient {
  final _ClosablePointer _handle;

  JsonRpcClient._(this._handle);

  static Future<int> Function() _urlFactory(String url) =>
          () => _channel.invokeMethod('JsonRpcClient::create', {'url': url});

  static void Function(int) _closer() =>
          (ptr) => _channel.invokeMethod('JsonRpcClient::destroy', {'ptr': ptr});

  factory JsonRpcClient.create(String url) =>
      JsonRpcClient._(_ClosablePointer(_urlFactory(url), _closer()));

  Future<void> createAccount(Account account) async {
    final Map<String, dynamic> params = {
      'ptr': await _handle.ptr,
      'account': account.writeToBuffer(),
    };

    await _channel.invokeMethod('JsonRpcClient::createAccount', params);
  }

  Future<Account> getAccountInfo(List<int> accountId) async {
    final Map<String, dynamic> params = {
      'ptr': await _handle.ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    return _channel
        .invokeMethod('JsonRpcClient::getAccountInfo', params)
        .then((bytes) => Account.fromBuffer(bytes));
  }
}

class Sync {
  static Future<void> cloneRemote(SledRepository repository,
      JsonRpcClient client, List<int> accountId) async {
    final Map<String, dynamic> params = {
      'repoPtr': await repository._handle.ptr,
      'remotePtr': await client._handle.ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    await _channel.invokeMethod('Sync::cloneRemote', params);
  }

  static Future<void> sync(SledRepository repository, JsonRpcClient client,
      List<int> accountId) async {
    final Map<String, dynamic> params = {
      'repoPtr': await repository._handle.ptr,
      'remotePtr': await client._handle.ptr,
      'accountId': Uint8List.fromList(accountId),
    };

    await _channel.invokeMethod('Sync::sync', params);
  }
}

class Events {
  static const String ACCOUNT_LIST_CHANGED = 'account_list_changed';

  static Stream<String> stream() {
    if (_eventStream == null) {
      _eventStream = _eventChannel.receiveBroadcastStream().cast<String>();
    }

    return _eventStream;
  }
}
