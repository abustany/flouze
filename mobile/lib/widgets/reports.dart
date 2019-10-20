import 'package:flouze_flutter/bindings.pb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/localization.dart';
import 'package:flouze/utils/account_members.dart';
import 'package:flouze/utils/amounts.dart';
import 'package:flouze/utils/config.dart';
import 'package:flouze/utils/keys.dart';

class Reports extends StatelessWidget {
  final List<Person> members;
  final Map<List<int>, int> balance;
  final List<Transfer> transfers;

  Reports({Key key, @required this.members, @required this.balance, @required this.transfers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int i = -1;
    int j = -1;

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
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(child: Text(FlouzeLocalizations.of(context).howToSettle), padding: EdgeInsets.only(top: 24)),
            Table(
              children: [...transfers.map((entry) {
                j++;
                final debitorName = personName(members, entry.debitor);
                final creditorName = personName(members, entry.creditor);

                return TableRow(children: [
                  Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(FlouzeLocalizations.of(context).xOwesY(debitorName, creditorName), key: subkey(key, '-$i-owes'), textAlign: TextAlign.right)
                  ),
                  Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('${amountToString(entry.amount.toInt())} ${AppConfig.currencySymbol}', key: subkey(key, '-$i-amount'))
                  )
                ]);
              })],
            )
          ],
        ),
      ],
    );
  }
}
