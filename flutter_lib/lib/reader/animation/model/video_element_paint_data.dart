import 'package:flutter_lib/reader/animation/model/element_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/highlight_block.dart';

class VideoElementPaintData extends ElementPaintData {
  ColorData lineColor;
  int xStart;
  int xEnd;
  int yStart;
  int yEnd;

  VideoElementPaintData.fromJson(Map<String, dynamic> json)
      : lineColor = ColorData.fromJson(json['lineColor']),
        xStart = json['xStart'],
        xEnd = json['xEnd'],
        yStart = json['yStart'],
        yEnd = json['yEnd'];

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add("$runtimeType");
    description.add("lineColor: $lineColor");
    description.add("xStart: $xStart");
    description.add("xEnd: $xEnd");
    description.add("yStart: $yStart");
    description.add("yEnd: $yEnd");
  }
}
