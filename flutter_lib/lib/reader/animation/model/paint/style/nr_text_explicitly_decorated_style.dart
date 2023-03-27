import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_decorated_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_css_style_entry.dart';
import 'package:flutter_lib/reader/animation/model/text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

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
  int getFontSizeInternal(TextMetrics metrics) {
    if (_entry is NRTextCSSStyleEntry &&
        !baseStyle.useCSSFontSizeOption.getValue()) {
      return parent.getFontSize(metrics);
    }

    // final int baseFontSize = getTreeParent().getFontSize(metrics);
    // if (_entry.isFeatureSupported(Feature.fontStyleModifier.id)) {
    //   if (_entry.getFontModifier(Feature.FONT_MODIFIER_INHERIT) ==
    //       Boolean3.TRUE) {
    //     return baseFontSize;
    //   }
    //   if (_entry.getFontModifier(FONT_MODIFIER_LARGER) == Boolean3.TRUE) {
    //     return baseFontSize * 120 ~/ 100;
    //   }
    //   if (_entry.getFontModifier(FONT_MODIFIER_SMALLER) == Boolean3.TRUE) {
    //     return baseFontSize * 100 ~/ 120;
    //   }
    // }
    // if (_entry.isFeatureSupported(Feature.lengthFontSize.id)) {
    //   return _entry.getLength(Feature.lengthFontSize, metrics, baseFontSize);
    // }
    return parent.getFontSize(metrics);
  }
}
