import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/options/option_string.dart';
import 'package:flutter_lib/reader/animation/model/nr_text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

import 'style_models/options/option_boolean.dart';
import 'style_models/options/option_integer_range.dart';

class NRTextBaseStyle extends NRTextStyle {
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

  String? _fontFamily;
  final List<FontEntry> _fontEntries;

  NRTextBaseStyle.fromJson(Map<String, dynamic> json)
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
        _fontEntries = FontEntry.fromJsonList(json['myFontEntries']),
        super.fromJson(json);

  @override
  bool allowHyphenations() {
    return true;
  }

  @override
  List<FontEntry> getFontEntries() {
    return _fontEntries;
  }

  @override
  int getFirstLineIndent(NRTextMetrics metrics) {
    return 0;
  }

  @override
  int getFontSize(NRTextMetrics metrics) {
    return getFontSize2();
  }

  int getFontSize2() {
    return fontSizeOption.getValue();
  }

  @override
  int getLeftMargin(NRTextMetrics metrics) {
    return 0;
  }

  @override
  int getLeftPadding(NRTextMetrics metrics) {
    return 0;
  }

  @override
  int getLineSpacePercent() {
    return lineSpaceOption.getValue() * 10;
  }

  @override
  int getRightMargin(NRTextMetrics metrics) {
    return 0;
  }

  @override
  int getRightPadding(NRTextMetrics metrics) {
    return 0;
  }

  @override
  int getSpaceAfter(NRTextMetrics metrics) {
    return 0;
  }

  @override
  int getSpaceBefore(NRTextMetrics metrics) {
    return 0;
  }

  @override
  int getVerticalAlign(NRTextMetrics metrics) {
    return 0;
  }

  @override
  bool isBold() {
    return boldOption.getValue();
  }

  @override
  bool isItalic() {
    return italicOption.getValue();
  }

  @override
  bool isStrikeThrough() {
    return strikeThroughOption.getValue();
  }

  @override
  bool isUnderline() {
    return underlineOption.getValue();
  }

  @override
  bool isVerticallyAligned() {
    return false;
  }

  @override
  int getAlignment() {
    return alignmentOption.getValue();
  }
}
