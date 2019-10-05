import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:flutter/foundation.dart';

class ClosableHandle<T> {
  Future<T> _handle;

  Future<T> Function() _factory;
  Future<void> Function(T) _close;

  ClosableHandle(this._factory, this._close);

  Future<T> get ptr {
    if (_handle == null) {
      _handle = this._factory();
    }

    return _handle;
  }

  void close() {
    if (_handle != null) {
      _handle.then((ptr) => _close(ptr));
      _handle = null;
    }
  }
}

class ClosablePointer<T extends ffi.NativeType> {
  Future<ffi.Pointer<T>> _ptr;

  ffi.Pointer<T> Function() _factory;
  void Function(ffi.Pointer<T>) _close;

  ClosablePointer(this._factory, this._close);

  Future<ffi.Pointer<T>> get ptr {
    if (_ptr == null) {
      _ptr = compute((_) { return this._factory(); }, null);
    }

    return _ptr;
  }

  void close() {
    if (_ptr != null) {
      _ptr.then((ptr) => _close(ptr));
      _ptr = null;
    }
  }
}

class SyncClosablePointer<T extends ffi.NativeType> {
  ffi.Pointer<T> _ptr;

  ffi.Pointer<T> Function() _factory;
  void Function(ffi.Pointer<T>) _close;

  SyncClosablePointer(this._factory, this._close);

  ffi.Pointer<T> get ptr {
    if (_ptr == null) {
      _ptr = _factory();
    }

    return _ptr;
  }

  void close() {
    if (_ptr != null) {
      _close(_ptr);
      _ptr = null;
    }
  }
}
