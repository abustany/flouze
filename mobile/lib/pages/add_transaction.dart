import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';

import 'package:intl/intl.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/account_members.dart';
import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/uuid.dart';
import 'package:flouze/widgets/amount_field.dart';
import 'package:flouze/widgets/simple_payed_by.dart';
import 'package:flouze/widgets/simple_payed_for.dart';
import 'package:flouze/widgets/payed_table.dart';

class AddTransactionPage extends StatefulWidget {
  final List<Person> members;
  final Transaction transaction;

  AddTransactionPage({Key key, @required this.members, this.transaction}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new AddTransactionPageState(members, transaction);
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

class PayedSplitEven extends AbstractPayedFor {
  final Set<Person> persons;

  PayedSplitEven(this.persons);

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

class PayedForSplitCustom extends AbstractPayedFor {
  final Map<Person, int> amounts;

  PayedForSplitCustom(this.amounts);

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

  String _description;
  int _amount;
  DateTime _date;
  AbstractPayedBy _payedBy;
  AbstractPayedFor _payedFor;
  List<int> _replaces;

  AddTransactionPageState(this._members, Transaction transaction) {
    _description = transaction?.label ?? '';
    _amount = transaction?.amount ?? 0;
    _amountController.text = amountToString(_amount);
    _date = (transaction != null) ? DateTime.fromMillisecondsSinceEpoch(1000*transaction.timestamp.toInt()) : DateTime.now();
    _payedBy = initPayedBy(this._members, transaction?.payedBy ?? List());
    _payedFor = initPayedFor(this._members, transaction?.payedFor ?? List());
    _replaces = transaction?.uuid ?? [];
  }

  static AbstractPayedBy initPayedBy(List<Person> members, List<PayedBy> payedBy) {
    if (payedBy.isEmpty) {
      return PayedByOne(null);
    }

    if (payedBy.length == 1) {
      return PayedByOne(findPersonById(members, payedBy.first.person));
    }

    return PayedByMany(Map.fromEntries(payedBy
        .map((p) => (MapEntry(findPersonById(members, p.person), p.amount)))
        .where((entry) => entry.key != null)));
  }

  static AbstractPayedFor initPayedFor(List<Person> members, List<PayedFor> payedFor) {
    if (payedFor.isEmpty) {
      return PayedSplitEven(members.toSet());
    }

    final Map<Person, int> amounts = Map.fromEntries(payedFor
        .map((p) => (MapEntry(findPersonById(members, p.person), p.amount)))
        .where((entry) => entry.key != null));

    if (amounts.values.toSet().length == 1) {
      // Even payment distribution for all members
      return PayedSplitEven(amounts.keys.toSet());
    }

    return PayedForSplitCustom(amounts);
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

  static PayedForSplitCustom payedForSimpleToAdvanced(PayedSplitEven payed, List<Person> members, int amount) {
    Set<Person> persons = payed.persons;
    List<int> splitAmounts = divideAmount(amount, persons.length);
    final Map<Person, int> amounts = Map.fromEntries(members.map((person) => MapEntry(person, 0)));
    IterableZip(<Iterable<dynamic>>[persons, splitAmounts]).forEach((entry) =>
      amounts[entry[0] as Person] = (entry[1] as int)
    );
    return PayedForSplitCustom(amounts);
  }

  @override
  Widget build(BuildContext context) {
    final Widget payedByWidget = (_payedBy == null || _payedBy is PayedByOne) ?
    Padding(
      padding: EdgeInsets.only(top: 12.0),
      child: SimplePayedBy(
        key: Key('payed-by'),
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
      PayedTable(key: Key('payed-by'), members: _members, amounts: (_payedBy as PayedByMany).amounts);

    final Widget payedForWidget = (_payedFor is PayedSplitEven) ?
      SimplePayedFor(
        key: Key('payed-for'),
        members: _members,
        selected: (_payedFor as PayedSplitEven).persons,
        onChanged: (members) {
          setState(() {
            _payedFor = PayedSplitEven(members);
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
        key: Key('payed-for'),
        members: _members,
        amounts: (_payedFor as PayedForSplitCustom).amounts,
      );

    final List<Widget> actionButtons = [
      IconButton(
        key: Key('action-save-transaction'),
        icon: Icon(Icons.check),
        onPressed: _onSave,
      ),
    ];

    if (_replaces.isNotEmpty) {
      actionButtons.insert(0, IconButton(
        key: Key('action-delete-transaction'),
        icon: Icon(Icons.delete),
        onPressed: _onDelete,
      ));
    }

    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text("Add a transaction"),
          actions: actionButtons,
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
                                    key: Key('input-description'),
                                    autofocus: true,
                                    initialValue: _description,
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
                                child: AmountField(
                                  key: Key('input-amount'),
                                  onSaved: (value) => _amount = value,
                                  notNull: true,
                                  controller: _amountController
                                ),
                              ),

                              formRow(
                                  context: context,
                                  label: 'Date',
                                  child: InkWell(
                                    key: Key('input-date'),
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
      ..replaces = _replaces
      ..label = _description
      ..amount = _amount
      ..timestamp = Int64(_date.millisecondsSinceEpoch~/1000)
      ..payedBy.addAll(_payedBy.asPayedBy(_amount))
      ..payedFor.addAll(_payedFor.asPayedFor(_amount));

    Navigator.of(context).pop(tx);
  }

  void _onDelete() async {
    var doDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('Delete the transaction?'),
        actions: <Widget>[
          FlatButton(
            child: Text('Cancel'),
            onPressed: () { Navigator.of(context).pop(false); },
          ),
          FlatButton(
            child: Text('Delete', style: TextStyle(color: Color(0xFFCC0000))),
            onPressed: () { Navigator.of(context).pop(true); },
          )
        ],
      )
    ) ?? false;

    if (!doDelete || !mounted) {
      return;
    }

    assert(_replaces.isNotEmpty);

    final Transaction tx = Transaction.create()
      ..uuid = generateUuid()
      ..replaces = _replaces
      ..deleted = true
      ..timestamp = Int64(_date.millisecondsSinceEpoch~/1000);

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
