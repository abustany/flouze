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
        .then((repo) => Future.wait([repo.listTransactions(_account.uuid), repo.getBalance(_account.uuid)]))
        .then((ctx) {
          final List<Flouze.Transaction> transactions = ctx[0];
          final Map<List<int>, int> balance = ctx[1];
          _transactionsController.add(TransactionsLoadedState(flattenHistory(transactions), balance));
        })
        .catchError((e) => _transactionsController.add(TransactionsLoadErrorState(e.toString())));
  }

  void saveTransaction(Flouze.Transaction transaction) {
    transaction.parent = _account.latestTransaction;

    if (_transactionsController.value is! TransactionsLoadedState) {
      return;
    }

    final TransactionsLoadedState state = (_transactionsController.value as TransactionsLoadedState);

    final List<int> previousLatestTransaction = _account.latestTransaction;
    _account.latestTransaction = transaction.uuid;

    _transactionsController.add(TransactionsLoadedState(flattenHistory([transaction, ...state.transactions]), state.balance));
    _repository
        .then((repo) { repo.addTransaction(_account.uuid, transaction); })
        .then((_) => loadTransactions()) // reload the transactions to upload the balance too
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
  TransactionsLoadedState(this.transactions, this.balance);
  final List<Flouze.Transaction> transactions;
  final Map<List<int>, int> balance;
}

class TransactionsErrorState extends TransactionsState {
  TransactionsErrorState(this.error);
  final String error;
}

class TransactionsLoadErrorState extends TransactionsErrorState {
  TransactionsLoadErrorState(String error) : super(error);
}

class TransactionsSaveErrorState extends TransactionsErrorState {
  TransactionsSaveErrorState(String error) : super(error);
}
