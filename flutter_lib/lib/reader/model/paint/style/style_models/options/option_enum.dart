
import 'base_option.dart';

class OptionEnum<T> extends BaseOption {
  T _value;
  String _stringValue;

  OptionEnum.fromJson(Map<String, dynamic> json)
      : _value = json['myValue'],
        _stringValue = json['myStringValue'],
        super.fromJson(json);
}
