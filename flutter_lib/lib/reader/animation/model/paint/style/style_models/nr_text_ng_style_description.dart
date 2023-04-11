import 'package:flutter_lib/interface/debug_info_provider.dart';
import 'package:flutter_lib/reader/animation/model/nr_text_metrics.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_style_entry.dart';

import 'options/option_string.dart';

/// 标签样式，会覆盖base节点样式
class NRTextNGStyleDescription with DebugInfoProvider {
  String name;

  OptionString fontFamilyOption;
  OptionString fontSizeOption;
  OptionString fontWeightOption;
  OptionString fontStyleOption;
  OptionString textDecorationOption;
  OptionString hyphenationOption;
  OptionString marginTopOption;
  OptionString marginBottomOption;
  OptionString marginLeftOption;
  OptionString marginRightOption;
  OptionString textIndentOption;
  OptionString alignmentOption;
  OptionString verticalAlignOption;
  OptionString lineHeightOption;

  // 标签内属性都会被一一赋值给ZLTextNGStyleDescription类的各个属性
  NRTextNGStyleDescription.fromJson(Map<String, dynamic> json)
      : name = json['Name'],
        fontFamilyOption = OptionString.fromJson(json['FontFamilyOption']),
        fontSizeOption = OptionString.fromJson(json['FontSizeOption']),
        fontWeightOption = OptionString.fromJson(json['FontWeightOption']),
        fontStyleOption = OptionString.fromJson(json['FontStyleOption']),
        textDecorationOption =
            OptionString.fromJson(json['TextDecorationOption']),
        hyphenationOption = OptionString.fromJson(json['HyphenationOption']),
        marginTopOption = OptionString.fromJson(json['MarginTopOption']),
        marginBottomOption = OptionString.fromJson(json['MarginBottomOption']),
        marginLeftOption = OptionString.fromJson(json['MarginLeftOption']),
        marginRightOption = OptionString.fromJson(json['MarginRightOption']),
        textIndentOption = OptionString.fromJson(json['TextIndentOption']),
        alignmentOption = OptionString.fromJson(json['AlignmentOption']),
        verticalAlignOption =
            OptionString.fromJson(json['VerticalAlignOption']),
        lineHeightOption = OptionString.fromJson(json['LineHeightOption']);

  static List<NRTextNGStyleDescription> fromJsonList(dynamic rawData) {
    return (rawData as List)
        .map((item) => NRTextNGStyleDescription.fromJson(item))
        .toList();
  }

  static List<NRTextNGStyleDescription?> fromJsonListNullable(dynamic rawData) {
    return (rawData as List)
        .map((item) =>
            item != null ? NRTextNGStyleDescription.fromJson(item) : null)
        .toList();
  }

  int getFontSize(NRTextMetrics metrics, int parentFontSize) {
    NRTextStyleEntryLength? length = parseLength(fontSizeOption.getValue());
    if (length == null) {
      return parentFontSize;
    }
    return NRTextStyleEntryLength.compute(
        length, metrics, parentFontSize, Feature.lengthFontSize);
  }

  int getVerticalAlign(NRTextMetrics metrics, int base, int fontSize) {
    NRTextStyleEntryLength? length =
        parseLength(verticalAlignOption.getValue());
    if (length == null) {
      return base;
    }
    return NRTextStyleEntryLength.compute(
        // TODO: add new length for vertical alignment
        length,
        metrics,
        fontSize,
        Feature.lengthFontSize);
  }

  bool hasNonZeroVerticalAlign() {
    NRTextStyleEntryLength? length =
        parseLength(verticalAlignOption.getValue());
    return length != null && length.size != 0;
  }

  int getLeftMargin(NRTextMetrics metrics, int base, int fontSize) {
    NRTextStyleEntryLength? length = parseLength(marginLeftOption.getValue());
    if (length == null) {
      return base;
    }
    return base +
        NRTextStyleEntryLength.compute(
            length, metrics, fontSize, Feature.lengthMarginLeft);
  }

  int getRightMargin(NRTextMetrics metrics, int base, int fontSize) {
    NRTextStyleEntryLength? length = parseLength(marginRightOption.getValue());
    if (length == null) {
      return base;
    }
    return base +
        NRTextStyleEntryLength.compute(
            length, metrics, fontSize, Feature.lengthMarginRight);
  }

  int getLeftPadding(NRTextMetrics metrics, int base, int fontSize) {
    return base;
  }

  int getRightPadding(NRTextMetrics metrics, int base, int fontSize) {
    return base;
  }

  int getFirstLineIndent(NRTextMetrics metrics, int base, int fontSize) {
    NRTextStyleEntryLength? length = parseLength(textIndentOption.getValue());
    if (length == null) {
      return base;
    }
    return NRTextStyleEntryLength.compute(
        length, metrics, fontSize, Feature.lengthFirstLineIndent);
  }

