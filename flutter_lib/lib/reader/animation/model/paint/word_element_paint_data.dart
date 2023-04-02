import 'dart:core';

import 'package:flutter_lib/reader/animation/model/highlight_block.dart';
import 'package:flutter_lib/reader/animation/model/paint/space_element_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_style.dart';

import 'element_paint_data.dart';

class WordElementPaintData extends ElementPaintData {
  final NRTextStyle _textStyle;
  final TextBlock _textBlock;
  final Mark? _mark;
  final ColorData _color;
  final int _shift;

  WordElementPaintData.fromJson(Map<String, dynamic> json)
      : _textStyle = NRTextStyle.create(json['textStyle']),
        _textBlock = TextBlock.fromJson(json['textBlock']),
        _mark = Mark.fromJsonOrNull(json['mark']),
        _color = ColorData.fromJson(json['color']),
        _shift = json['shift'];

  @override
  void debugFillDescription(List<String> description) {
    description.add("textStyle: $_textStyle");
    description.add("textBlock: $_textBlock");
    description.add("mark: $_mark");
    description.add("color: $_color");
    description.add("shift: $_shift");
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
