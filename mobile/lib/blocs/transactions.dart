import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

import 'package:flouze/utils/services.dart' as Services;
import 'package:flouze/utils/transactions.dart';

class TransactionsBloc {
  TransactionsBloc(this._account);

  final Flouze.Account _account;
  final _repository = Services.getRepository();
  final _transactionsController = BehaviorSubject<TransactionsState>();

  void loadTransactions() {
    _transactionsController.add(TransactionsLoadingState());
    _repository
        .then((repo) => repo.listTransactions(_account.uuid))
        .then((transactions) {
          _transactionsController.add(TransactionsLoadedState(flattenHistory(transactions)));
        })
        .catchError((e) => _transactionsController.add(TransactionsLoadErrorState(e.toString())));
  }

  void saveTransaction(Flouze.Transaction transaction) {
    transaction.parent = _account.latestTransaction;

    final List<int> previousLatestTransaction = _account.latestTransaction;
    final currentTransactions = (_transactionsController.value is TransactionsLoadedState) ?
      (_transactionsController.value as TransactionsLoadedState).transactions : [];
    _account.latestTransaction = transaction.uuid;

    _transactionsController.add(TransactionsLoadedState(flattenHistory([transaction, ...currentTransactions])));
    _repository
        .then((repo) { repo.addTransaction(_account.uuid, transaction); })
        .catchError((e) {
          _account.latestTransaction = previousLatestTransaction;
          _transactionsController.add(TransactionsSaveErrorState(e.toString()));
          loadTransactions();
        });
  }

  Stream<TransactionsState> get transactions => _transactionsController.stream;

  void dispose() {
    _transactionsController.close();
  }
}

class TransactionsState {}

class TransactionsLoadingState extends TransactionsState {}

class TransactionsLoadedState extends TransactionsState {
  TransactionsLoadedState(this.transactions);
  final List<Flouze.Transaction> transactions;
}

class TransactionsLoadErrorState extends TransactionsState {
  TransactionsLoadErrorState(this.error);
  final String error;
}

class TransactionsSaveErrorState extends TransactionsState {
  TransactionsSaveErrorState(this.error);
  final String error;
}
