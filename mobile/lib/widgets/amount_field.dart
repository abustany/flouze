import 'package:flutter/material.dart';

import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/config.dart';
import 'package:flouze/widgets/currency_input_formatter.dart';

class AmountField extends StatelessWidget {
  final String initialValue;
  final TextEditingController controller;
  final bool notNull;
  final FormFieldSetter<int> onSaved;

  AmountField({Key key, this.initialValue, this.controller, this.onSaved, this.notNull = false}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Row(
          children: <Widget>[
            Expanded(
                child: TextFormField(
                  initialValue: initialValue,
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                  inputFormatters: [
                    CurrencyInputFormatter(),
                  ],
                  controller: controller,
                  validator: (value) {
                    if (value.isEmpty) {
                      return notNull ? 'Amount cannot be empty' : null;
                    }

                    final double numVal = double.tryParse(value.replaceFirst(String.fromCharCode(AppConfig.decimalSeparator), '.'));

                    if (numVal == null) {
                      return 'Amount is not a valid number';
                    }

                    if (notNull && numVal == 0) {
                      return 'Amount should be greater than 0';
                    }
                  },
                  onSaved: (String value) {
                    if (onSaved != null) {
                      onSaved(amountFromString(value));
                    }
                  },
                )
            ),
            SizedBox(width: 12.0),
            Text(AppConfig.currencySymbol)
          ]);

}