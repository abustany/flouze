import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:flouze/utils/account_config.dart';
import 'package:flouze/utils/serializers.dart';

Future<AccountConfig> loadAccountConfig(List<int> accountUuid) async {
  var prefs = await SharedPreferences.getInstance();
  var accountJson = prefs.getString(accountConfigKey(accountUuid));

  if (accountJson == null) {
    return AccountConfig((b) => b..synchronized = false);
  }

  return serializers.deserialize(json.decode(accountJson)) as AccountConfig;
}

Future<Null> saveAccountConfig(List<int> accountUuid, AccountConfig accountConfig) async {
  var prefs = await SharedPreferences.getInstance();
  await prefs.setString(accountConfigKey(accountUuid), json.encode(serializers.serialize(accountConfig)));
}

const _ACCOUNT_KEY_PREFIX = 'account:';
Uuid _uuid = new Uuid();

String accountConfigKey(List<int> accountUuid) => _ACCOUNT_KEY_PREFIX + _uuid.unparse(accountUuid);
