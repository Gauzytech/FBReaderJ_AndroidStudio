import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_style_entry.dart';
import 'package:flutter_lib/reader/animation/model/text_metrics.dart';

import 'options/option_string.dart';

/// 标签样式，会覆盖base节点样式
class ContentTextNGStyleDescription {
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
  ContentTextNGStyleDescription.fromJson(Map<String, dynamic> json)
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

  int getFontSize(TextMetrics metrics, int parentFontSize) {
    TextStyleEntryLength? length = parseLength(fontSizeOption.getValue());
    if (length == null) {
      return parentFontSize;
    }
    return TextStyleEntryLength.compute(
        length, metrics, parentFontSize, Feature.lengthFontSize);
  }

  int getVerticalAlign(TextMetrics metrics, int base, int fontSize) {
    TextStyleEntryLength? length = parseLength(verticalAlignOption.getValue());
    if (length == null) {
      return base;
    }
    return TextStyleEntryLength.compute(
        // TODO: add new length for vertical alignment
        length,
        metrics,
        fontSize,
        Feature.lengthFontSize);
  }

  bool hasNonZeroVerticalAlign() {
    TextStyleEntryLength? length = parseLength(verticalAlignOption.getValue());
    return length != null && length.size != 0;
  }

  int getLeftMargin(TextMetrics metrics, int base, int fontSize) {
    TextStyleEntryLength? length = parseLength(marginLeftOption.getValue());
    if (length == null) {
      return base;
    }
    return base +
        TextStyleEntryLength.compute(
            length, metrics, fontSize, Feature.lengthMarginLeft);
  }

  int getRightMargin(TextMetrics metrics, int base, int fontSize) {
    TextStyleEntryLength? length = parseLength(marginRightOption.getValue());
    if (length == null) {
      return base;
    }
    return base +
        TextStyleEntryLength.compute(
            length, metrics, fontSize, Feature.lengthMarginRight);
  }

  int getLeftPadding(TextMetrics metrics, int base, int fontSize) {
    return base;
  }

  int getRightPadding(TextMetrics metrics, int base, int fontSize) {
    return base;
  }

  int getFirstLineIndent(TextMetrics metrics, int base, int fontSize) {
    TextStyleEntryLength? length = parseLength(textIndentOption.getValue());
    if (length == null) {
      return base;
    }
    return TextStyleEntryLength.compute(
        length, metrics, fontSize, Feature.lengthFirstLineIndent);
  }

  int getSpaceBefore(TextMetrics metrics, int base, int fontSize) {
    TextStyleEntryLength? length = parseLength(marginTopOption.getValue());
    if (length == null) {
      return base;
    }
    return TextStyleEntryLength.compute(
        length, metrics, fontSize, Feature.lengthSpaceBefore);
  }

  int getSpaceAfter(TextMetrics metrics, int base, int fontSize) {
    TextStyleEntryLength? length = parseLength(marginBottomOption.getValue());
    if (length == null) {
      return base;
    }
    return TextStyleEntryLength.compute(
        length, metrics, fontSize, Feature.lengthSpaceAfter);
  }

  Boolean3 isBold() {
    String fontWeight = fontWeightOption.getValue();
    if ("bold" == fontWeight) {
      return Boolean3.TRUE;
    } else if ("normal" == fontWeight) {
      return Boolean3.FALSE;
    } else {
      return Boolean3.UNDEFINED;
    }
  }

  Boolean3 isItalic() {
    String fontStyle = fontStyleOption.getValue();
    if ("italic" == fontStyle || "oblique" == fontStyle) {
      return Boolean3.TRUE;
    } else if ("normal" == fontStyle) {
      return Boolean3.FALSE;
    } else {
      return Boolean3.UNDEFINED;
    }
  }

  Boolean3 isUnderline() {
    String textDecoration = textDecorationOption.getValue();
    if ("underline" == textDecoration) {
      return Boolean3.TRUE;
    } else if ("" == textDecoration || "inherit" == textDecoration) {
      return Boolean3.UNDEFINED;
    } else {
      return Boolean3.FALSE;
    }
  }

