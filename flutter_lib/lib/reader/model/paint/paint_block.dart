import 'package:flutter_lib/reader/model/selection/highlight_block.dart';

abstract class PaintBlock {

  static PaintBlock fromJson(Map<String, dynamic> json) {
    int blockType = json['blockType'];
    switch (blockType) {
      case 0:
        return TextBlock.fromJson(json);
      case 1:
        return RectangleBlock.fromJson(json);
      case 2:
        return HighlightBlock.fromJson(json);
      default:
        throw Exception('Unsupported blockType: $blockType');
    }
  }

  static List<PaintBlock> fromJsonList(dynamic rawData) {
    return (rawData as List).map((item) => PaintBlock.fromJson(item)).toList();
  }

  static List<HighlightBlock> fromJsonHighlights(dynamic rawData) {
    return (rawData as List).map((item) => PaintBlock.fromJson(item) as HighlightBlock).toList();
  }
}

class TextBlock extends PaintBlock {
  String text;
  ColorData? colorData;
  int x;
  int y;

  TextBlock.fromJson(Map<String, dynamic> json)
      : text = json['text'],
        colorData = ColorData.fromJsonNullable(json['color']),
        x = json['x'],
        y = json['y'];
}

class RectangleBlock extends PaintBlock {
  ColorData? colorData;
  int x0;
  int y0;
  int x1;
  int y1;

  RectangleBlock.fromJson(Map<String, dynamic> json)
      : colorData = ColorData.fromJsonNullable(json['color']),
        x0 = json['x0'],
        y0 = json['y0'],
        x1 = json['x1'],
        y1 = json['y1'];
}
