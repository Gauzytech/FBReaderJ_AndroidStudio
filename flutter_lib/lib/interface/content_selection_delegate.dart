import 'dart:ui';

import 'package:flutter_lib/reader/model/selection/highlight_block.dart';
import 'package:flutter_lib/reader/model/selection/reader_selection_result.dart';
import 'package:flutter_lib/reader/model/selection/selection_cursor.dart';


abstract class ContentSelectionDelegate {

  void showText(String text);

  void setSelectionHighlight(
    List<HighlightBlock>? blocks,
    List<SelectionCursor>? selectionCursors, {
    bool resetCrossPageCount = false,
  });

  void onSelectionDataUpdate(ReaderSelectionResult selectionResult);
}
