import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_base_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_hyper_link.dart';
import 'package:flutter_lib/reader/animation/model/text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

abstract class NRTextDecoratedStyle extends NRTextStyle {
  // fields to be cached
  late NRTextBaseStyle baseStyle;

  List<FontEntry> _fontEntries = [];
  bool _isItalic = false;
  bool _isBold = false;
  bool _isUnderline = false;
  bool _isStrikeThrough = false;
  int _lineSpacePercent = 0;

  bool _isNotCached = true;

  int _myFontSize = 0;
  int _mySpaceBefore = 0;
  int _mySpaceAfter = 0;
  int _myVerticalAlign = 0;
  bool? _myIsVerticallyAligned;
  int _myLeftMargin = 0;
  int _myRightMargin = 0;
  int _myLeftPadding = 0;
  int _myRightPadding = 0;
  int _myFirstLineIndent = 0;
  late TextMetrics _myMetrics;

  NRTextDecoratedStyle(
    NRTextStyle base,
    NRTextHyperLink? hyperlink,
  )   : // 缓存上一层级的base style
        baseStyle = base is NRTextBaseStyle
            ? base
            : (base as NRTextDecoratedStyle).baseStyle,
        super(base, hyperlink ?? base.hyperlink);

  NRTextDecoratedStyle.fromJson(Map<String, dynamic> json)
      : baseStyle = NRTextBaseStyle.fromJson(json['BaseStyle']),
        _fontEntries = FontEntry.fromJsonList(json['myFontEntries']),
        _isItalic = json['myIsItalic'],
        _isBold = json['myIsBold'],
        _isUnderline = json['myIsUnderline'],
        _isStrikeThrough = json['myIsStrikeThrough'],
        _lineSpacePercent = json['myLineSpacePercent'],
        _isNotCached = json['myIsNotCached'],
        _myFontSize = json['myFontSize'],
        _mySpaceBefore = json['mySpaceBefore'],
        _mySpaceAfter = json['mySpaceAfter'],
        _myVerticalAlign = json['myVerticalAlign'],
        _myIsVerticallyAligned = json['myIsVerticallyAligned'],
        _myLeftMargin = json['myLeftMargin'],
        _myRightMargin = json['myRightMargin'],
        _myLeftPadding = json['myLeftPadding'],
        _myRightPadding = json['myRightPadding'],
        _myFirstLineIndent = json['myFirstLineIndent'],
        _myMetrics = TextMetrics.fromJson(json['myMetrics']),
        super.fromJson(json);

  void _initCache() {
    _fontEntries = getFontEntriesInternal();
    _isItalic = isItalicInternal();
    _isBold = isBoldInternal();
    _isUnderline = isUnderlineInternal();
    _isStrikeThrough = isStrikeThroughInternal();
    _lineSpacePercent = getLineSpacePercentInternal();

    _isNotCached = false;
  }

  void _initMetricsCache(TextMetrics metrics) {
    _myMetrics = metrics;
    _myFontSize = getFontSizeInternal(metrics);
    _mySpaceBefore = getSpaceBeforeInternal(metrics, _myFontSize);
    _mySpaceAfter = getSpaceAfterInternal(metrics, _myFontSize);
    _myVerticalAlign = getVerticalAlignInternal(metrics, _myFontSize);
    _myLeftMargin = getLeftMarginInternal(metrics, _myFontSize);
    _myRightMargin = getRightMarginInternal(metrics, _myFontSize);
    _myLeftPadding = getLeftPaddingInternal(metrics, _myFontSize);
    _myRightPadding = getRightPaddingInternal(metrics, _myFontSize);
    _myFirstLineIndent = getFirstLineIndentInternal(metrics, _myFontSize);
  }

  @override
  List<FontEntry> getFontEntries() {
    if (_isNotCached) {
      _initCache();
    }
    return _fontEntries;
  }

  @override
  int getFontSize(TextMetrics metrics) {
    if (metrics != _myMetrics) {
      _initMetricsCache(metrics);
    }
    return _myFontSize;
  }

  @override
  int getSpaceBefore(TextMetrics metrics) {
    if (metrics != _myMetrics) {
      _initMetricsCache(metrics);
    }
    return _mySpaceBefore;
  }

  @override
  int getSpaceAfter(TextMetrics metrics) {
    if (metrics != _myMetrics) {
      _initMetricsCache(metrics);
    }
    return _mySpaceAfter;
  }

  @override
  bool isItalic() {
    if (_isNotCached) {
      _initCache();
    }
    return _isItalic;
  }

  @override
  bool isBold() {
    if (_isNotCached) {
      _initCache();
    }
    return _isBold;
  }

  @override
  bool isUnderline() {
    if (_isNotCached) {
      _initCache();
    }
    return _isUnderline;
  }

  @override
  bool isStrikeThrough() {
    if (_isNotCached) {
      _initCache();
    }
    return _isStrikeThrough;
  }

  @override
  int getVerticalAlign(TextMetrics metrics) {
    if (metrics != _myMetrics) {
      _initMetricsCache(metrics);
    }
    return _myVerticalAlign;
  }

  @override
  bool isVerticallyAligned() {
    _myIsVerticallyAligned ??=
        parent.isVerticallyAligned() || isVerticallyAlignedInternal();
    return _myIsVerticallyAligned!;
  }

  @override
  int getLeftMargin(TextMetrics metrics) {
    if (metrics != _myMetrics) {
      _initMetricsCache(metrics);
    }
    return _myLeftMargin;
  }

  @override
  int getRightMargin(TextMetrics metrics) {
    if (metrics != _myMetrics) {
      _initMetricsCache(metrics);
    }
    return _myRightMargin;
  }

  @override
  int getLeftPadding(TextMetrics metrics) {
    if (metrics != _myMetrics) {
      _initMetricsCache(metrics);
    }
    return _myLeftPadding;
  }

  @override
  int getRightPadding(TextMetrics metrics) {
    if (metrics != _myMetrics) {
      _initMetricsCache(metrics);
    }
    return _myRightPadding;
  }

  @override
  int getFirstLineIndent(TextMetrics metrics) {
    if (metrics != _myMetrics) {
      _initMetricsCache(metrics);
    }
    return _myFirstLineIndent;
  }

  @override
  int getLineSpacePercent() {
    if (_isNotCached) {
      _initCache();
    }
    return _lineSpacePercent;
  }

  List<FontEntry> getFontEntriesInternal();

  int getFontSizeInternal(TextMetrics metrics);

  int getSpaceBeforeInternal(TextMetrics metrics, int fontSize);

  int getSpaceAfterInternal(TextMetrics metrics, int fontSize);

  bool isItalicInternal();

  bool isBoldInternal();

  bool isUnderlineInternal();

  bool isStrikeThroughInternal();

  int getVerticalAlignInternal(TextMetrics metrics, int fontSize);

  bool isVerticallyAlignedInternal();

  int getLeftMarginInternal(TextMetrics metrics, int fontSize);

  int getRightMarginInternal(TextMetrics metrics, int fontSize);

  int getLeftPaddingInternal(TextMetrics metrics, int fontSize);

  int getRightPaddingInternal(TextMetrics metrics, int fontSize);

  int getFirstLineIndentInternal(TextMetrics metrics, int fontSize);

  int getLineSpacePercentInternal();
}
