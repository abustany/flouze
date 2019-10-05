import 'dart:ffi' as ffi;
import 'dart:typed_data';

class Byte extends ffi.Struct<Byte> {
  @ffi.Uint8()
  int byte;

  static ffi.Pointer<Byte> allocate(Uint8List data) {
    ffi.Pointer<Byte> bytes = ffi.Pointer.allocate(count: data.length);

    for (int i = 0; i < data.length; ++i) {
      bytes.elementAt(i).load<Byte>().byte = data[i];
    }

    return bytes.cast();
  }

  Uint8List toUint8List(int length) {
    final bytes = addressOf;

    if (bytes == ffi.nullptr) { // ignore: unrelated_type_equality_checks
      return null;
    }

    final res = Uint8List(length);

    for (int i = 0; i < length; ++i) {
      res[i] = bytes
          .elementAt(i)
          .load<Byte>()
          .byte;
    }

    return res;
  }
}
