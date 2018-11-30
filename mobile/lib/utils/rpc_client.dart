import 'package:flutter/services.dart' show rootBundle;

import 'package:flouze_flutter/flouze_flutter.dart';

Future<JsonRpcClient> _cachedClient;

Future<JsonRpcClient> getJsonRpcClient() async {
  if (_cachedClient == null) {
    _cachedClient = rootBundle.loadString('assets/sync_server_uri.txt')
      .then((serverUri) => serverUri.trim())
      .then((serverUri) => JsonRpcClient.create(serverUri));
  }

  return _cachedClient;
}
