import 'dart:core';

import 'package:flutter_lib/model/pair.dart';
import 'package:flutter_lib/utils/config.dart';

abstract class BaseOption {
  final Pair<String, String> _id;
  final String defaultStringValue;
  String? specialName;

  BaseOption(String group, String optionName, String defaultStringValue)
      : _id = Pair(group, optionName),
        defaultStringValue = defaultStringValue ?? "";

  BaseOption.fromJson(Map<String, dynamic> json)
      : _id = Pair(json['myId']['Group'], json['myId']['Name']),
        defaultStringValue = json['myDefaultStringValue'],
        specialName = json['mySpecialName'];

  String get configValue => Config().getValue(_id, defaultStringValue);
}
