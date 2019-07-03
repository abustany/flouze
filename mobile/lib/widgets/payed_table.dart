import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/keys.dart';
import 'package:flouze/widgets/amount_field.dart';

class PayedTable extends StatefulWidget {
  final List<Person> members;
  final Map<Person, int> amounts;
  final void Function(Person, int) onChanged;

  PayedTable({Key key, @required this.members, @required this.amounts, this.onChanged}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PayedTableState(key, members, amounts, onChanged);
  }

}

class PayedTableState extends State<PayedTable> {
  final Key key;
  final List<Person> members;
  final Map<Person, int> amounts;
  final void Function(Person, int) onChanged;

  Map<Person, TextEditingController> controllers;

  PayedTableState(this.key, this.members, this.amounts, this.onChanged);

  static Map<Person, TextEditingController> _makeControllers(List<Person> members, Map<Person, int> amounts, void Function(Person, int) onChanged) {
    return Map.fromEntries(members.map((p) {
      final initialValue = amounts[p] ?? 0;
      final controller = TextEditingController(text: amountToString(initialValue, zeroIsEmpty: true));

      controller.addListener(() {
        int amount;
        try {
          amount = amountFromString(controller.text);
        } catch (ignored) {
          amount = null;
        }

        if (onChanged != null) {
          onChanged(p, amount);
        }
      });

      return MapEntry(p, controller);
    }));

  }


  @override
  void initState() {
    controllers = _makeControllers(members, amounts, onChanged);

    super.initState();
  }

  @override
  dispose() {
    controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  List<TableRow> _payedRows(Key parentKey) {
    int i = -1;
    return controllers.entries.map((e) {
      i++;

      return TableRow(
          children: <Widget>[
            Text(e.key.name),
            AmountField(
              key: subkey(parentKey, '-member-$i'),
              controller: e.value,
            )
          ]
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) =>
    Table(
      key: key,
      children: _payedRows(key),
      columnWidths: {
        0: IntrinsicColumnWidth(flex: 1.0),
        1: IntrinsicColumnWidth(flex: 3.0),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    );
}
