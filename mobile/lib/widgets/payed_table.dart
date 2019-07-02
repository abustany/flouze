import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/keys.dart';
import 'package:flouze/widgets/amount_field.dart';

class PayedTable extends StatelessWidget {
  final List<Person> members;
  final Map<Person, int> amounts;

  PayedTable({Key key, @required this.members, @required this.amounts}) : super(key: key);

  static List<TableRow> payedRows(Key parentKey, List<Person> members, Map<Person, int> amounts) {
    int i = -1;
    return members.map((person) {
      final int initialValue = amounts[person] ?? 0;
      i++;

      return TableRow(
          children: <Widget>[
            Text(person.name),
            AmountField(
              key: subkey(parentKey, '-member-$i'),
              initialValue: amountToString(initialValue, zeroIsEmpty: true),
              onSaved: (value) => amounts[person] = value,
            )
          ]
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) =>
    Table(
      key: key,
      children: payedRows(key, members, amounts),
      columnWidths: {
        0: IntrinsicColumnWidth(flex: 1.0),
        1: IntrinsicColumnWidth(flex: 3.0),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    );
}
