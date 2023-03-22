import 'package:flutter_lib/reader/animation/model/paint/style/base_option.dart';
import 'package:flutter_lib/utils/config.dart';

class OptionBoolean extends BaseOption {
  final bool _defaultValue;

  OptionBoolean(String group, String optionName, bool defaultValue)
      : _defaultValue = defaultValue,
        super(group, optionName, defaultValue ? "true" : "false");

  OptionBoolean.fromJson(Map<String, dynamic> json)
      : _defaultValue = json['myDefaultValue'],
        super.fromJson(json);

  bool getValue() {
    if (specialName != null) {
      return Config().getSpecialBooleanValue(specialName!, _defaultValue);
    } else {
      return "true" == configValue;
    }
  }
}
