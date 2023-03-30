import 'package:flutter_lib/reader/animation/model/paint/line_paint_data.dart';

class PagePaintData {
  List<LinePaintData> get data => _linePaintData;
  final List<LinePaintData> _linePaintData;

  PagePaintData(List<LinePaintData> linePaintDataList,
      {bool processing = false})
      : _linePaintData = linePaintDataList;

  void dispose() {
    for (var lineInfo in _linePaintData) {
      for (var elementPaintData in lineInfo.elementPaintDataList) {
        elementPaintData.tearDown();
      }
    }
  }
}
