import 'package:flutter_lib/reader/animation/model/paint/line_paint_data.dart';

class PagePaintData {
  List<LinePaintData> linePaintDataCollection;

  PagePaintData({required this.linePaintDataCollection});

  void dispose() {
    for (var lineInfo in linePaintDataCollection) {
      for (var elementPaintData in lineInfo.elementPaintDataList) {
        elementPaintData.tearDown();
      }
    }
  }
}
