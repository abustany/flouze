import 'package:flutter/material.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

class SimplePayedFor extends StatelessWidget {
  final List<Person> members;
  final void Function(Set<Person> p) onChanged;
  final void Function() onSplit;
  final Set<Person> selected;

  SimplePayedFor({Key key, @required this.members, this.onChanged, this.onSplit, this.selected});

  @override
  Widget build(BuildContext context) =>
      Wrap(
        key: key,
        spacing: 8.0,
        runSpacing: 8.0,
        children: members.map((person) =>
            ChoiceChip(
              selected: (selected ?? Set()).contains(person),
              onSelected: (selected) {
                if (onChanged != null && selected) {
                  onChanged(this.selected.union(Set.from([person])));
                }
              },
              avatar: Icon(Icons.account_circle),
              label: Text(person.name),
            ),
        ).toList() + [
          ChoiceChip(
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