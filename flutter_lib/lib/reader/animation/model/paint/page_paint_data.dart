import 'package:flutter_lib/reader/animation/model/paint/line_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_style_collection.dart';

class PagePaintData {
  List<LinePaintData> get data => _linePaintData;
  final List<LinePaintData> _linePaintData;

  NRTextStyleCollection get styleCollection => _styleCollection;
  NRTextStyleCollection _styleCollection;

  PagePaintData(NRTextStyleCollection styleCollection,
      List<LinePaintData> linePaintDataList,
      {bool processing = false})
      : _styleCollection = styleCollection,
        _linePaintData = linePaintDataList;

  void dispose() {
    for (var lineInfo in _linePaintData) {
      for (var elementPaintData in lineInfo.elementPaintDataList) {
        elementPaintData.tearDown();
      }
    }
  }
}
