
import 'package:flutter_lib/reader/model/paint/element_paint_data.dart';
import 'package:flutter_lib/reader/model/selection/highlight_block.dart';

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
        yEnd = json['yEnd'],
        super.fromJson(json);

  @override
  void debugFillDescription(List<String> description) {
    description.add("lineColor: $lineColor");
    description.add("xStart: $xStart");
    description.add("xEnd: $xEnd");
    description.add("yStart: $yStart");
    description.add("yEnd: $yEnd");
  }
}
