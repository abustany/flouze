import 'package:flutter/material.dart';

import 'package:flouze/blocs/add_account.dart';
import 'package:flouze/widgets/member_entry.dart';

class AddAccountPage extends StatefulWidget {
  AddAccountPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new AddAccountPageState();
}

class AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  AddAccountBloc _bloc;
  final TextEditingController _nameController = TextEditingController();
  final Map<int, TextEditingController> _membersController = {};

  @override
  void initState() {
    _bloc = AddAccountBloc();
    _nameController.addListener(() => _bloc.setName(_nameController.text));
    _addMemberController(0); // Append the account owner
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _membersController.forEach((_, c) => c.dispose());
    _bloc.dispose();
    super.dispose();
  }

  void _addMemberController(int idx) {
    final controller = TextEditingController();
    controller.addListener(() {
      _bloc.setMemberName(idx, controller.text);
    });
    _membersController[idx] = controller;
  }

  void _removeMemberController(int idx) {
    // We'd probably need to dispose the controller as well? But the text field
    // won't be unmounted until the state is updated, so we can't do it here...
    _membersController.remove(idx);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Create an account"),
          actions: <Widget>[
            IconButton(
              key: Key('action-save-account'),
              icon: Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop(_bloc.makeAccount());
              }
            )
          ],
        ),
        body: ListView(
          children: <Widget>[
            Padding(
                padding: new EdgeInsets.all(16.0),
                child: new Center(
                    child: StreamBuilder<AddAccountState>(
                      stream: _bloc.account,
                      initialData: AddAccountState.initial(),
                      builder: (context, snapshot) => Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TextFormField(
                              key: Key('input-account-name'),
                              autofocus: true,
                              textCapitalization: TextCapitalization.sentences,
                              controller: _nameController,
                              autovalidate: true,
                              validator: (_) => snapshot.data.isNameValid ? null : 'Account name cannot be empty',
                              decoration: InputDecoration(
                                labelText: "Title",
                              ),
                            ),

                            MemberEntryWidget(
                              key: Key('member-0'),
                              controller: _membersController[0],
                              hint: '',
                              label: 'Your name',
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _buildMemberWidgets(snapshot.data),
                            ),

                            Container(
                              margin: EdgeInsets.only(top: 8.0, left: 38.0),
                              child: RaisedButton(
                                key: Key('member-add'),
                                child: Text('Add member'),
                                onPressed: () { _bloc.addMember(); }
                              )
                            ),
                          ],
                        )
                      )
                    )
                )
            )
          ],
        )
    );
  }

  List<Widget> _buildMemberWidgets(AddAccountState state) {
    return state.members.map((idx, name) {
      if (idx == 0) {
        // 0 is the owner
        return MapEntry(idx, null);
      }

      if (!_membersController.containsKey(idx)) {
        _addMemberController(idx);
      }

      return MapEntry(
        idx,
        MemberEntryWidget(
          key: Key('member-$idx'),
          controller: _membersController[idx],
          label: 'Member name',
          onRemove: () {
            _bloc.removeMember(idx);
            _removeMemberController(idx);
          },
        )
      );
    }).values.where((w) => w != null).toList();
  }
}
