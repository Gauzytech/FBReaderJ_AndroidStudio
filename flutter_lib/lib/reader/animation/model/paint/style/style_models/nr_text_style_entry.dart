import 'dart:core';

import 'package:flutter_lib/interface/debug_info_provider.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_css_style_entry.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_other_style_entry.dart';
import 'package:flutter_lib/reader/animation/model/nr_text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';

abstract class NRTextStyleEntry with DebugInfoProvider {
  int get depth => _depth;
  final int _depth;

  int _featureMask = 0;
  List<NRTextStyleEntryLength?> _lengths =
      List.filled(Feature.numberOfLength.id, null);

  int get alignmentType => _alignmentType;
  int _alignmentType = 0;

  List<FontEntry> get fontEntries => _fontEntries;
  List<FontEntry> _fontEntries = [];

  int _supportedFontModifiers = 0;
  int _fontModifiers = 0;

  int get verticalAlignCode => _verticalAlignCode;
  int _verticalAlignCode = 0;

  NRTextStyleEntry(int depth) : _depth = depth;

  NRTextStyleEntry.fromJson(Map<String, dynamic> json)
      : _depth = json['Depth'],
        _featureMask = json['myFeatureMask'],
        _lengths = NRTextStyleEntryLength.fromJsonList(json['myLengths']),
        _alignmentType = json['myAlignmentType'],
        _fontEntries = FontEntry.fromJsonList(json['myFontEntries']),
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

  int getLength(Feature feature, NRTextMetrics metrics, int fontSize) {
    return NRTextStyleEntryLength.compute(
        _lengths[feature.id]!, metrics, fontSize, feature);
  }

  Boolean3 getFontModifier(int modifier) {
    if ((_supportedFontModifiers & modifier) == 0) {
      return Boolean3.UNDEFINED;
    }
    return (_supportedFontModifiers & modifier) == 0
        ? Boolean3.FALSE
        : Boolean3.TRUE;
  }

  bool hasNonZeroLength(Feature feature) {
    return _lengths[feature.id]?.size != 0;
  }

  @override
  void debugFillDescription(List<String> description) {
    description.add("depth: $_depth");
    description.add("featureMask: $_featureMask");
    description.add("lengths: $_lengths");
    description.add("alignmentType: $_alignmentType");
    description.add("fontEntries: $_fontEntries");
    description.add("supportedFontModifiers: $_supportedFontModifiers");
    description.add("fontModifiers: $_fontModifiers");
    description.add("verticalAlignCode: $_verticalAlignCode");
  }
}

enum SizeUnit {
  // TODO: add IN, CM, MM, PICA ("pc", = 12 POINT)
  pixel,
  point,
  em100,
  rem100,
  ex100,
  percent;

  static SizeUnit fromIndex(int value) {
    switch (value) {
      case 1:
        return SizeUnit.point;
      case 2:
        return SizeUnit.em100;
      case 3:
        return SizeUnit.rem100;
      case 4:
        return SizeUnit.ex100;
      case 5:
        return SizeUnit.percent;
      default:
        return SizeUnit.pixel;
    }
  }
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

enum FontModifier {
  bold(1 << 0),
  italic(1 << 1),
  underline(1 << 2),
  strikeThrough(1 << 3),
  smallCaps(1 << 4),
  inherit(1 << 5),
  smaller(1 << 6),
  larger(1 << 7);

  const FontModifier(this.value);

  final int value;
}

enum Boolean3 {
  TRUE,
  FALSE,
  UNDEFINED;
}

class NRTextStyleEntryLength with DebugInfoProvider {
  int size;
  SizeUnit unit;

  NRTextStyleEntryLength({required this.size, required this.unit});

  NRTextStyleEntryLength.fromJson(Map<String, dynamic> json)
      : size = json['Size'],
        unit = SizeUnit.fromIndex(json['Unit']);

  static List<NRTextStyleEntryLength?> fromJsonList(dynamic rawData) {
    return (rawData as List)
        .map((e) => e != null ? NRTextStyleEntryLength.fromJson(e) : null)
        .toList();
  }

  static int compute(
    NRTextStyleEntryLength length,
    NRTextMetrics metrics,
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

  static int _fullSize(NRTextMetrics metrics, int fontSize, Feature feature) {
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
  void debugFillDescription(List<String> description) {
    description.add("$size.$unit");
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