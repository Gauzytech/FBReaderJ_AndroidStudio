import 'package:flutter_lib/book_content/content_element_area_vector.dart';
import 'package:flutter_lib/book_content/content_line_info.dart';
import 'package:flutter_lib/book_content/content_word_cursor.dart';

/// 对应ZLTextPage
class ContentPage {
  ContentWordCursor startCursor = ContentWordCursor();
  ContentWordCursor endCursor = ContentWordCursor();
  List<ContentLineInfo> lineInfos = List.empty();

  // 0: 单列
  // lineInfos.size: 双列
  int column0Height = 0;
  // int paintState = PaintStateEnum.NOTHING_TO_PAINT;

  // 用来辅助定位划选高亮区域
  ContentElementAreaVector textElementMap = ContentElementAreaVector();

  int myColumnWidth = 0;
  int myHeight = 0;
  bool myTwoColumnView = false;
}
