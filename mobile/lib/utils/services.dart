import 'dart:io';

import 'package:flutter/material.dart';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

Future<SledRepository> _repository;
Navigator _navigator;

Future<SledRepository> getRepository() async {
  if (_repository != null) {
    return _repository;
  }

  print('Loading Flouze library');
  await FlouzeFlutter.init();

  Directory appDocDir = await getApplicationDocumentsDirectory();
  final String dbPath = path.join(appDocDir.path, 'flouze.db');

  print('Initializing database in $dbPath');
  _repository = SledRepository.fromFile(dbPath);

  return _repository;
}

void closeRepository() async {
  if (_repository != null) {
    await (await _repository).close();
    _repository = null;
  }
}

void setNavigator(Navigator navigator) {
  _navigator = navigator;
}

Navigator getNavigator() {
  return _navigator;
}