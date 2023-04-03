import 'dart:core';

import 'package:flutter_lib/reader/animation/model/highlight_block.dart';
import 'package:flutter_lib/reader/animation/model/paint/space_element_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_style.dart';

import 'element_paint_data.dart';

class WordElementPaintData extends ElementPaintData {
  final NRTextStyle textStyle;
  final TextBlock textBlock;
  final Mark? mark;
  final ColorData color;
  final int shift;

  WordElementPaintData.fromJson(Map<String, dynamic> json)
      : textStyle = NRTextStyle.create(json['textStyle']),
        textBlock = TextBlock.fromJson(json['textBlock']),
        mark = Mark.fromJsonOrNull(json['mark']),
        color = ColorData.fromJson(json['color']),
        shift = json['shift'];

  @override
  void debugFillDescription(List<String> description) {
    description.add("textStyle: $textStyle");
    description.add("textBlock: $textBlock");
    description.add("mark: $mark");
    description.add("color: $color");
    description.add("shift: $shift");
  }
}

class Mark {
  int start;
  int length;
  Mark next;

  Mark.fromJson(Map<String, dynamic> json)
      : start = json['Start'],
        length = json['Length'],
        next = Mark.fromJson(json['myNext']);

  static Mark? fromJsonOrNull(Map<String, dynamic>? json) {
    return json != null ? Mark.fromJson(json) : null;
  }
}
