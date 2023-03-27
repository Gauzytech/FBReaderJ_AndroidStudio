import 'dart:core';

import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_css_style_entry.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_other_style_entry.dart';
import 'package:flutter_lib/reader/animation/model/text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

abstract class NRTextStyleEntry {
  int get depth => _depth;
  int _depth;

  int _featureMask = 0;
  List<TextStyleEntryLength> _lengths = [];
  int _alignmentType = 0;

  List<FontEntry> get fontEntries => _fontEntries;
  List<FontEntry> _fontEntries = [];

  int _supportedFontModifiers = 0;
  int _fontModifiers = 0;
  int _verticalAlignCode = 0;

  NRTextStyleEntry(int depth) : _depth = depth;

  NRTextStyleEntry.fromJson(Map<String, dynamic> json)
      : _depth = json['Depth'],
        _featureMask = json['myFeatureMask'],
        _lengths = json['myLengths'],
        _alignmentType = json['myAlignmentType'],
        _fontEntries = json['myFontEntries'],
        _supportedFontModifiers = json['mySupportedFontModifiers'],
        _fontModifiers = json['myFontModifiers'],
        _verticalAlignCode = json['myVerticalAlignCode'];

  bool isFeatureSupported(int featureId) {
    return _isFeatureSupported(_featureMask, featureId);
  }

  static NRTextStyleEntry create(Map<String, dynamic> json) {
    String type = json['entryType'];
    switch (type) {
      case 'ZLTextCSSStyleEntry':
        return NRTextCSSStyleEntry.fromJson(json);
      case 'ZLTextOtherStyleEntry':
        return NRTextOtherStyleEntry.fromJson(json);
      default:
        throw Exception('Unsupported type: $type');
    }
  }

  static bool _isFeatureSupported(int mask, int featureId) {
    return (mask & (1 << featureId)) != 0;
  }

  int getLength(Feature feature, TextMetrics metrics, int fontSize) {
    return TextStyleEntryLength.compute(
        _lengths[feature.id], metrics, fontSize, feature);
  }
}

enum SizeUnit {
  // TODO: add IN, CM, MM, PICA ("pc", = 12 POINT)
  pixel,
  point,
  em100,
  rem100,
  ex100,
  percent
}

enum Feature {
  lengthPaddingLeft(0),
  lengthPaddingRight(1),
  lengthMarginLeft(2),
  lengthMarginRight(3),
  lengthFirstLineIndent(4),
  lengthSpaceBefore(5),
  lengthSpaceAfter(6),
  lengthFontSize(7),
  lengthVerticalAlign(8),
  numberOfLength(9),
  alignmentType(9),
  fontFamily(10),
  fontStyleModifier(11),
  nonLengthVerticalAlign(12),
  // not transferred at the moment
  display(13);

  const Feature(this.id);

  final int id;
}

mixin FontModifier {
  int FONT_MODIFIER_BOLD = 1 << 0;
  int FONT_MODIFIER_ITALIC = 1 << 1;
  int FONT_MODIFIER_UNDERLINED = 1 << 2;
  int FONT_MODIFIER_STRIKEDTHROUGH = 1 << 3;
  int FONT_MODIFIER_SMALLCAPS = 1 << 4;
  int FONT_MODIFIER_INHERIT = 1 << 5;
  int FONT_MODIFIER_SMALLER = 1 << 6;
  int FONT_MODIFIER_LARGER = 1 << 7;
}

enum Boolean3 {
  TRUE,
  FALSE,
  UNDEFINED;
}

// mixin SizeUnit {
//     int PIXEL                            = 0;
//     int POINT                            = 1;
//     int EM_100                           = 2;
//     int REM_100                          = 3;
//     int EX_100                           = 4;
//     int PERCENT                          = 5;
//     // TODO: add IN, CM, MM, PICA ("pc", = 12 POINT)
// }

class TextStyleEntryLength {
  int size;
  SizeUnit unit;

  TextStyleEntryLength({required this.size, required this.unit});

  static int compute(
    TextStyleEntryLength length,
    TextMetrics metrics,
    int fontSize,
    Feature feature,
  ) {
    switch (length.unit) {
      case SizeUnit.point:
        return length.size * metrics.dpi ~/ 72;
      case SizeUnit.em100:
        return (length.size * fontSize + 50) ~/ 100;
      case SizeUnit.rem100:
        return (length.size * metrics.fontSize + 50) ~/ 100;
      case SizeUnit.ex100:
        // TODO 0.5 font size => height of x
        return (length.size * fontSize / 2 + 50) ~/ 100;
      case SizeUnit.percent:
        return (length.size * _fullSize(metrics, fontSize, feature) + 50) ~/
            100;
      default:
    }
    // SizeUnit.pixel
    return length.size;
  }

