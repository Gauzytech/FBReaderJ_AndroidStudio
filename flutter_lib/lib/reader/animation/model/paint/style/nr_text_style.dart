import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_base_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_hyper_link.dart';
import 'package:flutter_lib/reader/animation/model/text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

abstract class NRTextStyle {
  late NRTextStyle parent;
  late NRTextHyperLink hyperlink;

  NRTextStyle(
    NRTextStyle? textStyle,
    NRTextHyperLink hyperLink,
  ) {
    parent = textStyle ?? this;
    hyperlink = hyperLink;
  }

  NRTextStyle.fromJson(Map<String, dynamic> json)
      : parent = NRTextStyle.create(json['Parent']),
        hyperlink = NRTextHyperLink.fromJson(json['Hyperlink']);

  static NRTextStyle create(Map<String, dynamic> json) {
    String className = json['className'];
    switch(className) {
      case 'TextBaseStyle':
        return NRTextBaseStyle.fromJson(json);
    }
    throw Exception('Unknown class name: $className');
  }

  List<FontEntry> getFontEntries();

  int getFontSize(TextMetrics metrics);

  bool isBold();

  bool isItalic();

  bool isUnderline();

  bool isStrikeThrough();

  bool isVerticallyAligned();

  int getLeftIndent(TextMetrics metrics) {
    return getLeftMargin(metrics) + getLeftPadding(metrics);
  }

  int getRightIndent(TextMetrics metrics) {
    return getRightMargin(metrics) + getRightPadding(metrics);
  }

  int getLeftMargin(TextMetrics metrics);

  int getRightMargin(TextMetrics metrics);

  int getLeftPadding(TextMetrics metrics);

  int getRightPadding(TextMetrics metrics);

  int getFirstLineIndent(TextMetrics metrics);

  int getLineSpacePercent();

  int getVerticalAlign(TextMetrics metrics);

  int getSpaceBefore(TextMetrics metrics);

  int getSpaceAfter(TextMetrics metrics);

  int getAlignment();

  /// 允许自动断字
  bool allowHyphenations();
}
