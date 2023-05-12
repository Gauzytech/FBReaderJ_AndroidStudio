import 'package:flutter_lib/utils/config.dart';

import 'base_option.dart';

class OptionString extends BaseOption {
  OptionString.fromJson(super.json) : super.fromJson();

  String getValue() {
    if (specialName != null) {
      return Config().getSpecialStringValue(specialName!, defaultStringValue);
    } else {
      return configValue;
    }
  }
}
