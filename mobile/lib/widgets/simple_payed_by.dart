import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/keys.dart';

class SimplePayedBy extends StatelessWidget {
  final List<Person> members;
  final void Function(Person p) onSelected;
  final void Function() onSplit;
  final Person selected;

  SimplePayedBy({Key key, @required this.members, this.onSelected, this.onSplit, this.selected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int i = -1;

    return Wrap(
      key: key,
      spacing: 8.0,
      runSpacing: 8.0,
      children: members.map((person) {
        i++;
        return ChoiceChip(
          key: subkey(key, '-member-$i'),
          selected: person == selected,
          onSelected: (selected) {
            if (onSelected != null && selected) {
              onSelected(person);
            }
          },
          avatar: Icon(Icons.account_circle),
          label: Text(person.name),
        );
      }).toList() + [
        ChoiceChip(
            key: subkey(key, '-split'),
            selected: false,
            onSelected: (selected) {
              if (onSplit != null) {
                onSplit();
              }
            },
            avatar: Icon(Icons.donut_small),
            label: Text('Split...'))
      ],
    );
  }
}