import 'package:flutter/material.dart';

import 'package:flouze/localization.dart';
import 'package:flouze/utils/keys.dart';

class MemberEntryWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final void Function() onRemove;

  MemberEntryWidget({Key key, this.controller, this.hint, this.label, this.onRemove}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: TextFormField(
            key: subkey(key, '-input-name'),
            decoration: new InputDecoration(hintText: hint, labelText: label, icon: Icon(Icons.account_circle)),
            controller: controller,
            textCapitalization: TextCapitalization.words,
            autovalidate: true,
            validator: (text) =>
              text.isNotEmpty ? null : FlouzeLocalizations.of(context).memberEntryWidgetValidationErrorNameEmpty,
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
