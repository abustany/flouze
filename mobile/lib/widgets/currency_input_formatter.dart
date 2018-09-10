import 'package:charcode/ascii.dart';

import 'package:flutter/services.dart';

import 'package:flouze/utils/config.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return _selectionAwareTextManipulation(newValue, _filter);
  }

  static String _filter(String value) {
    final StringBuffer filtered = new StringBuffer();
    bool hasSeparator = false;
    int nDecimals = 0;

    for (int c in value.codeUnits) {
      final bool isSeparator = (c == AppConfig.decimalSeparator);

      if (nDecimals < AppConfig.currencyDecimals && c >= $0 && c <= $9 || (!hasSeparator && isSeparator)) {
        filtered.writeCharCode(c);

        if (hasSeparator && !isSeparator) {
          nDecimals++;
        }
      }

      hasSeparator = hasSeparator || isSeparator;
    }

    return filtered.toString();
  }

  // Copied from WhitelistingTextInputFormatter
  static TextEditingValue _selectionAwareTextManipulation(
      TextEditingValue value,
      String substringManipulation(String substring),
      ) {
    final int selectionStartIndex = value.selection.start;
    final int selectionEndIndex = value.selection.end;
    String manipulatedText;
    TextSelection manipulatedSelection;
    if (selectionStartIndex < 0 || selectionEndIndex < 0) {
      manipulatedText = substringManipulation(value.text);
    } else {
      final String beforeSelection = substringManipulation(
          value.text.substring(0, selectionStartIndex)
      );
      final String inSelection = substringManipulation(
          value.text.substring(selectionStartIndex, selectionEndIndex)
      );
      final String afterSelection = substringManipulation(
          value.text.substring(selectionEndIndex)
      );
      manipulatedText = beforeSelection + inSelection + afterSelection;
      if (value.selection.baseOffset > value.selection.extentOffset) {
        manipulatedSelection = value.selection.copyWith(
          baseOffset: beforeSelection.length + inSelection.length,
          extentOffset: beforeSelection.length,
        );
      } else {
        manipulatedSelection = value.selection.copyWith(
          baseOffset: beforeSelection.length,
          extentOffset: beforeSelection.length + inSelection.length,
        );
      }
    }
    return new TextEditingValue(
      text: manipulatedText,
      selection: manipulatedSelection ?? const TextSelection.collapsed(offset: -1),
      composing: manipulatedText == value.text
          ? value.composing
          : TextRange.empty,
    );
  }
}
