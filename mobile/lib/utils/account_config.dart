import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'account_config.g.dart';

abstract class AccountConfig implements Built<AccountConfig, AccountConfigBuilder> {
  BuiltList<int> get meUuid;
  bool get synchronized;

  AccountConfig._();
  factory AccountConfig([updates(AccountConfigBuilder b)]) = _$AccountConfig;

  static Serializer<AccountConfig> get serializer => _$accountConfigSerializer;
}
