import 'package:flutter/foundation.dart';
import 'package:flutter_lib/interface/debug_info_provider.dart';
import 'package:flutter_lib/interface/disposable_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/paint/space_element_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/nr_text_style.dart';
import 'package:flutter_lib/reader/animation/model/paint/video_element_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/paint/word_element_paint_data.dart';

import 'extension_element_paint_data.dart';
import 'image_element_paint_data.dart';

enum ElementType { word, image, video, extension, space }

abstract class ElementPaintData with DisposablePaintData, DebugInfoProvider {
  final NRTextStyle? textStyle;

  ElementPaintData.fromJson(Map<String, dynamic> json)
      : textStyle = json['textStyle'] != null
            ? NRTextStyle.create(json['textStyle'])
            : null;

  static ElementPaintData create(Map<String, dynamic> json) {
    int elementType = json['elementType'];
    if (elementType == ElementType.word.index) {
      return WordElementPaintData.fromJson(json);
    } else if (elementType == ElementType.image.index) {
      return ImageElementPaintData.fromJson(json);
    } else if (elementType == ElementType.video.index) {
      return VideoElementPaintData.fromJson(json);
    } else if (elementType == ElementType.extension.index) {
      return ExtensionElementPaintData.fromJson(json);
    } else if (elementType == ElementType.space.index) {
      return SpaceElementPaintData.fromJson(json);
    } else {
      throw Exception('Unsupported type: $elementType');
    }
  }

  @override
  void tearDown() {
    print('${describeIdentity(this)} tear down');
  }
}
