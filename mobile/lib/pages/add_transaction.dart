import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';

import 'package:intl/intl.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/uuid.dart';
import 'package:flouze/widgets/amount_field.dart';
import 'package:flouze/widgets/simple_payed_by.dart';
import 'package:flouze/widgets/simple_payed_for.dart';
import 'package:flouze/widgets/payed_table.dart';

class AddTransactionPage extends StatefulWidget {
  final List<Person> members;

  AddTransactionPage({Key key, @required this.members}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new AddTransactionPageState(members);
}

abstract class AbstractPayedBy{
  String validate(int amount);
  List<PayedBy> asPayedBy(int amount);
}

class PayedByOne extends AbstractPayedBy {
  final Person person;
  PayedByOne(this.person);

  @override
  List<PayedBy> asPayedBy(int amount) =>
    [PayedBy.create()
        ..person = person.uuid
        ..amount = amount];

  @override
  String validate(int amount) {
    if (person == null) {
      return 'Please select the person who paid';
    }

    return null;
  }
}

class PayedByMany extends AbstractPayedBy {
  final Map<Person, int> amounts;
  PayedByMany(this.amounts);

  void update(Person person, int amount) {
    this.amounts[person] = amount;
  }

  @override
  List<PayedBy> asPayedBy(int amount) =>
    amounts.keys.map((person) =>
          PayedBy.create()
            ..person = person.uuid
            ..amount = amounts[person]
      ).toList();

  @override
  String validate(int amount) {
    final int total = amounts.values.reduce((acc, v) => acc + v);

    if (amount != total) {
      return 'Sum of "payed by"s does not match total amount';
    }

    return null;
  }
}

abstract class AbstractPayedFor {
  String validate(int amount); // Returns null if no error, error message else
  List<PayedFor> asPayedFor(int amount);
}

class PayedForSimple extends AbstractPayedFor {
  final Set<Person> persons;

  PayedForSimple(this.persons);

  String validate(int amount) {
    if (persons.isEmpty) {
      return 'Please select at least one payment recipient';
    }

    return null;
  }

  List<PayedFor> asPayedFor(int amount) {
    List<int> amounts = divideAmount(amount, persons.length);
    return IterableZip(<Iterable<dynamic>>[persons, amounts]).map((entry) =>
        PayedFor.create()
          ..person = (entry[0] as Person).uuid
          ..amount = (entry[1] as int)
    ).toList();
  }
}

class PayedForAdvanced extends AbstractPayedFor {
  final Map<Person, int> amounts;

  PayedForAdvanced(this.amounts);

  @override
  List<PayedFor> asPayedFor(int amount) =>
    amounts.keys.map((person) =>
      PayedFor.create()
        ..person = person.uuid
        ..amount = amounts[person]
    ).toList();

  @override
  String validate(int amount) {
    final int total = amounts.values.reduce((acc, v) => acc + v);

    if (amount != total) {
      return 'Sum of "payed by"s does not match total amount';
    }

    return null;
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
  AbstractPayedFor _payedFor;

  AddTransactionPageState(this._members) {
    _payedBy = PayedByOne(null);
    _payedFor = PayedForSimple(_members.toSet());
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

  static PayedByMany payedByOneToMany(PayedByOne payed, List<Person> members, int amount) {
    var selectedPerson = payed.person;

    return PayedByMany(Map.fromEntries(members.map((person) => MapEntry(person, (person == selectedPerson) ? amount : 0))));
  }

  static PayedForAdvanced payedForSimpleToAdvanced(PayedForSimple payed, List<Person> members, int amount) {
    Set<Person> persons = payed.persons;
    List<int> splitAmounts = divideAmount(amount, persons.length);
    final Map<Person, int> amounts = Map.fromEntries(members.map((person) => MapEntry(person, 0)));
    IterableZip(<Iterable<dynamic>>[persons, splitAmounts]).forEach((entry) =>
      amounts[entry[0] as Person] = (entry[1] as int)
    );
    return PayedForAdvanced(amounts);
  }

  @override
  Widget build(BuildContext context) {
    final Widget payedByWidget = (_payedBy == null || _payedBy is PayedByOne) ?
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
              _payedBy = payedByOneToMany(_payedBy, _members, amountFromString(_amountController.text));
            });
          },
          selected: ((_payedBy != null) ? (_payedBy as PayedByOne).person : false)))
      :
      PayedTable(members: _members, amounts: (_payedBy as PayedByMany).amounts, keyPrefix: 'payed-by)');

    final Widget payedForWidget = (_payedFor is PayedForSimple) ?
      SimplePayedFor(
        members: _members,
        selected: (_payedFor as PayedForSimple).persons,
        onChanged: (members) {
          setState(() {
            _payedFor = PayedForSimple(members);
          });
        },
        onSplit: () {
          setState(() {
            _payedFor = payedForSimpleToAdvanced(_payedFor, _members, amountFromString(_amountController.text));
          });
        },
      )
      :
      PayedTable(
        members: _members,
        amounts: (_payedFor as PayedForAdvanced).amounts,
        keyPrefix: 'payed-for-',
      );

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
                        payedForWidget,
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

    String payedByError = _payedBy.validate(_amount);

    if (payedByError != null) {
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text(payedByError))
      );
      return;
    }

    String payedForError = _payedFor.validate(_amount);

    if (payedForError != null) {
      _scaffoldKey.currentState.showSnackBar(
          SnackBar(content: Text(payedForError))
      );
      return;
    }

    final Transaction tx = Transaction.create()
      ..uuid = generateUuid()
      ..label = _description
      ..amount = _amount
      ..timestamp = Int64(_date.millisecondsSinceEpoch~/1000)
      ..payedBy.addAll(_payedBy.asPayedBy(_amount))
      ..payedFor.addAll(_payedFor.asPayedFor(_amount));

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
