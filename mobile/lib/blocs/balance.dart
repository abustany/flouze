import 'dart:async';

import 'package:rxdart/rxdart.dart';

import 'package:flouze/utils/services.dart' as Services;

class BalanceBloc {
  BalanceBloc(this._accountUuid);

  final List<int> _accountUuid;
  final _repository = Services.getRepository();
  final _balanceController = BehaviorSubject<BalanceState>();

  void loadBalance() {
    _balanceController.add(BalanceLoadingState());
    _repository
      .then((repo) => repo.getBalance(_accountUuid))
      .then((balance) {
        _balanceController.add(BalanceLoadedState(balance));
      })
      .catchError((e) {
        _balanceController.add(BalanceErrorState(e.toString()));
      });
  }

  Stream<BalanceState> get balance => _balanceController.stream;

  void dispose() {
    _balanceController.close();
  }
}

class BalanceState {}

class BalanceLoadingState extends BalanceState {}

class BalanceLoadedState extends BalanceState {
  BalanceLoadedState(this.balance);
  final Map<List<int>, int> balance;
}

class BalanceErrorState extends BalanceState {
  BalanceErrorState(this.error);
  final String error;
}
