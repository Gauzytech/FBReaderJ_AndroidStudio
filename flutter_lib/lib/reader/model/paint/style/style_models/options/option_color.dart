import 'package:flutter_lib/reader/model/selection/highlight_block.dart';

import 'base_option.dart';

class OptionColor extends BaseOption {
  ColorData _value;
  String _stringValue;

  OptionColor.fromJson(Map<String, dynamic> json)
      : _value = json['myValue'],
        _stringValue = json['myStringValue'],
        super.fromJson(json);
}
