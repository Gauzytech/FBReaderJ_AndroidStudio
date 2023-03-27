import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_decorated_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_hyper_link.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_ng_style_description.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_style_entry.dart';
import 'package:flutter_lib/reader/animation/model/text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

class ContentTextNGStyle extends NRTextDecoratedStyle {
  final ContentTextNGStyleDescription _myDescription;

  ContentTextNGStyle(NRTextStyle parent,
      ContentTextNGStyleDescription description, NRTextHyperLink hyperlink)
      : _myDescription = description,
        super(parent, hyperlink);

  ContentTextNGStyle.fromJson(Map<String, dynamic> json)
      : _myDescription = json['myDescription'],
        super.fromJson(json);

  @override
  List<FontEntry> getFontEntriesInternal() {
    final List<FontEntry> parentEntries = parent.getFontEntries();
    final String decoratedValue = _myDescription.fontFamilyOption.getValue();
    if ("" == decoratedValue) {
      return parentEntries;
    }
    // final FontEntry e = FontEntry.systemEntry(decoratedValue);
    // if (parentEntries.isNotEmpty && e == parentEntries[0]) {
    //   return parentEntries;
    // }
    final List<FontEntry> entries = [];
    // entries.add(e);
    entries.addAll(parentEntries);
    return entries;
  }

  @override
  int getFontSizeInternal(TextMetrics metrics) {
    return _myDescription.getFontSize(metrics, parent.getFontSize(metrics));
  }

  @override
  bool isBoldInternal() {
    if (_myDescription.isBold() == Boolean3.TRUE) {
      return true;
    } else if (_myDescription.isBold() == Boolean3.FALSE) {
      return false;
    } else {
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
  int getLeftMarginInternal(TextMetrics metrics, int fontSize) {
    return _myDescription.getLeftMargin(
        metrics, parent.getLeftMargin(metrics), fontSize);
  }

  @override
  int getRightMarginInternal(TextMetrics metrics, int fontSize) {
    return _myDescription.getRightMargin(
        metrics, parent.getRightMargin(metrics), fontSize);
  }

  @override
  int getLeftPaddingInternal(TextMetrics metrics, int fontSize) {
    return _myDescription.getLeftPadding(
        metrics, parent.getLeftPadding(metrics), fontSize);
  }

  @override
  int getRightPaddingInternal(TextMetrics metrics, int fontSize) {
    return _myDescription.getRightPadding(
        metrics, parent.getRightPadding(metrics), fontSize);
  }

  @override
  int getFirstLineIndentInternal(TextMetrics metrics, int fontSize) {
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
  int getVerticalAlignInternal(TextMetrics metrics, int fontSize) {
    return _myDescription.getVerticalAlign(
        metrics, parent.getVerticalAlign(metrics), fontSize);
  }

  @override
  bool isVerticallyAlignedInternal() {
    return _myDescription.hasNonZeroVerticalAlign();
  }

  @override
  int getSpaceBeforeInternal(TextMetrics metrics, int fontSize) {
    return _myDescription.getSpaceBefore(
        metrics, parent.getSpaceBefore(metrics), fontSize);
  }

  @override
  int getSpaceAfterInternal(TextMetrics metrics, int fontSize) {
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
    return "ContentTextNGStyle[${_myDescription.name}]";
  }
}
