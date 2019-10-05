import 'dart:convert';
import 'dart:ffi' as ffi;

class Utf8 extends ffi.Struct<Utf8> {
  @ffi.Uint8()
  int char;

  static ffi.Pointer<Utf8> allocate(String dartStr) {
    List<int> units = Utf8Encoder().convert(dartStr);
    ffi.Pointer<Utf8> str = ffi.Pointer.allocate(count: units.length + 1);

    for (int i = 0; i < units.length; ++i) {
      str.elementAt(i).load<Utf8>().char = units[i];
    }

    str.elementAt(units.length).load<Utf8>().char = 0;

    return str.cast();
  }

  String toString() {
    final str = addressOf;

    if (str == ffi.nullptr) { // ignore: unrelated_type_equality_checks
      return null;
    }

    int len = 0;
    while (str.elementAt(++len).load<Utf8>().char != 0) {}

    List<int> units = List(len);

    for (int i = 0; i < len; ++i) {
      units[i] = str
          .elementAt(i)
          .load<Utf8>()
          .char;
    }

    return Utf8Decoder().convert(units);
  }
}
