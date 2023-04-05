class NRTextMetrics {
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
    if (other == this) {
      return true;
    }
    if (other is! NRTextMetrics) {
      return false;
    }
    return _dpi == other.dpi &&
        _fullWidth == other.fullWidth &&
        _fullHeight == other.fullHeight;
  }

  @override
  int get hashCode => _dpi + 13 * (_fullHeight + 13 * _fullWidth);
}
