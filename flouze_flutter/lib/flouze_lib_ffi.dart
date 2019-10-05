import 'dart:ffi' as ffi;

import 'dylib_utils.dart';

ffi.DynamicLibrary _cachedFlouzeLibrary;

ffi.DynamicLibrary get flouzeLibrary =>
    _cachedFlouzeLibrary ??= dlopenPlatformSpecific('flouze_flutter_ffi');
