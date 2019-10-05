import 'dart:async';

StreamController<String> _eventStreamController = StreamController.broadcast();

class Events {
  static const String ACCOUNT_LIST_CHANGED = 'account_list_changed';

  static void post(String event) {
    _eventStreamController.add(event);
  }

  static Stream<String> stream() {
    return _eventStreamController.stream;
  }
}
