import 'package:flouze/utils/config.dart';

int amountFromString(String text) {
  if (text == null || text.isEmpty) {
    return 0;
  }

  double numVal = double.parse(text.replaceFirst(String.fromCharCode(AppConfig.decimalSeparator), '.'));

  for (int i = 0; i < AppConfig.currencyDecimals; i++) {
    numVal *= 10;
  }

  return numVal.truncate();
}

String amountToString(int amount, {bool zeroIsEmpty = false}) {
  if (zeroIsEmpty && amount == 0) {
    return '';
  }

  double val = amount.toDouble();

  for (int i = 0; i < AppConfig.currencyDecimals; i++) {
    val /= 10;
  }

  return val.toStringAsFixed(AppConfig.currencyDecimals).replaceFirst('.', String.fromCharCode(AppConfig.decimalSeparator));
}

List<int> divideAmount(int amount, int nMembers) {
  if (nMembers == 0) {
    return List();
  }

  int slice = (amount / nMembers).floor();
  List<int> amounts = List.filled(nMembers, slice);

  int total = slice * nMembers;

  for (int i = 0; i < nMembers && total < amount; ++i) {
    amounts[i]++;
    total++;
  }

  amounts.shuffle();

  return amounts;
}
