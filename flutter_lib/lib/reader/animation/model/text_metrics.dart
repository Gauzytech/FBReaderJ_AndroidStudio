class TextMetrics {
  int get dpi => _dpi;
  final int _dpi;

  int get fullWidth => _fullWidth;
  final int _fullWidth;

  int get fullHeight => _fullHeight;
  final int _fullHeight;

  final int _fontSize;

  TextMetrics(int dpi, int fullWidth, int fullHeight, int fontSize)
      : _dpi = dpi,
        _fullWidth = fullWidth,
        _fullHeight = fullHeight,
        _fontSize = fontSize;

  @override
  bool operator ==(Object other) {
    if (other == this) {
      return true;
    }
    if (other is! TextMetrics) {
      return false;
    }
    return _dpi == other.dpi &&
        _fullWidth == other.fullWidth &&
        _fullHeight == other.fullHeight;
  }

  @override
  int get hashCode => _dpi + 13 * (_fullHeight + 13 * _fullWidth);
}
