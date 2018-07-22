import 'package:flutter/material.dart';

class MemberEntryWidget extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  MemberEntryWidget({Key key, this.initialValue, this.onChanged}) : super(key: key);

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
          child: TextField(
            decoration: new InputDecoration(hintText: 'Add a new member…'),
            onChanged: (value) {
              this.onChanged(value);
            },
          ),
        )
      ],
    );
  }
}
