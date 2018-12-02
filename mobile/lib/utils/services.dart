import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/utils/uuid.dart' as UUID;

Future<SledRepository> _repository;
Future<String> _cachedShareServerUri;
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

String removeTrailingSlashes(String uri) {
  while (uri.endsWith('/')) {
    uri = uri.substring(0, uri.length-1);
  }

  return uri;
}

Future<String> _shareServerUri() {
  if (_cachedShareServerUri == null) {
    _cachedShareServerUri = rootBundle.loadString('assets/share_server_uri.txt')
        .then((serverUri) => removeTrailingSlashes(serverUri.trim()));
  }

  return _cachedShareServerUri;
}

Future<String> shareAccountUri(List<int> accountId) async =>
    "${await _shareServerUri()}/mobile/clone?accountId=${UUID.toString(accountId)}";