  int getSpaceBefore(NRTextMetrics metrics, int base, int fontSize) {
    NRTextStyleEntryLength? length = parseLength(marginTopOption.getValue());
    if (length == null) {
      return base;
    }
    return NRTextStyleEntryLength.compute(
        length, metrics, fontSize, Feature.lengthSpaceBefore);
  }

  int getSpaceAfter(NRTextMetrics metrics, int base, int fontSize) {
    NRTextStyleEntryLength? length = parseLength(marginBottomOption.getValue());
    if (length == null) {
      return base;
    }
    return NRTextStyleEntryLength.compute(
        length, metrics, fontSize, Feature.lengthSpaceAfter);
  }

  Boolean3 isBold() {
    switch (fontWeightOption.getValue()) {
      case 'bold':
        return Boolean3.TRUE;
      case 'normal':
        return Boolean3.FALSE;
      default:
        return Boolean3.UNDEFINED;
    }
  }

  Boolean3 isItalic() {
    switch (fontStyleOption.getValue()) {
      case 'italic':
      case 'oblique':
        return Boolean3.TRUE;
      case 'normal':
        return Boolean3.FALSE;
      default:
        return Boolean3.UNDEFINED;
    }
  }

  Boolean3 isUnderline() {
    switch (fontWeightOption.getValue()) {
      case 'underline':
        return Boolean3.TRUE;
      case 'inherit':
      case '':
        return Boolean3.UNDEFINED;
      default:
        return Boolean3.FALSE;
    }
  }

  Boolean3 isStrikeThrough() {
    switch (textDecorationOption.getValue()) {
      case 'line-through':
        return Boolean3.TRUE;
      case 'inherit':
      case '':
        return Boolean3.UNDEFINED;
      default:
        return Boolean3.FALSE;
    }
  }

  int getAlignment() {
    String alignment = alignmentOption.getValue();
    if (alignment.isEmpty) {
      return ContentTextAlignmentType.alignUndefined.index;
    }

    switch (alignment) {
      case 'center':
        return ContentTextAlignmentType.alignCenter.index;
      case 'left':
        return ContentTextAlignmentType.alignLeft.index;
      case 'right':
        return ContentTextAlignmentType.alignRight.index;
      case 'justify':
        return ContentTextAlignmentType.alignJustify.index;
      default:
        return ContentTextAlignmentType.alignUndefined.index;
    }
  }

  Boolean3 allowHyphenations() {
    switch (hyphenationOption.getValue()) {
      case 'auto':
        return Boolean3.TRUE;
      case 'none':
        return Boolean3.FALSE;
      default:
        return Boolean3.UNDEFINED;
    }
  }

  final Map<String, NRTextStyleEntryLength> _lengthCache = {};

  NRTextStyleEntryLength? parseLength(String value) {
    if (value.isEmpty) {
      return null;
    }

    NRTextStyleEntryLength? cacheValue = _lengthCache[value];
    if (cacheValue != null) {
      return cacheValue;
    }

    NRTextStyleEntryLength? length;
    if (value.endsWith("%")) {
      length = NRTextStyleEntryLength(
          size: int.parse(value.substring(0, value.length - 1)),
          unit: SizeUnit.percent);
    } else if (value.endsWith("rem")) {
      length = NRTextStyleEntryLength(
          size: (100 * double.parse(value.substring(0, value.length - 2)))
              .toInt(),
          unit: SizeUnit.rem100);
    } else if (value.endsWith("em")) {
      length = NRTextStyleEntryLength(
          size: (100 * double.parse(value.substring(0, value.length - 2)))
              .toInt(),
          unit: SizeUnit.em100);
    } else if (value.endsWith("ex")) {
      length = NRTextStyleEntryLength(
          size: (100 * double.parse(value.substring(0, value.length - 2)))
              .toInt(),
          unit: SizeUnit.ex100);
    } else if (value.endsWith("px")) {
      length = NRTextStyleEntryLength(
          size: int.parse(value.substring(0, value.length - 2)),
          unit: SizeUnit.pixel);
    } else if (value.endsWith("pt")) {
      length = NRTextStyleEntryLength(
          size: int.parse(value.substring(0, value.length - 2)),
          unit: SizeUnit.point);
    }

    if (length != null) {
      _lengthCache[value] = length;
    }
    return length;
  }

  @override
  void debugFillDescription(List<String> description) {
    description.add("$runtimeType");
    description.add("name: $name");
    description.add("fontFamilyOption: $fontFamilyOption");
    description.add("fontSizeOption: $fontSizeOption");
    description.add("fontWeightOption: $fontWeightOption");
    description.add("fontStyleOption: $fontStyleOption");
    description.add("textDecorationOption: $textDecorationOption");
    description.add("hyphenationOption: $hyphenationOption");
    description.add("marginTopOption: $marginTopOption");
    description.add("marginBottomOption: $marginBottomOption");
    description.add("marginLeftOption: $marginLeftOption");
    description.add("marginRightOption: $marginRightOption");
    description.add("alignmentOption: $alignmentOption");
    description.add("verticalAlignOption: $verticalAlignOption");
    description.add("lineHeightOption: $lineHeightOption");
  }
}
