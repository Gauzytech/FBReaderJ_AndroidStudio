import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_base_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_explicitly_decorated_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_ng_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_hyper_link.dart';
import 'package:flutter_lib/reader/animation/model/nr_text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

abstract class NRTextStyle {
  late NRTextStyle parent;

  NRTextHyperLink get hyperlink => _hyperlink;
  final NRTextHyperLink _hyperlink;

  NRTextStyle(
    NRTextStyle? textStyle,
    NRTextHyperLink hyperLink,
  ) : _hyperlink = hyperLink {
    parent = textStyle ?? this;
  }

  NRTextStyle.fromJson(Map<String, dynamic> json)
      : _hyperlink = NRTextHyperLink.fromJson(json['Hyperlink']) {
    parent = json['Parent'] != null ? NRTextStyle.create(json['Parent']) : this;
  }

  static NRTextStyle create(Map<String, dynamic> json) {
    String className = json['className'];
    switch (className) {
      case 'ZLTextBaseStyle':
        return NRTextBaseStyle.fromJson(json);
      case 'ZLTextExplicitlyDecoratedStyle':
        return NRTextExplicitlyDecoratedStyle.fromJson(json);
      case 'ZLTextNGStyle':
        return NRTextNGStyle.fromJson(json);
      default:
        throw Exception('Unknown class name: $className');
    }
  }

  List<FontEntry> getFontEntries();

  int getFontSize(NRTextMetrics metrics);

  bool isBold();

  bool isItalic();

  bool isUnderline();

  bool isStrikeThrough();

  bool isVerticallyAligned();

  int getLeftIndent(NRTextMetrics metrics) {
    return getLeftMargin(metrics) + getLeftPadding(metrics);
  }

  int getRightIndent(NRTextMetrics metrics) {
    return getRightMargin(metrics) + getRightPadding(metrics);
  }

  int getLeftMargin(NRTextMetrics metrics);

  int getRightMargin(NRTextMetrics metrics);

  int getLeftPadding(NRTextMetrics metrics);

  int getRightPadding(NRTextMetrics metrics);

  int getFirstLineIndent(NRTextMetrics metrics);

  int getLineSpacePercent();

  int getVerticalAlign(NRTextMetrics metrics);

  int getSpaceBefore(NRTextMetrics metrics);

  int getSpaceAfter(NRTextMetrics metrics);

  int getAlignment();

  /// 允许自动断字
  bool allowHyphenations();
}
