import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import 'package:flouze/utils/account_config.dart';

part 'serializers.g.dart';

@SerializersFor([
  AccountConfig
])
Serializers serializers = _$serializers;
