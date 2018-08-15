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

String amountToString(int amount) {
  double val = amount.toDouble();

  for (int i = 0; i < AppConfig.currencyDecimals; i++) {
    val /= 10;
  }

  return val.toStringAsFixed(AppConfig.currencyDecimals).replaceFirst('.', String.fromCharCode(AppConfig.decimalSeparator));
}
