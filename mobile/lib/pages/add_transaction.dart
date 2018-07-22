import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fixnum/fixnum.dart';

import 'package:intl/intl.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/uuid.dart';

class AddTransactionPage extends StatefulWidget {
  final List<Person> members;

  AddTransactionPage({Key key, @required this.members}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new AddTransactionPageState(members);
}

class AddTransactionPageState extends State<AddTransactionPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat.yMMMd();
  final List<Person> _members;

  String _description = '';
  int _amount = 0;
  DateTime _date = DateTime.now();
  Map<String, int> _payedBy;
  Map<String, int> _payedFor;

  AddTransactionPageState(this._members) {
    _payedBy = Map.fromEntries(_members.map((person) => MapEntry<String, int>(person.uuid.toString(), 0)));
    _payedFor = Map.fromEntries(_members.map((person) => MapEntry<String, int>(person.uuid.toString(), 0)));
  }

  static TextFormField amountField({Key key, String initialValue, FormFieldSetter<String> onSaved, bool notNull = false}) =>
      TextFormField(
        key: key,
        initialValue: initialValue,
        keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
        inputFormatters: <TextInputFormatter>[
          WhitelistingTextInputFormatter(RegExp("[0-9]")),
        ],
        validator: (value) {
          if (value.isEmpty) {
            return 'Amount cannot be empty';
          }

          if (notNull && int.parse(value) == 0) {
            return 'Amount should be greater than 0';
          }
        },
        onSaved: onSaved,
      );

  static List<TableRow> payedRows(List<Person> members, Map<String, int> amounts, String keyPrefix) =>
      members.map((person) {
      final int initialValue = amounts[person.uuid.toString()];

      return TableRow(
          children: <Widget>[
            Text(person.name),
            amountField(
              key: Key(keyPrefix + person.uuid.toString()),
              initialValue: initialValue == 0 ? '' : initialValue.toString(),
              onSaved: (value) => amounts[person.uuid.toString()] = int.parse(value),
            )
          ]
      );
    }).toList();

  static TableRow formRow({@required BuildContext context, @required String label, @required Widget child}) =>
      TableRow(
        children: <Widget>[
          Container(
            margin:EdgeInsets.only(right: 12.0),
            child: Text(
              label,
              style: Theme.of(context).textTheme.title,
            ),
          ),
          child,
        ],
      );

  @override
  Widget build(BuildContext context) {
    final List<TableRow> payedByRows = payedRows(_members, _payedBy, 'payed-by-');
    final List<TableRow> payedForRows = payedRows(_members, _payedFor, 'payed-for-');

    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text("Add a transaction"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _onSave,
            )
          ],
        ),
        body: new Padding(
            padding: new EdgeInsets.all(16.0),
            child: new ListView(
                children: <Widget>[new Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Table(
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            columnWidths: {
                              0: IntrinsicColumnWidth(flex: 1.0),
                              1: IntrinsicColumnWidth(flex: 3.0),
                            },
                            children: <TableRow>[
                              formRow(
                                  context: context,
                                  label: 'Description',
                                  child: TextFormField(
                                    autofocus: true,
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'Description cannot be empty';
                                      }
                                    },
                                    onSaved: (description) => _description = description,
                                  )
                              ),

                              formRow(
                                context: context,
                                label: 'Amount',
                                child: amountField(onSaved: (value) => _amount = int.parse(value), notNull: true),
                              ),

                              formRow(
                                  context: context,
                                  label: 'Date',
                                  child: InkWell(
                                    onTap: () => _pickDate(context),
                                    child: InputDecorator(
                                      decoration: InputDecoration(),
                                      child: Text(_dateFormat.format(_date))
                                    )
                                  )
                              ),
                            ]
                        ),

                        Container(
                            margin: EdgeInsets.only(top: 12.0),
                            child: Text(
                              'Payed by',
                              style: Theme.of(context).textTheme.title,
                            )
                        ),
                        Table(
                          children: payedByRows,
                          columnWidths: {
                            0: IntrinsicColumnWidth(flex: 1.0),
                            1: IntrinsicColumnWidth(flex: 3.0),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        ),

                        Container(
                            margin: EdgeInsets.only(top: 12.0),
                            child: Text(
                              'Payed for',
                              style: Theme.of(context).textTheme.title,
                            )
                        ),
                        Table(
                          children: payedForRows,
                          columnWidths: {
                            0: IntrinsicColumnWidth(flex: 1.0),
                            1: IntrinsicColumnWidth(flex: 3.0),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        )
                      ],
                    )
                )
            ])
        )
    );
  }

  void _onSave() {
    final FormState formState = _formKey.currentState;

    if (!formState.validate()) {
      return;
    }

    formState.save();

    final int payedByTotal = _payedBy.values.reduce((acc, v) => acc + v);
    final int payedForTotal = _payedFor.values.reduce((acc, v) => acc + v);

    if (_amount != payedByTotal) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(content: Text('Sum of "payed by"s does not match total amount'))
      );
      return;
    }

    if (_amount != payedForTotal) {
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text('Sum of "payed for"s does not match total amount'))
      );
      return;
    }

    final List<PayedBy> payedBy = _members.map((person) =>
        PayedBy.create()
          ..person = person.uuid
          ..amount = _payedBy[person.uuid.toString()]
    ).toList();

    final List<PayedFor> payedFor = _members.map((person) =>
    PayedFor.create()
      ..person = person.uuid
      ..amount = _payedFor[person.uuid.toString()]
    ).toList();

    final Transaction tx = Transaction.create()
      ..uuid = generateUuid()
      ..label = _description
      ..amount = _amount
      ..timestamp = Int64(_date.millisecondsSinceEpoch~/1000)
      ..payedBy.addAll(payedBy)
      ..payedFor.addAll(payedFor);

    Navigator.of(context).pop(tx);
  }

  void _pickDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(context: context, initialDate: _date, firstDate: new DateTime(1960), lastDate: new DateTime(2100));

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _date = picked;
    });
  }
}
