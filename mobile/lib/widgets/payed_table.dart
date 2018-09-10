import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/amounts.dart';
import 'package:flouze/widgets/amount_field.dart';

class PayedTable extends StatelessWidget {
  final List<Person> members;
  final Map<Person, int> amounts;
  final String keyPrefix;

  PayedTable({Key key, @required this.members, @required this.amounts, this.keyPrefix});

  static List<TableRow> payedRows(List<Person> members, Map<Person, int> amounts, String keyPrefix) =>
      members.map((person) {
        final int initialValue = amounts[person];

        return TableRow(
            children: <Widget>[
              Text(person.name),
              AmountField(
                key: Key(keyPrefix + person.uuid.toString()),
                initialValue: initialValue == 0 ? '' : amountToString(initialValue),
                onSaved: (value) => amounts[person] = value,
              )
            ]
        );
      }).toList();

  @override
  Widget build(BuildContext context) =>
    Table(
      key: key,
      children: payedRows(members, amounts, keyPrefix),
      columnWidths: {
        0: IntrinsicColumnWidth(flex: 1.0),
        1: IntrinsicColumnWidth(flex: 3.0),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    );
}
