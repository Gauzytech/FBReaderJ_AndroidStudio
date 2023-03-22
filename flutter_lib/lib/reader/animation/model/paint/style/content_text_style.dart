import 'package:flutter_lib/reader/animation/model/paint/style/content_text_base_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/content_text_hyper_link.dart';
import 'package:flutter_lib/reader/animation/model/text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

abstract class ContentTextStyle {
  late ContentTextStyle _parent;
  late ContentTextHyperLink _hyperlink;

  ContentTextStyle(
    ContentTextStyle? textStyle,
    ContentTextHyperLink hyperLink,
  ) {
    _parent = textStyle ?? this;
    _hyperlink = hyperLink;
  }

  ContentTextStyle.fromJson(Map<String, dynamic> json)
      : _parent = ContentTextStyle.create(json['Parent']),
        _hyperlink = ContentTextHyperLink.fromJson(json['Hyperlink']);

  static ContentTextStyle create(Map<String, dynamic> json) {
    String className = json['className'];
    switch(className) {
      case 'TextBaseStyle':
        return ContentTextBaseStyle.fromJson(json);
    }
    throw Exception('Unknown class name: $className');
  }

  List<FontEntry> get fontEntries;

  int getFontSize(TextMetrics metrics);

  bool get isBold;

  bool get isItalic;

  bool get isUnderline;

  bool get isStrikeThrough;

  bool get isVerticallyAligned;

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

  // byte getAlignment();

  /** 允许自动断字 */
  bool allowHyphenations();
}
