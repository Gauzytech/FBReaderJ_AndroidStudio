import 'dart:core';

import 'package:flutter_lib/reader/model/paint/paint_block.dart';
import 'package:flutter_lib/reader/model/selection/highlight_block.dart';

import 'element_paint_data.dart';

class WordElementPaintData extends ElementPaintData {
  final List<PaintBlock> blocks;
  final Mark? mark;
  final ColorData? color;
  final int shift;
  final ColorData? highlightBackgroundColor;
  final ColorData? highlightForegroundColor;

  WordElementPaintData.fromJson(Map<String, dynamic> json)
      : blocks = PaintBlock.fromJsonList(json['paintBlocks']),
        mark = Mark.fromJsonNullable(json['mark']),
        color = ColorData.fromJsonNullable(json['color']),
        shift = json['shift'],
        highlightBackgroundColor =
            ColorData.fromJsonNullable(json['highlightBackgroundColor']),
        highlightForegroundColor =
            ColorData.fromJsonNullable(json['highlightForegroundColor']),
        super.fromJson(json);

  @override
  void debugFillDescription(List<String> description) {
    description.add("textStyle: $textStyle");
    description.add("blocks: $blocks");
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

  static Mark? fromJsonNullable(Map<String, dynamic>? json) {
    return json != null ? Mark.fromJson(json) : null;
  }
}
