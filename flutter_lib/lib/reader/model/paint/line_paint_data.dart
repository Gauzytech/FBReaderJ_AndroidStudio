import 'package:flutter_lib/reader/model/paint/element_paint_data.dart';

class LinePaintData {
  List<ElementPaintData> elementPaintDataList;

  LinePaintData.fromJson(Map<String, dynamic> json)
      : elementPaintDataList = (json['element_paint_data'] as List)
            .map((item) => ElementPaintData.create(item))
            .toList();

  static List<LinePaintData> fromJsonList(dynamic rawData) {
    return (rawData as List)
        .map((item) => LinePaintData.fromJson(item))
        .toList();
  }
}
