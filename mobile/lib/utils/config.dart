import 'package:charcode/ascii.dart';

class _AppConfig {
  final int currencyDecimals = 2;
  final String currencySymbol = '€';
  final int decimalSeparator = $comma;

  const _AppConfig();
}

const AppConfig = _AppConfig();
