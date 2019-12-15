import 'dart:async';

import 'package:flouze_flutter/bindings.pb.dart';
import 'package:rxdart/rxdart.dart';

import 'package:flouze_flutter/flouze_flutter.dart' as Flouze;

import 'package:flouze/utils/services.dart' as Services;
import 'package:flouze/utils/transactions.dart';

class TransactionsBloc {
  TransactionsBloc(this._account);

  final Flouze.Account _account;
  final _transactionsController = BehaviorSubject<TransactionsState>();

  void loadTransactions() {
    _transactionsController.add(TransactionsLoadingState());
    Services.getRepository()
        .then((repo) => Future.wait([repo.listTransactions(_account.uuid), repo.getBalance(_account.uuid)]))
        .then((ctx) async {
          final List<Flouze.Transaction> transactions = ctx[0];
          final Map<List<int>, int> balance = ctx[1];
          final transfers = await Flouze.Balance.getTransfers(balance);
          _transactionsController.add(TransactionsLoadedState(flattenHistory(transactions), balance, transfers));
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

    _transactionsController.add(TransactionsLoadedState(flattenHistory([transaction, ...state.transactions]), state.balance, state.transfers));
    Services.getRepository()
        .then((repo) { repo.addTransaction(_account.uuid, transaction).then((_) => repo.flush()); })
        .then((_) => loadTransactions()) // reload the transactions to upload the balance too
        .catchError((e) {
          _account.latestTransaction = previousLatestTransaction;
          _transactionsController.add(TransactionsSaveErrorState(e.toString()));
          loadTransactions();
        });
  }

  void deleteAccount() {
    Services.getRepository()
        .then((repo) { repo.deleteAccount(_account.uuid).then((_) => repo.flush()); })
        .then((_) { _transactionsController.add(TransactionsAccountDeletedState()); })
        .catchError((e) {
          _transactionsController.add(TransactionsErrorState(e.toString()));
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
  TransactionsLoadedState(this.transactions, this.balance, this.transfers)
    : totalAmount = transactions.isEmpty ? 0 : transactions.map((t) => t.amount).reduce((a, b) => a + b);
  final List<Flouze.Transaction> transactions;
  final Map<List<int>, int> balance;
  final List<Transfer> transfers;
  final int totalAmount;
}

class TransactionsAccountDeletedState extends TransactionsState {}

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
