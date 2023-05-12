import 'dart:ui';

import 'package:flutter_lib/reader/model/selection/highlight_block.dart';
import 'package:flutter_lib/reader/model/selection/selection_cursor.dart';


abstract class ContentSelectionDelegate {

  void showText(String text);

  void setSelectionHighlight(
    List<HighlightBlock>? blocks,
    List<SelectionCursor>? selectionCursors, {
    bool resetCrossPageCount = false,
  });

  /// [position]必须是global position, 因为设置[Positioned]会自动乘以deviceRatio
  void showSelectionMenu(Offset position);
}
