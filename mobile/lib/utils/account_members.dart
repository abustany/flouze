import 'package:collection/collection.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

final Function _listEquality = ListEquality().equals;

String personName(List<Person> members, List<int> personId) {
  for (Person p in members) {
    if (_listEquality(p.uuid, personId)) {
      return p.name;
    }
  }

  return '??';
}
