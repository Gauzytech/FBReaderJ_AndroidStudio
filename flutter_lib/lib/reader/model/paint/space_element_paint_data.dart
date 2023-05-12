
import 'package:flutter_lib/reader/model/paint/element_paint_data.dart';
import 'package:flutter_lib/reader/model/paint/paint_block.dart';

class SpaceElementPaintData extends ElementPaintData {
  int spaceWidth;
  List<PaintBlock> blocks;

  SpaceElementPaintData.fromJson(Map<String, dynamic> json)
      : spaceWidth = json['spaceWidth'],
        blocks = PaintBlock.fromJsonList(json['paintBlocks']),
        super.fromJson(json);

  @override
  void debugFillDescription(List<String> description) {
    description.add("spaceWidth: $spaceWidth");
    description.add("blocks: $blocks");
  }
}
