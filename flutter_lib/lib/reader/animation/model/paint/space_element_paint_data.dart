import 'package:flutter_lib/reader/animation/model/paint/element_paint_data.dart';

class SpaceElementPaintData extends ElementPaintData {
  int spaceWidth;
  List<TextBlock> textBlocks;

  SpaceElementPaintData.fromJson(Map<String, dynamic> json)
      : spaceWidth = json['spaceWidth'],
        textBlocks = TextBlock.fromJsonList(json['textBlocks']);

  @override
  void debugFillDescription(List<String> description) {
    description.add("spaceWidth: $spaceWidth");
    description.add("textBlocks: $textBlocks");
  }
}

class TextBlock {
  List<String> data;
  int offset;
  int length;
  int x;
  int y;

  TextBlock.fromJson(Map<String, dynamic> json)
      : x = json['x'],
        y = json['y'],
        data = (json['data'] as List)
            .map((code) => String.fromCharCode(code))
            .toList(),
        offset = json['offset'],
        length = json['length'];

  static List<TextBlock> fromJsonList(dynamic rawData) {
    return (rawData as List).map((item) => TextBlock.fromJson(item))
        .toList();
  }
}
