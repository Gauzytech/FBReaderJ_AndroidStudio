
import 'package:flutter_lib/reader/model/nr_text_metrics.dart';
import 'package:flutter_lib/reader/model/paint/style/nr_text_decorated_style.dart';
import 'package:flutter_lib/reader/model/paint/style/nr_text_style.dart';
import 'package:flutter_lib/reader/model/paint/style/style_models/nr_text_css_style_entry.dart';
import 'package:flutter_lib/reader/model/user_settings/font_entry.dart';

import 'style_models/nr_text_style_entry.dart';

class NRTextExplicitlyDecoratedStyle extends NRTextDecoratedStyle {
  final NRTextStyleEntry _entry;
  NRTextStyle? _treeParent;

  NRTextExplicitlyDecoratedStyle.fromJson(Map<String, dynamic> json)
      : _entry = NRTextStyleEntry.create(json['myEntry']),
        _treeParent = NRTextStyle.create(json['myTreeParent']),
        super.fromJson(json);

  @override
  List<FontEntry> getFontEntriesInternal() {
    final List<FontEntry> parentEntries = parent.getFontEntries();
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSFontFamilyOption.getValue()) {
      return parentEntries;
    }

    if (!_entry.isFeatureSupported(Feature.fontFamily.id)) {
      return parentEntries;
    }

    final List<FontEntry> entries = _entry.fontEntries;
    final int lSize = entries.length;
    if (lSize == 0) {
      return parentEntries;
    }

    final int pSize = parentEntries.length;
    if (pSize > lSize && entries == parentEntries.sublist(0, lSize)) {
      return parentEntries;
    }

