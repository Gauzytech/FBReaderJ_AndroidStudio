import 'package:flutter_lib/reader/animation/model/element_paint_data.dart';

class SpaceElementPaintData extends ElementPaintData {
  int spaceWidth;
  List<TextBlock> textBlocks;

  SpaceElementPaintData.fromJson(Map<String, dynamic> json)
      : spaceWidth = json['spaceWidth'],
        textBlocks = (json['textBlocks'] as List)
            .map((item) => TextBlock.fromJson(item))
            .toList();


  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add("$runtimeType");
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
        data = (json['data'] as List).map((item) => item as String).toList(),
        offset = json['offset'],
        length = json['length'];
}
