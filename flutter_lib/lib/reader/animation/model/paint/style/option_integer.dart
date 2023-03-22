import 'dart:core';

import 'package:flutter_lib/reader/animation/model/paint/style/base_option.dart';

class OptionInteger extends BaseOption {
  int _value;
  String _stringValue;

  OptionInteger.fromJson(Map<String, dynamic> json)
      : _value = json['myValue'],
        _stringValue = json['myStringValue'],
        super.fromJson(json);
}
