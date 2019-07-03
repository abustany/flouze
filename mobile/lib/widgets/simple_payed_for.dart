import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/keys.dart';

class SimplePayedFor extends StatelessWidget {
  final List<Person> members;
  final void Function(Set<Person> p) onChanged;
  final void Function() onSplit;
  final Set<Person> selected;

  SimplePayedFor({Key key, @required this.members, this.onChanged, this.onSplit, this.selected}) : super(key: key) {
    members.sort((p1, p2) => p1.name.toLowerCase().compareTo(p2.name.toLowerCase()));
  }

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
          selected: (selected ?? Set()).contains(person),
          onSelected: (selected) {
            if (onChanged != null) {
              onChanged(selected ? this.selected.union({person}) : this.selected.difference({person}));
            }
          },
          avatar: Icon(Icons.account_circle),
          label: Text(person.name),
        );
      },
      ).toList() + [
        ChoiceChip(
            key: subkey(key, '-split'),
            selected: false,
            onSelected: (selected) {
              if (onSplit != null) {
                onSplit();
              }
            },
            avatar: Icon(Icons.donut_small),
            label: Text('Advanced...'))
      ],
    );
  }
}