import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/account_members.dart';
import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/config.dart';
import 'package:flouze/utils/keys.dart';

class Reports extends StatelessWidget {
  final List<Person> members;
  final Map<List<int>, int> balance;

  Reports({Key key, @required this.members, @required this.balance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int i = -1;

    return ListView(
      shrinkWrap: false,
      children: [
        Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Table(
              children: balance.entries.map((entry) {
                i++;
                return TableRow(children: [
                  Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(personName(members, entry.key), key: subkey(key, '-$i-name'), textAlign: TextAlign.right)
                  ),
                  Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('${amountToString(entry.value)} ${AppConfig.currencySymbol}', key: subkey(key, '-$i-balance'))
                  )
                ]);
              }).toList(),
            )
        )
      ],
    );
  }
}
