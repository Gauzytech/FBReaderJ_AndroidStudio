import 'package:flutter_lib/reader/animation/model/video_element_paint_data.dart';

import 'element_paint_data.dart';
import 'image_element_paint_data.dart';

class ExtensionElementPaintData extends ElementPaintData {
  ImageElementPaintData imagePaintData;
  VideoElementPaintData videoElementPaintData;

  ExtensionElementPaintData.fromJson(Map<String, dynamic> json)
      : imagePaintData = ImageElementPaintData.fromJson(json['imagePaintData']),
        videoElementPaintData =
            VideoElementPaintData.fromJson(json['videoPaintData']);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add("$runtimeType");
    description.add("imagePaintData: $imagePaintData");
    description.add("videoElementPaintData: $videoElementPaintData");
  }
}
