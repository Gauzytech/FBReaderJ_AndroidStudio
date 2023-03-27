
import 'base_option.dart';

class OptionStringList extends BaseOption {
  final String _delimiter;
  List<String> _value;
  String _stringValue;

  OptionStringList.fromJson(Map<String, dynamic> json)
      : _delimiter = json['myDelimiter'],
        _value = json['myValue'],
        _stringValue = json['myStringValue'],
        super.fromJson(json);
}
