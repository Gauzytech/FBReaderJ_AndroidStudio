import 'package:flutter_lib/reader/animation/model/paint/style/content_text_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/option_boolean.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/option_integer_range.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/option_string.dart';
import 'package:flutter_lib/reader/animation/model/text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

class ContentTextBaseStyle extends ContentTextStyle {
  static const String _group = "Style";
  static const String _options = "Options";

  final OptionBoolean useCSSTextAlignmentOption =
      OptionBoolean(_group, "css:textAlignment", true);

  final OptionBoolean useCSSMarginsOption =
      OptionBoolean(_group, "css:margins", true);

  final OptionBoolean useCSSFontSizeOption =
      OptionBoolean(_group, "css:fontSize", true);

  final OptionBoolean useCSSFontFamilyOption =
      OptionBoolean(_group, "css:fontFamily", true);

  final OptionBoolean autoHyphenationOption =
      OptionBoolean(_options, "AutoHyphenation", true);

  final OptionBoolean boldOption;
  final OptionBoolean italicOption;
  final OptionBoolean underlineOption;
  final OptionBoolean strikeThroughOption;
  final OptionIntegerRange alignmentOption;
  final OptionIntegerRange lineSpaceOption;

  final OptionString fontFamilyOption;
  final OptionIntegerRange fontSizeOption;

  String _fontFamily;
  final List<FontEntry> _fontEntries;

  ContentTextBaseStyle.fromJson(Map<String, dynamic> json)
      : fontFamilyOption = OptionString.fromJson(json['FontFamilyOption']),
        fontSizeOption = OptionIntegerRange.fromJson(json['FontSizeOption']),
        boldOption = OptionBoolean.fromJson(json['BoldOption']),
        italicOption = OptionBoolean.fromJson(json['ItalicOption']),
        underlineOption = OptionBoolean.fromJson(json['UnderlineOption']),
        strikeThroughOption =
            OptionBoolean.fromJson(json['StrikeThroughOption']),
        alignmentOption = OptionIntegerRange.fromJson(json['AlignmentOption']),
        lineSpaceOption = OptionIntegerRange.fromJson(json['LineSpaceOption']),
        _fontFamily = json['myFontFamily'],
        _fontEntries = (json['myFontEntries'] as List)
            .map((item) => FontEntry.fromJson(item))
            .toList(),
        super.fromJson(json);

  @override
  bool allowHyphenations() {
    return true;
  }

  @override
  List<FontEntry> get fontEntries => _fontEntries;

  @override
  int getFirstLineIndent(TextMetrics metrics) {
    return 0;
  }

  @override
  int getFontSize(TextMetrics metrics) {
    return _getFontSize();
  }

  int _getFontSize() {
    return fontSizeOption.getValue();
  }

  @override
  int getLeftMargin(TextMetrics metrics) {
    return 0;
  }

  @override
  int getLeftPadding(TextMetrics metrics) {
    return 0;
  }

  @override
  int getLineSpacePercent() {
    return lineSpaceOption.getValue() * 10;
  }

  @override
  int getRightMargin(TextMetrics metrics) {
    return 0;
  }

  @override
  int getRightPadding(TextMetrics metrics) {
    return 0;
  }

  @override
  int getSpaceAfter(TextMetrics metrics) {
    return 0;
  }

  @override
  int getSpaceBefore(TextMetrics metrics) {
    return 0;
  }

  @override
  int getVerticalAlign(TextMetrics metrics) {
    return 0;
  }

  @override
  bool get isBold => boldOption.getValue();

  @override
  bool get isItalic => italicOption.getValue();

  @override
  bool get isStrikeThrough => strikeThroughOption.getValue();

  @override
  bool get isUnderline => underlineOption.getValue();

  @override
  bool get isVerticallyAligned => false;
}