    final List<FontEntry> allEntries = [];
    allEntries.addAll(entries);
    allEntries.addAll(parentEntries);
    return allEntries;
  }

  NRTextStyle _computeTreeParent() {
    if (_entry.depth == 0) {
      return parent.parent;
    }
    int count = 0;
    NRTextStyle p = parent;
    for (; p != p.parent; p = p.parent) {
      if (p is NRTextExplicitlyDecoratedStyle) {
        if (p._entry.depth != _entry.depth) {
          return p;
        }
      } else {
        if (++count > 1) {
          return p;
        }
      }
    }
    return p;
  }

  NRTextStyle getTreeParent() {
    _treeParent ??= _computeTreeParent();
    return _treeParent!;
  }

  @override
  int getFontSizeInternal(NRTextMetrics metrics) {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSFontSizeOption.getValue()) {
      return parent.getFontSize(metrics);
    }

    final int baseFontSize = getTreeParent().getFontSize(metrics);
    if (_entry.isFeatureSupported(Feature.fontStyleModifier.id)) {
      if (_entry.getFontModifier(FontModifier.inherit.value) == Boolean3.TRUE) {
        return baseFontSize;
      }
      if (_entry.getFontModifier(FontModifier.larger.value) == Boolean3.TRUE) {
        return baseFontSize * 120 ~/ 100;
      }
      if (_entry.getFontModifier(FontModifier.smaller.value) == Boolean3.TRUE) {
        return baseFontSize * 100 ~/ 120;
      }
    }
    if (_entry.isFeatureSupported(Feature.lengthFontSize.id)) {
      return _entry.getLength(Feature.lengthFontSize, metrics, baseFontSize);
    }
    return parent.getFontSize(metrics);
  }

  @override
  bool isBoldInternal() {
    switch (_entry.getFontModifier(FontModifier.bold.value)) {
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
    switch (_entry.getFontModifier(FontModifier.italic.value)) {
      case Boolean3.TRUE:
        return true;
      case Boolean3.FALSE:
        return false;
      default:
        return parent.isItalic();
    }
  }

  @override
  bool isUnderlineInternal() {
    switch (_entry.getFontModifier(FontModifier.underline.value)) {
      case Boolean3.TRUE:
        return true;
      case Boolean3.FALSE:
        return false;
      default:
        return parent.isUnderline();
    }
  }

  @override
  bool isStrikeThroughInternal() {
    switch (_entry.getFontModifier(FontModifier.strikeThrough.value)) {
      case Boolean3.TRUE:
        return true;
      case Boolean3.FALSE:
        return false;
      default:
        return parent.isStrikeThrough();
    }
  }

  @override
  int getLeftMarginInternal(NRTextMetrics metrics, int fontSize) {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSMarginsOption.getValue()) {
      return parent.getLeftMargin(metrics);
    }

    if (!_entry.isFeatureSupported(Feature.lengthMarginLeft.id)) {
      return parent.getLeftMargin(metrics);
    }
    return getTreeParent().getLeftMargin(metrics) +
        _entry.getLength(Feature.lengthMarginLeft, metrics, fontSize);
  }

  @override
  int getRightMarginInternal(NRTextMetrics metrics, int fontSize) {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSMarginsOption.getValue()) {
      return parent.getRightMargin(metrics);
    }

    if (!_entry.isFeatureSupported(Feature.lengthMarginRight.id)) {
      return parent.getRightMargin(metrics);
    }
    return getTreeParent().getRightMargin(metrics) +
        _entry.getLength(Feature.lengthMarginRight, metrics, fontSize);
  }

  @override
  int getLeftPaddingInternal(NRTextMetrics metrics, int fontSize) {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSMarginsOption.getValue()) {
      return parent.getLeftPadding(metrics);
    }

    if (!_entry.isFeatureSupported(Feature.lengthPaddingLeft.id)) {
      return parent.getLeftPadding(metrics);
    }
    return getTreeParent().getLeftPadding(metrics) +
        _entry.getLength(Feature.lengthPaddingLeft, metrics, fontSize);
  }

  @override
  int getRightPaddingInternal(NRTextMetrics metrics, int fontSize) {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSMarginsOption.getValue()) {
      return parent.getRightPadding(metrics);
    }

    if (!_entry.isFeatureSupported(Feature.lengthPaddingRight.id)) {
      return parent.getRightPadding(metrics);
    }
    return getTreeParent().getRightPadding(metrics) +
        _entry.getLength(Feature.lengthPaddingRight, metrics, fontSize);
  }

  @override
  int getFirstLineIndentInternal(NRTextMetrics metrics, int fontSize) {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSMarginsOption.getValue()) {
      return parent.getFirstLineIndent(metrics);
    }

    if (!_entry.isFeatureSupported(Feature.lengthFirstLineIndent.id)) {
      return parent.getFirstLineIndent(metrics);
    }
    return _entry.getLength(Feature.lengthFirstLineIndent, metrics, fontSize);
  }

  @override
  int getLineSpacePercentInternal() {
    // TODO: implement
    return parent.getLineSpacePercent();
  }

  @override
  int getVerticalAlignInternal(NRTextMetrics metrics, int fontSize) {
    // TODO: implement
    if (_entry.isFeatureSupported(Feature.lengthVerticalAlign.id)) {
      return _entry.getLength(Feature.lengthVerticalAlign, metrics, fontSize);
    } else if (_entry.isFeatureSupported(Feature.nonLengthVerticalAlign.id)) {
      switch (_entry.verticalAlignCode) {
        case 0: // sub
          return NRTextStyleEntryLength.compute(
            NRTextStyleEntryLength(size: -50, unit: SizeUnit.em100),
            metrics,
            fontSize,
            Feature.lengthVerticalAlign,
          );
        case 1: // super
          return NRTextStyleEntryLength.compute(
            NRTextStyleEntryLength(size: 50, unit: SizeUnit.em100),
            metrics,
            fontSize,
            Feature.lengthVerticalAlign,
          );
        default:
          return parent.getVerticalAlign(metrics);
        /*
				case 2: // top
					return 0;
				case 3: // text-top
					return 0;
				case 4: // middle
					return 0;
				case 5: // bottom
					return 0;
				case 6: // text-bottom
					return 0;
				case 7: // initial
					return 0;
				case 8: // inherit
					return 0;
				*/
      }
    } else {
      return parent.getVerticalAlign(metrics);
    }
  }

  @override
  bool isVerticallyAlignedInternal() {
    if (_entry.isFeatureSupported(Feature.lengthVerticalAlign.id)) {
      return _entry.hasNonZeroLength(Feature.lengthVerticalAlign);
    } else if (_entry.isFeatureSupported(Feature.nonLengthVerticalAlign.id)) {
      switch (_entry.verticalAlignCode) {
        case 0: // sub
        case 1: // super
          return true;
        default:
          return false;
      }
    } else {
      return false;
    }
  }

  @override
  int getSpaceBeforeInternal(NRTextMetrics metrics, int fontSize) {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSMarginsOption.getValue()) {
      return parent.getSpaceBefore(metrics);
    }

    if (!_entry.isFeatureSupported(Feature.lengthSpaceBefore.id)) {
      return parent.getSpaceBefore(metrics);
    }
    return _entry.getLength(Feature.lengthSpaceBefore, metrics, fontSize);
  }

  @override
  int getSpaceAfterInternal(NRTextMetrics metrics, int fontSize) {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSMarginsOption.getValue()) {
      return parent.getSpaceAfter(metrics);
    }

    if (!_entry.isFeatureSupported(Feature.lengthSpaceAfter.id)) {
      return parent.getSpaceAfter(metrics);
    }
    return _entry.getLength(Feature.lengthSpaceAfter, metrics, fontSize);
  }

  @override
  int getAlignment() {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSTextAlignmentOption.getValue()) {
      return parent.getAlignment();
    }
    return _entry.isFeatureSupported(Feature.alignmentType.id)
        ? _entry.alignmentType
        : parent.getAlignment();
  }

  @override
  bool allowHyphenations() => parent.allowHyphenations();

  @override
  String toString() {
    return "ZLTextExplicitlyDecoratedStyle{" +
        "myEntry= $_entry"  +
        ", myTreeParent= $_treeParent" +
        '}';
  }
}
