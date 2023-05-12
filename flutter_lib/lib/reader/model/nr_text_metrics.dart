import 'package:flutter_lib/interface/debug_info_provider.dart';

class NRTextMetrics with DebugInfoProvider {
  int get dpi => _dpi;
  final int _dpi;

  int get fullWidth => _fullWidth;
  final int _fullWidth;

  int get fullHeight => _fullHeight;
  final int _fullHeight;

  int get fontSize => _fontSize;
  final int _fontSize;

  NRTextMetrics(int dpi, int fullWidth, int fullHeight, int fontSize)
      : _dpi = dpi,
        _fullWidth = fullWidth,
        _fullHeight = fullHeight,
        _fontSize = fontSize;

  NRTextMetrics.fromJson(Map<String, dynamic> json)
      : _dpi = json['DPI'],
        _fullWidth = json['FullWidth'],
        _fullHeight = json['FullHeight'],
        _fontSize = json['FontSize'];

  @override
  bool operator ==(Object other) {
    if (other is! NRTextMetrics) {
      return false;
    }
    return _dpi == other.dpi &&
        _fullWidth == other.fullWidth &&
        _fullHeight == other.fullHeight;
  }

  @override
  int get hashCode => _dpi + 13 * (_fullHeight + 13 * _fullWidth);

  @override
  void debugFillDescription(List<String> description) {
    description.add("dpi: $_dpi");
    description.add("fullWidth: $_fullWidth");
    description.add("fullHeight: $_fullHeight");
    description.add("fontSize: $_fontSize");
  }
}
