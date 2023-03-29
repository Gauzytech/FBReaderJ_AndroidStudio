import 'package:flutter_lib/reader/animation/model/paint/line_paint_data.dart';

class PagePaintData {
  bool get isProcessing => _processing && _linePaintData == null;
  bool _processing;

  List<LinePaintData> get data =>
      _linePaintData != null ? _linePaintData! : List.empty();
  List<LinePaintData>? _linePaintData;

  PagePaintData(List<LinePaintData> linePaintDataList, {bool processing = false})
      : _processing = processing,
        _linePaintData = linePaintDataList;

  void updateData(List<LinePaintData> linePaintDataList) {
    _linePaintData = linePaintDataList;
    _processing = false;
  }

  void dispose() {
    if (_linePaintData != null) {
      for (var lineInfo in _linePaintData!) {
        for (var elementPaintData in lineInfo.elementPaintDataList) {
          elementPaintData.tearDown();
        }
      }
      _linePaintData = null;
    }
  }
}