  Boolean3 isStrikeThrough() {
    String textDecoration = textDecorationOption.getValue();
    if ("line-through" == textDecoration) {
      return Boolean3.TRUE;
    } else if ("" == textDecoration || "inherit" == textDecoration) {
      return Boolean3.UNDEFINED;
    } else {
      return Boolean3.FALSE;
    }
  }

  int getAlignment() {
    String alignment = alignmentOption.getValue();
    if (alignment.isEmpty) {
      return ContentTextAlignmentType.alignUndefined.index;
    } else if ("center" == alignment) {
      return ContentTextAlignmentType.alignCenter.index;
    } else if ("left" == alignment) {
      return ContentTextAlignmentType.alignLeft.index;
    } else if ("right" == alignment) {
      return ContentTextAlignmentType.alignRight.index;
    } else if ("justify" == alignment) {
      return ContentTextAlignmentType.alignJustify.index;
    } else {
      return ContentTextAlignmentType.alignUndefined.index;
    }
  }

  Boolean3 allowHyphenations() {
    String hyphen = hyphenationOption.getValue();
    if ("auto" == hyphen) {
      return Boolean3.TRUE;
    } else if ("none" == hyphen) {
      return Boolean3.FALSE;
    } else {
      return Boolean3.UNDEFINED;
    }
  }

  final Map<String, TextStyleEntryLength> _lengthCache = {};

  TextStyleEntryLength? parseLength(String value) {
    if (value.isEmpty) {
      return null;
    }

    TextStyleEntryLength? cacheValue = _lengthCache[value];
    if (cacheValue != null) {
      return cacheValue;
    }

    TextStyleEntryLength? length;
    if (value.endsWith("%")) {
      length = TextStyleEntryLength(
          size: int.parse(value.substring(0, value.length - 1)),
          unit: SizeUnit.percent);
    } else if (value.endsWith("rem")) {
      length = TextStyleEntryLength(
          size: (100 * double.parse(value.substring(0, value.length - 2)))
              .toInt(),
          unit: SizeUnit.rem100);
    } else if (value.endsWith("em")) {
      length = TextStyleEntryLength(
          size: (100 * double.parse(value.substring(0, value.length - 2)))
              .toInt(),
          unit: SizeUnit.em100);
    } else if (value.endsWith("ex")) {
      length = TextStyleEntryLength(
          size: (100 * double.parse(value.substring(0, value.length - 2)))
              .toInt(),
          unit: SizeUnit.ex100);
    } else if (value.endsWith("px")) {
      length = TextStyleEntryLength(
          size: int.parse(value.substring(0, value.length - 2)),
          unit: SizeUnit.pixel);
    } else if (value.endsWith("pt")) {
      length = TextStyleEntryLength(
          size: int.parse(value.substring(0, value.length - 2)),
          unit: SizeUnit.point);
    }

    if (length != null) {
      _lengthCache[value] = length;
    }
    return length;
  }

  @override
  String toString() {
    return "ContentTextNGStyleDescription{" +
        "Name='" +
        name +
        '\'' +
        ", FontFamilyOption=$fontFamilyOption" +
        ", FontSizeOption=$fontSizeOption" +
        ", FontWeightOption=$fontWeightOption" +
        ", FontStyleOption=$fontStyleOption" +
        ", TextDecorationOption=$textDecorationOption" +
        ", HyphenationOption=$hyphenationOption" +
        ", MarginTopOption=$marginTopOption" +
        ", MarginBottomOption=$marginBottomOption" +
        ", MarginLeftOption=$marginLeftOption" +
        ", MarginRightOption=$marginRightOption" +
        ", TextIndentOption=$textIndentOption" +
        ", AlignmentOption=$alignmentOption" +
        ", VerticalAlignOption=$verticalAlignOption" +
        ", LineHeightOption=$lineHeightOption" +
        '}';
  }
}
