import 'package:flutter_lib/model/pair.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static const String _myNullString = "__NULL__";

  late SharedPreferences _prefs;

  Config._internal() {
    initializeSharedPref();
  }

  factory Config() => _instance;

  static late final Config _instance = Config._internal();

  final Map<Pair, String> _myCache = {};
  final Set<String> _myCachedGroups = {};

  bool getSpecialBooleanValue(String name, bool defaultValue) {
    return _prefs.getBool(name) ?? defaultValue;
  }

  String getSpecialStringValue(String name, String defaultValue) {
    return _prefs.getString(name) ?? defaultValue;
  }

  String getValue(Pair id, String defaultValue) {
    String? value = _myCache[id];
    if (value == null) {
      if (_myCachedGroups.contains(id.left)) {
        value = _myNullString;
      } else {
        //     try {
        //       value = getValueInternal(id.Group, id.Name);
        //     }
        // catch(NotAvailableException e) {
        //       return defaultValue;
        //     }
        if (value == null) {
          value = _myNullString;
        }
      }
      _myCache[id] = value;
    }
    return value != _myNullString ? value : defaultValue;
  }

  Future<void> initializeSharedPref() async {
    _prefs = await SharedPreferences.getInstance();
  }
}
