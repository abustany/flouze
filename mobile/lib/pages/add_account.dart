import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/uuid.dart';
import 'package:flouze/widgets/member_entry.dart';

class AddAccountPage extends StatefulWidget {
  AddAccountPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new AddAccountPageState();
}

class AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();

  String _accountName = '';
  List<String> _members = [];

  @override
  void initState() {
    super.initState();
  }

  void _onSave() {
    final FormState state = _formKey.currentState;

    if (!state.validate()) {
      print('There are some validation errors');
      return;
    }

    state.save();

    final List<Person> members = _members
        .where((name) => name.isNotEmpty)
        .map((name) {
          final Person person = Person.create()..uuid = generateUuid()..name = name;
          return person;
        }).toList();

    final Account account = Account.create()
      ..uuid = generateUuid()
      ..label = _accountName
      ..members.addAll(members);

    Navigator.of(context).pop(account);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> members = List.from(_members);

    while (members.isNotEmpty && members.last == '') {
      members.removeLast();
    }

    if (members.isEmpty || members.last != '') {
      members.add('');
    }

    final int nMembers = members.length;
    final List<Widget> memberWidgets = members.asMap().map((idx, name) =>
        MapEntry(
            idx,

            new MemberEntryWidget(
              key: Key('member-$idx'),
              initialValue: name,
              onChanged: (value) {
                members[idx] = value;

                if (idx == nMembers-1 && value.isNotEmpty) {
                  members.add('');
                }

                setState(() {
                  _members = members;
                });
              },
            )
        )
    ).values.toList();

    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Create an account"),
          actions: <Widget>[
            IconButton(
              key: Key('action-save-account'),
              icon: Icon(Icons.check),
              onPressed: _onSave,
            )
          ],
        ),
        body: new Padding(
            padding: new EdgeInsets.all(16.0),
            child: new Center(
                child: new Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Name',
                          style: Theme.of(context).textTheme.title,
                        ),
                        TextFormField(
                          key: Key('input-account-name'),
                          autofocus: true,
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Account name cannot be empty';
                            }
                          },
                          onSaved: (name) => _accountName = name,
                        ),

                        Container(
                          margin: EdgeInsetsDirectional.only(top: 0.0),
                          child: Text(
                            'Members',
                            style: Theme.of(context).textTheme.title,
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: memberWidgets,
                        )
                      ],
                    )
                )
            )
        )
    );
  }
}
