import 'package:flutter/material.dart';

Key subkey(Key key, String suffix) {
  if (key is ValueKey<String>) {
    return Key(key.value + suffix);
  } else {
    return Key(key.toString() + suffix);
  }
}
