import 'dart:core';
import 'dart:ui';

import 'element_paint_data.dart';

enum ImageSourceType {
  network('network'),
  file('file');

  final String name;

  const ImageSourceType(this.name);

  static ImageSourceType fromName(String name) {
    if (name == ImageSourceType.network.name) {
      return ImageSourceType.network;
    } else if (name == ImageSourceType.file.name) {
      return ImageSourceType.file;
    } else {
      throw Exception('Unknown name: $name');
    }
  }
}

class ImageElementPaintData extends ElementPaintData {
  ImageSourceType sourceType;
  double left;
  double top;
  String imageSrc;
  Size maxSize;
  String scalingType;
  String adjustingModeForImages;

  ImageElementPaintData.fromJson(Map<String, dynamic> json)
      : sourceType = ImageSourceType.fromName(json['sourceType']),
        left = json['left'],
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