  static int _fullSize(TextMetrics metrics, int fontSize, Feature feature) {
    switch (feature) {
      case Feature.lengthMarginLeft:
      case Feature.lengthMarginRight:
      case Feature.lengthPaddingLeft:
      case Feature.lengthPaddingRight:
      case Feature.lengthFirstLineIndent:
        return metrics.fullWidth;
      case Feature.lengthSpaceBefore:
      case Feature.lengthSpaceAfter:
        return metrics.fullHeight;
      case Feature.lengthVerticalAlign:
      case Feature.lengthFontSize:
        return fontSize;
      default:
        throw Exception("Unknown supported feature: $feature");
    }
  }

  @override
  String toString() {
    return "$size.$unit";
  }
}

enum ContentTextAlignmentType {
  alignUndefined,
  alignLeft,
  alignRight,
  alignCenter,
  alignJustify,
  // left for LTR languages and right for RTL
  alignLineStart;
}

//  short Depth;
//  short myFeatureMask;
//
//  Length[] myLengths = Length[Feature.NUMBER_OF_LENGTHS];
//  byte myAlignmentType;
//  List<FontEntry> myFontEntries;
//  byte mySupportedFontModifiers;
//  byte myFontModifiers;
//  byte myVerticalAlignCode;
//
// static bool isFeatureSupported(short mask, int featureId) {
// return (mask & (1 << featureId)) != 0;
// }
//
// protected ZLTextStyleEntry(short depth) {
//   Depth = depth;
// }
//
//  bool isFeatureSupported(int featureId) {
// return isFeatureSupported(myFeatureMask, featureId);
// }
//
//  setLength(int featureId, short size, byte unit) {
// myFeatureMask |= 1 << featureId;
// myLengths[featureId] = new Length(size, unit);
// }
//
//
//  int getLength(int featureId, ZLTextMetrics metrics, int fontSize) {
// return compute(myLengths[featureId], metrics, fontSize, featureId);
// }
//
//  bool hasNonZeroLength(int featureId) {
// return myLengths[featureId].Size != 0;
// }

//
//  setAlignmentType(byte alignmentType) {
// myFeatureMask |= 1 << Feature.ALIGNMENT_TYPE;
// myAlignmentType = alignmentType;
// }
//
//  byte getAlignmentType() {
// return myAlignmentType;
// }
//
//  setFontFamilies(FontManager fontManager, int fontFamiliesIndex) {
// myFeatureMask |= 1 << Feature.FONT_FAMILY;
// myFontEntries = fontManager.getFamilyEntries(fontFamiliesIndex);
// }
//
//  List<FontEntry> getFontEntries() {
// return myFontEntries;
// }
//
//  setFontModifiers(byte supported, byte values) {
// myFeatureMask |= 1 << Feature.FONT_STYLE_MODIFIER;
// mySupportedFontModifiers = supported;
// myFontModifiers = values;
// }
//
//  void setFontModifier(byte modifier, bool on) {
// myFeatureMask |= 1 << Feature.FONT_STYLE_MODIFIER;
// mySupportedFontModifiers |= modifier;
// if (on) {
// myFontModifiers |= modifier;
// } else {
// myFontModifiers &= ~modifier;
// }
// }
//
//  bool3 getFontModifier(byte modifier) {
// if ((mySupportedFontModifiers & modifier) == 0) {
// return bool3.UNDEFINED;
// }
// return (myFontModifiers & modifier) == 0 ? bool3.FALSE : bool3.TRUE;
// }
//
//  void setVerticalAlignCode(byte code) {
// myFeatureMask |= 1 << Feature.NON_LENGTH_VERTICAL_ALIGN;
// myVerticalAlignCode = code;
// }
//
//  byte getVerticalAlignCode() {
// return myVerticalAlignCode;
// }
//
// @Override
// public String toString() {
//   final StringBuilder buffer = new StringBuilder("StyleEntry[");
//   buffer.append("features: ").append(myFeatureMask).append(";");
//   if (isFeatureSupported(Feature.LENGTH_SPACE_BEFORE)) {
//     buffer.append(" ")
//         .append("space-before: ").append(myLengths[Feature.LENGTH_SPACE_BEFORE]).append(";");
//   }
//   if (isFeatureSupported(Feature.LENGTH_SPACE_AFTER)) {
//     buffer.append(" ")
//         .append("space-after: ").append(myLengths[Feature.LENGTH_SPACE_AFTER]).append(";");
//   }
//   buffer.append("]");
//   return buffer.toString();
// }
// }
