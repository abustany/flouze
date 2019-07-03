import 'dart:async';

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/blocs/transaction.dart';
import 'package:flouze/utils/amounts.dart';
import 'package:flouze/widgets/amount_field.dart';
import 'package:flouze/widgets/simple_payed_by.dart';
import 'package:flouze/widgets/simple_payed_for.dart';
import 'package:flouze/widgets/payed_table.dart';

class AddTransactionPage extends StatefulWidget {
  final List<Person> members;
  final Transaction transaction;

  AddTransactionPage({Key key, @required this.members, this.transaction}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AddTransactionPageState(members, transaction ?? Transaction.create());
}

class AddTransactionPageState extends State<AddTransactionPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final List<Person> _members;
  final Transaction _transaction;

  TransactionBloc _bloc;
  StreamSubscription<TransactionState> _blocSub;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final DateFormat _dateFormat = DateFormat.yMMMd();


  AddTransactionPageState(this._members, this._transaction);

  @override
  void initState() {
    _bloc = TransactionBloc(_transaction, _members);

    _amountController.addListener(() {
      try {
        _bloc.setAmount(amountFromString(_amountController.text));
      } catch (ignored) {
        _bloc.setAmount(null);
      }
    });

    _descriptionController.addListener(() {
      _bloc.setLabel(_descriptionController.text);
    });

    _blocSub = _bloc.transaction.listen((s) {
      if (s is TransactionSaveState) {
        Navigator.of(context).pop(s.transaction);
      }
    });

    _bloc.transaction.where((s) => s is TransactionLoadedState).first.then((s) {
      final state = (s as TransactionLoadedState);
      _descriptionController.text = state.label.value;
      _amountController.text = amountToString(state.amount, zeroIsEmpty: true);
    });

    super.initState();
  }

  @override
  dispose() {
    _blocSub.cancel();
    super.dispose();
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


  @override
  Widget build(BuildContext context) =>
      StreamBuilder<TransactionState>(
          stream: _bloc.transaction,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.active || snapshot.data is! TransactionLoadedState) {
              return Container();
            }

            return _buildEditor(snapshot.data);
          });

  Widget _buildEditor(TransactionLoadedState state) {
    final payedBy = state.payedBy.value;
    final Widget payedByWidget = payedBy is PayedByOne ?
      SimplePayedBy(
          key: Key('payed-by'),
          members: _members,
          onSelected: (Person p) => _bloc.setPayedBySingle(p),
          onSplit: () => _bloc.splitPayedBy(),
          selected: payedBy.person,
      )
      :
      PayedTable(
          key: Key('payed-by'),
          members: _members,
          amounts: (payedBy as PayedByMany).amounts,
          onChanged: _bloc.setPayedBy,
      );

    final payedFor = state.payedFor.value;
    final Widget payedForWidget = payedFor is PayedSplitEven ?
      SimplePayedFor(
        key: Key('payed-for'),
        members: _members,
        selected: payedFor.persons,
        onChanged: (members) => _bloc.setPayedForEven(members),
        onSplit: () => _bloc.splitPayedFor(),
      )
      :
      PayedTable(
        key: Key('payed-for'),
        members: _members,
        amounts: (payedFor as PayedForSplitCustom).amounts,
        onChanged: _bloc.setPayedFor,
      );

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("Add a transaction"),
          actions: _actionButtons(state),
        ),
        body: Padding(
            padding: EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0),
            child: ListView(
                children: <Widget>[
                  Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            key: Key('input-description'),
                            autofocus: true,
                            controller: _descriptionController,
                            decoration: InputDecoration(labelText: 'Description'),
                            textCapitalization: TextCapitalization.sentences,
                            autovalidate: true,
                            validator: (_) => state.label.error,
                          ),

                          AmountField(
                            key: Key('input-amount'),
                            label: 'Amount',
                            controller: _amountController
                          ),

                          InkWell(
                              key: Key('input-date'),
                              onTap: () => _pickDate(context, state.date),
                              child: InputDecorator(
                                  decoration: InputDecoration(labelText: 'Date'),
                                  child: Text(_dateFormat.format(state.date), textAlign: TextAlign.end),
                              )
                          ),

                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Payed by',
                              border: InputBorder.none,
                              errorText: state.payedBy.error,
                            ),
                            child: payedByWidget,
                          ),

                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Payed for',
                              border: InputBorder.none,
                              errorText: state.payedFor.error,
                            ),
                            child: payedForWidget,
                          ),
                        ],
                      )
                  )
                ])
        )
    );
  }

  List<Widget> _actionButtons(TransactionLoadedState state) => <Widget>[
      if (state.canDelete)
        IconButton(
          key: Key('action-delete-transaction'),
          icon: Icon(Icons.delete),
          onPressed: () async {
            final doDelete = await showDialog(
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

            if (doDelete) {
              _bloc.deleteTransaction();
            }
          }
        ),
      IconButton(
        key: Key('action-save-transaction'),
        icon: Icon(Icons.check),
        onPressed: () {
          if (_formKey.currentState.validate()) {
            _bloc.saveTransaction();
          }
        },
      ),
    ];

  void _pickDate(BuildContext context, DateTime initialDate) async {
    final DateTime picked = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(1960), lastDate: DateTime(2100));

    if (picked == null) {
      return;
    }

    _bloc.setDate(picked);
  }
}
