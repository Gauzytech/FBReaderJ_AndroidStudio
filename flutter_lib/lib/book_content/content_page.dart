import 'package:flutter_lib/book_content/content_element_area_vector.dart';
import 'package:flutter_lib/book_content/content_line_info.dart';
import 'package:flutter_lib/book_content/content_word_cursor.dart';
import 'package:flutter_lib/book_content/model/column_mode.dart';
import 'package:flutter_lib/book_content/model/paint_state.dart';

/// 对应ZLTextPage
class ContentPage {
  ContentWordCursor startCursor;
  ContentWordCursor endCursor;
  List<ContentLineInfo> _lineInfos;

  // 0: 单列
  // lineInfos.size: 双列
  int column0Height = 0;
  PaintState paintState = PaintState.nothingToPaint;

  // 用来辅助定位划选高亮区域
  ContentElementAreaVector textElementMap = ContentElementAreaVector();

  // page可绘制区域一列的宽度, 受[ColumnMode]影响，不是page可绘制区域总宽度
  int _contentColumnWidth = 0;

  // page可绘制区域的高度
  int _contentAreaHeight = 0;

  // 显示模式: 单列/双列
  ColumnMode _columnMode = ColumnMode.singleColumnView;

  ContentPage.fromJson(Map<String, dynamic> json)
      : startCursor = ContentWordCursor.fromJson(json['startCursor']),
        endCursor = ContentWordCursor.fromJson(json['endCursor']),
        _lineInfos = (json['lineInfos'] as List)
            .map((item) => ContentLineInfo.fromJson(item))
            .toList(),
        column0Height = json['column0Height'],
        paintState = PaintState.create(json['paintState']),
        _contentColumnWidth = json['myColumnWidth'],
        _contentAreaHeight = json['myHeight'],
        _columnMode = ColumnMode.create(json['myTwoColumnView']);

}
