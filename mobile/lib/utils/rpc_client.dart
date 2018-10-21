import 'package:flutter/services.dart' show rootBundle;

import 'package:flouze_flutter/flouze_flutter.dart';

JsonRpcClient _cachedClient;

Future<JsonRpcClient> getJsonRpcClient() async {
  if (_cachedClient == null) {
    String syncServerUrl = (await rootBundle.loadString('assets/sync_server_uri.txt')).trim();
    _cachedClient = await JsonRpcClient.create(syncServerUrl);
  }

  return _cachedClient;
}
