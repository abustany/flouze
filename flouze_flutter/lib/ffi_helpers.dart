import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flouze_flutter/closeable_pointer.dart';

import 'bytes.dart';
import 'utf8.dart';

T withError<T>(T Function(ffi.Pointer<ffi.Pointer<Utf8>> errPtr) f) {
  ffi.Pointer<ffi.Pointer<Utf8>> errPtr = ffi.Pointer.allocate();
  T res = f(errPtr);
  ffi.Pointer<Utf8> err = errPtr.load();
  errPtr.free();

  if (err.address != 0) {
    final errStr = err.load<Utf8>().toString();
    err.free();
    throw Exception(errStr);
  }

  return res;
}

T withCStr<T>(String s, T Function(ffi.Pointer<Utf8>) f) {
  final cStr = Utf8.allocate(s);

  try {
    return f(cStr);
  } finally {
    cStr.free();
  }
}

T withCBytes<T>(Uint8List data, T Function(ffi.Pointer<Byte>, int len) f) {
  final cBytes = Byte.allocate(data);

  try {
    return f(cBytes, data.length);
  } finally {
    cBytes.free();
  }
}

class WithBytes<T> {
  WithBytes(T result, Uint8List bytes) {
    this.result = result;
    this.bytes = bytes;
  }

  T result;
  Uint8List bytes;
}

// Assume that sizeof(size_t) == sizeof(void*)
WithBytes<T> withOutCBytes<T>(T Function(ffi.Pointer<ffi.Pointer<Byte>> dataPtr, ffi.Pointer<ffi.IntPtr> dataLenPtr) f) {
  ffi.Pointer<ffi.Pointer<Byte>> dataPtr = ffi.Pointer.allocate();
  ffi.Pointer<ffi.IntPtr> lenPtr = ffi.Pointer.allocate();

  T res = f(dataPtr, lenPtr);

  int len = lenPtr.load();
  lenPtr.free();

  ffi.Pointer<Byte> data = dataPtr.load();
  dataPtr.free();

  return WithBytes(res, data.load<Byte>().toUint8List(len));
}

abstract class Call {
  Call();
  Call.withSender(this.sender);
  SendPort sender;
}

class CallResult {
  CallResult(this.result, this.error);
  factory CallResult.ok(dynamic result) => CallResult(result, null);
  factory CallResult.error(dynamic e) => CallResult(null, e is Exception ? e : Exception(e.toString()));

  dynamic unwrap() {
    if (this.error != null) {
      throw this.error;
    }

    return this.result;
  }

  final dynamic result;
  final Exception error;
}

// SendPort to the global isolate
Future<SendPort> _sendPort;

class _InitCall extends Call {
  _InitCall(this.fn, this.initMsg);
  final void Function(dynamic init) fn;
  final Call initMsg;
}

class DestroyCall extends Call {}

void _isolateMain(SendPort sender) {
  final port = ReceivePort();
  sender.send(port.sendPort);

  port.listen((msg) {
    switch (msg.runtimeType) {
      case _InitCall:
        final call = (msg as _InitCall);
        call.initMsg.sender = call.sender;
        call.fn(call.initMsg);
        return null;
      default:
        throw new Exception("Unknown message type: ${msg.runtimeType}");
    }
  });
}

abstract class IsolateProxy<T> {
  final ClosableHandle<SendPort> _handle;

  IsolateProxy(Future<SendPort> Function() factory)
      : _handle = ClosableHandle(factory, _destroy);

  static Future<void> _destroy(SendPort sendPort) =>
      IsolateProxy.callStatic(sendPort, DestroyCall());

  static void handleCalls(
      SendPort sender,
      dynamic Function() makeInstance,
      Function(dynamic instance, Call call) handleCall,
    ) {
    dynamic instance;

    try {
      instance = makeInstance();
    } catch (e) {
      sender.send(CallResult.error(e));
    }
    ReceivePort inPort = ReceivePort();
    sender.send(CallResult.ok(inPort.sendPort));

    inPort.listen((msg) {
      final call = (msg as Call);
      final sender = call.sender;

      try {
        sender.send(CallResult.ok(handleCall(instance, call)));
      } catch (e) {
        if (e is Exception) {
          sender.send(CallResult.error(e));
        } else {
          sender.send(CallResult.error(Exception("Unknown error $e")));
        }
      }

      if (call is DestroyCall) {
        inPort.close();
      }
    });
  }

  static Future<SendPort> spawnInIsolate(Call call, void Function(dynamic initCall) init) async {
    if (_sendPort == null) {
      final port = ReceivePort();
      Isolate.spawn(_isolateMain, port.sendPort);
      _sendPort = port.first.then((res) => res as SendPort);
    }

    return callStatic(await _sendPort, _InitCall(init, call)).then((res) => res as SendPort);
  }

  Future<dynamic> call(Call call) async {
    final port = ReceivePort();
    call.sender = port.sendPort;
    (await _handle.ptr).send(call);
    return ((await port.first) as CallResult).unwrap();
  }

  static Future<dynamic> callStatic(SendPort sendPort, Call call) async {
    final port = ReceivePort();
    call.sender = port.sendPort;
    sendPort.send(call);
    return ((await port.first) as CallResult).unwrap();
  }

  void destroy() {
    _handle.close();
  }
}
