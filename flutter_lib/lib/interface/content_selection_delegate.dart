import 'dart:ui';

import '../reader/animation/model/highlight_block.dart';
import '../reader/animation/model/selection_cursor.dart';

abstract class ContentSelectionDelegate {

  void updateSelectionState(bool enable);

  void showText(String text);

  void setSelectionHighlight(
    List<HighlightBlock>? blocks,
    List<SelectionCursor>? selectionCursors,
  );

  /// [position]必须是global position, 因为设置[Positioned]会自动乘以deviceRatio
  void showSelectionMenu(Offset position);
}
