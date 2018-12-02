import 'package:collection/collection.dart';

import 'package:uuid/uuid.dart';

Uuid _uuid = new Uuid();

List<int> generateUuid() {
  List<int> res = List.filled(16, 0);
  _uuid.v4(buffer: res);
  return res;
}

List<int> parse(String uuid) {
  return _uuid.parse(uuid);
}

String toString(List<int> uuid) {
  return _uuid.unparse(uuid);
}

final Function uuidEquals = ListEquality().equals;
