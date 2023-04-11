import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_decorated_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_hyper_link.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_ng_style_description.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_style_entry.dart';
import 'package:flutter_lib/reader/animation/model/nr_text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

class NRTextNGStyle extends NRTextDecoratedStyle {
  final NRTextNGStyleDescription _myDescription;

  NRTextNGStyle(
    NRTextStyle parent,
    NRTextNGStyleDescription description,
    NRTextHyperLink hyperlink,
  )   : _myDescription = description,
        super(parent, hyperlink);

  NRTextNGStyle.fromJson(Map<String, dynamic> json)
      : _myDescription =
            NRTextNGStyleDescription.fromJson(json['myDescription']),
        super.fromJson(json);

  @override
  List<FontEntry> getFontEntriesInternal() {
    final List<FontEntry> parentEntries = parent.getFontEntries();
    final String decoratedValue = _myDescription.fontFamilyOption.getValue();
    if (decoratedValue == '') {
      return parentEntries;
    }

    final FontEntry e = FontEntry.systemEntry(decoratedValue);
    if (parentEntries.isNotEmpty && e == parentEntries[0]) {
      return parentEntries;
    }
    final List<FontEntry> entries = [];
    entries.add(e);
    entries.addAll(parentEntries);
    return entries;
  }

  @override
  int getFontSizeInternal(NRTextMetrics metrics) =>
      _myDescription.getFontSize(metrics, parent.getFontSize(metrics));

  @override
  bool isBoldInternal() {
    switch(_myDescription.isBold()) {
      case Boolean3.TRUE:
        return true;
      case Boolean3.FALSE:
        return false;
      default:
        return parent.isBold();
    }
  }

  @override
  bool isItalicInternal() {
    if (_myDescription.isItalic() == Boolean3.TRUE) {
      return true;
    } else if (_myDescription.isItalic() == Boolean3.FALSE) {
      return false;
    } else {
      return parent.isItalic();
    }
  }

  @override
  bool isUnderlineInternal() {
    if (_myDescription.isUnderline() == Boolean3.TRUE) {
      return true;
    } else if (_myDescription.isUnderline() == Boolean3.FALSE) {
      return false;
    } else {
      return parent.isUnderline();
    }
  }

  @override
  bool isStrikeThroughInternal() {
    if (_myDescription.isStrikeThrough() == Boolean3.TRUE) {
      return true;
    } else if (_myDescription.isStrikeThrough() == Boolean3.FALSE) {
      return false;
    } else {
      return parent.isStrikeThrough();
    }
  }

  @override
  int getLeftMarginInternal(NRTextMetrics metrics, int fontSize) {
    return _myDescription.getLeftMargin(
        metrics, parent.getLeftMargin(metrics), fontSize);
  }

  @override
  int getRightMarginInternal(NRTextMetrics metrics, int fontSize) {
    return _myDescription.getRightMargin(
        metrics, parent.getRightMargin(metrics), fontSize);
  }

  @override
  int getLeftPaddingInternal(NRTextMetrics metrics, int fontSize) {
    return _myDescription.getLeftPadding(
        metrics, parent.getLeftPadding(metrics), fontSize);
  }

  @override
  int getRightPaddingInternal(NRTextMetrics metrics, int fontSize) {
    return _myDescription.getRightPadding(
        metrics, parent.getRightPadding(metrics), fontSize);
  }

  @override
  int getFirstLineIndentInternal(NRTextMetrics metrics, int fontSize) {
    return _myDescription.getFirstLineIndent(
        metrics, parent.getFirstLineIndent(metrics), fontSize);
  }

  @override
  int getLineSpacePercentInternal() {
    final String lineHeight = _myDescription.lineHeightOption.getValue();
    RegExp reg = RegExp('[1-9][0-9]*%');
    if (!reg.hasMatch(lineHeight)) {
      return parent.getLineSpacePercent();
    }
    return int.parse(lineHeight.substring(0, lineHeight.length - 1));
  }

  @override
  int getVerticalAlignInternal(NRTextMetrics metrics, int fontSize) {
    return _myDescription.getVerticalAlign(
        metrics, parent.getVerticalAlign(metrics), fontSize);
  }

  @override
  bool isVerticallyAlignedInternal() {
    return _myDescription.hasNonZeroVerticalAlign();
  }

  @override
  int getSpaceBeforeInternal(NRTextMetrics metrics, int fontSize) {
    return _myDescription.getSpaceBefore(
        metrics, parent.getSpaceBefore(metrics), fontSize);
  }

  @override
  int getSpaceAfterInternal(NRTextMetrics metrics, int fontSize) {
    return _myDescription.getSpaceAfter(
        metrics, parent.getSpaceAfter(metrics), fontSize);
  }

  @override
  int getAlignment() {
    final int defined = _myDescription.getAlignment();
    if (defined != ContentTextAlignmentType.alignUndefined.index) {
      return defined;
    }
    return parent.getAlignment();
  }

  @override
  bool allowHyphenations() {
    if (_myDescription.allowHyphenations() == Boolean3.TRUE) {
      return true;
    } else if (_myDescription.allowHyphenations() == Boolean3.FALSE) {
      return false;
    } else {
      return parent.allowHyphenations();
    }
  }

  @override
  String toString() {
    return "NRTextNGStyle[${_myDescription.name}]";
  }
}
