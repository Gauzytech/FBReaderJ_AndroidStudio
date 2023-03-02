import 'dart:core';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'element_paint_data.dart';

class ImageElementPaintData extends ElementPaintData {
  double left;
  double top;
  String imageSrc;
  Size maxSize;
  String scalingType;
  String adjustingModeForImages;

  ImageElementPaintData.fromJson(Map<String, dynamic> json)
      : left = json['left'],
        top = json['top'],
        imageSrc = json['imageSrc'],
        maxSize = Size(
          json['maxSize']['Width'] + .0,
          json['maxSize']['Height'] + .0,
        ),
        scalingType = json['scalingType'],
        adjustingModeForImages = json['adjustingModeForImages'];

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add("$runtimeType");
    description.add("left: $left");
    description.add("top: $top");
    description.add("maxSize: $maxSize");
    description.add("scalingType: $scalingType");
    description.add("adjustingModeForImages: $adjustingModeForImages");
  }
}
