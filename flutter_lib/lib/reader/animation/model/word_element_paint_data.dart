import 'dart:core';

import 'package:flutter_lib/reader/animation/model/highlight_block.dart';
import 'package:flutter_lib/reader/animation/model/space_element_paint_data.dart';

import 'element_paint_data.dart';

class WordElementPaintData extends ElementPaintData {
  TextBlock textBlock;
  Mark mark;
  ColorData color;
  int shift;

  WordElementPaintData.fromJson(Map<String, dynamic> json)
      : textBlock = TextBlock.fromJson(json['textBlock']),
        mark = Mark.fromJson(json['mark']),
        color = ColorData.fromJson(json['color']),
        shift = json['shift'];

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add("$runtimeType");
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
}
