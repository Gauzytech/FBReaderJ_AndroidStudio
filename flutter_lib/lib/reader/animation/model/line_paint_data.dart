import 'package:flutter_lib/reader/animation/model/element_paint_data.dart';

class LinePaintData {
  List<ElementPaintData> elementPaintDataList;

  LinePaintData.fromJson(String rootPath, Map<String, dynamic> json)
      : elementPaintDataList = (json['elementPaintData'] as List)
            .map((item) => ElementPaintData.fromJson(item))
            .toList();
}
