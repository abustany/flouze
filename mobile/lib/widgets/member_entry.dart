import 'package:flutter/material.dart';

import 'package:flouze/utils/keys.dart';

class MemberEntryWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final void Function() onRemove;

  MemberEntryWidget({Key key, this.controller, this.hint, this.onRemove}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: EdgeInsetsDirectional.only(end: 12.0),
          child: Icon(Icons.account_circle),
        ),
        Expanded(
          child: TextFormField(
            key: subkey(key, '-input-name'),
            decoration: new InputDecoration(hintText: hint),
            controller: controller,
            textCapitalization: TextCapitalization.words,
            autovalidate: true,
            validator: (text) => text.isNotEmpty ? null : 'Member name cannot be empty',
          ),
        ),
        if (onRemove != null)
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onRemove,
          )
      ],
    );
  }
}
