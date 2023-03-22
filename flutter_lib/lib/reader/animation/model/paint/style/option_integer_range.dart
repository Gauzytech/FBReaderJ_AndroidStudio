import 'dart:math';

import 'package:flutter_lib/reader/animation/model/paint/style/base_option.dart';

class OptionIntegerRange extends BaseOption {
  final int _minValue;
  final int _maxValue;

  int _value;
  String _stringValue;

  OptionIntegerRange.fromJson(Map<String, dynamic> json)
      : _minValue = json['MinValue'],
        _maxValue = json['MaxValue'],
        _value = json['myValue'],
        _stringValue = json['myStringValue'],
        super.fromJson(json);

  int getValue() {
    final String stringValue = configValue;
    if (stringValue != _stringValue) {
      _stringValue = stringValue;
      _value = _valueInRange(int.parse(stringValue), _minValue, _maxValue);
    }
    return _value;
  }

  int _valueInRange(int value, int minVal, int maxVal) {
    return min(maxVal, max(minVal, value));
  }
}
