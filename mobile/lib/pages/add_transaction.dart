import 'package:flutter/material.dart';

import 'package:fixnum/fixnum.dart';

import 'package:intl/intl.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/uuid.dart';
import 'package:flouze/widgets/amount_field.dart';
import 'package:flouze/widgets/simple_payed_by.dart';
import 'package:flouze/widgets/payed_table.dart';

class AddTransactionPage extends StatefulWidget {
  final List<Person> members;

  AddTransactionPage({Key key, @required this.members}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new AddTransactionPageState(members);
}


abstract class AbstractPayedBy{}

class PayedByOne extends AbstractPayedBy {
  final Person person;
  PayedByOne(this.person);
}

class PayedByMany extends AbstractPayedBy {
  final Map<Person, int> amounts;
  PayedByMany(this.amounts);

  void update(Person person, int amount) {
    this.amounts[person] = amount;
  }
}

class AddTransactionPageState extends State<AddTransactionPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final DateFormat _dateFormat = DateFormat.yMMMd();
  final List<Person> _members;

  String _description = '';
  int _amount = 0;
  DateTime _date = DateTime.now();
  AbstractPayedBy _payedBy;
  Map<Person, int> _payedFor;

  AddTransactionPageState(this._members) {
    _payedFor = Map.fromEntries(_members.map((person) => MapEntry<Person, int>(person, 0)));
  }

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

  static PayedByMany convertToMany(AbstractPayedBy payed, List<Person> members, int amount) {
    if (payed is PayedByMany) {
      return payed;
    }

    var selectedPerson = (payed is PayedByOne ? payed.person : null);

    return PayedByMany(Map.fromEntries(members.map((person) => MapEntry(person, (person == selectedPerson) ? amount : 0))));
  }

  @override
  Widget build(BuildContext context) {
    Widget payedByWidget = (_payedBy == null || _payedBy is PayedByOne) ?
    Padding(
      padding: EdgeInsets.only(top: 12.0),
      child: SimplePayedBy(
          members: _members,
          onSelected: (Person p) {
            setState(() {
              _payedBy = PayedByOne(p);
            });
          },
          onSplit: () {
            setState(() {
              _payedBy = convertToMany(_payedBy, _members, amountFromString(_amountController.text));
            });
          },
          selected: ((_payedBy != null) ? (_payedBy as PayedByOne).person : false)))
      :
      PayedTable(members: _members, amounts: (_payedBy as PayedByMany).amounts, keyPrefix: 'payed-by)');

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
                                child: AmountField(onSaved: (value) => _amount = value, notNull: true, controller: _amountController),
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
                        payedByWidget,

                        Container(
                            margin: EdgeInsets.only(top: 12.0),
                            child: Text(
                              'Payed for',
                              style: Theme.of(context).textTheme.title,
                            )
                        ),
                        PayedTable(
                          members: _members,
                          amounts: _payedFor,
                          keyPrefix: 'payed-for-',
                        ),
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

    if (_payedBy == null) {
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text('Please select the person who paid'))
      );

      return;
    }

    if (_payedBy is PayedByMany) {
      final int payedByTotal = (_payedBy as PayedByMany).amounts.values.reduce((acc, v) => acc + v);

      if (_amount != payedByTotal) {
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text('Sum of "payed by"s does not match total amount'))
        );
        return;
      }
    }

    final int payedForTotal = _payedFor.values.reduce((acc, v) => acc + v);


    if (_amount != payedForTotal) {
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text('Sum of "payed for"s does not match total amount'))
      );
      return;
    }

    final List<PayedBy> payedBy = (_payedBy is PayedByOne) ?
      ([PayedBy.create()
        ..person = (_payedBy as PayedByOne).person.uuid
        ..amount = _amount])
      :
      _members.map((person) =>
          PayedBy.create()
            ..person = person.uuid
            ..amount = (_payedBy as PayedByMany).amounts[person]
      ).toList();

    final List<PayedFor> payedFor = _members.map((person) =>
    PayedFor.create()
      ..person = person.uuid
      ..amount = _payedFor[person]
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
