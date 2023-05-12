import 'dart:ui' as ui;
import 'package:flutter_lib/reader/ui/selection_menu_factory.dart';

class SelectionMenuPosition {

  final int selectionStartY;
  final int selectionEndY;

  SelectionMenuPosition(this.selectionStartY, this.selectionEndY);

  SelectionMenuPosition.fromJson(Map<String, dynamic> json)
      : selectionStartY = json['selectionStartY'],
        selectionEndY = json['selectionEndY'];

  ui.Offset toShowPosition(ui.Size contentSize) {
    double margin = 25;
    double ratio = ui.window.devicePixelRatio;
    double selectionMenuHeight = SelectionMenuFactory.selectionMenuSize.height * ratio;
    double startYMargin = selectionStartY - margin;
    double endYMargin = selectionEndY + margin;
    double startY = startYMargin - selectionMenuHeight;
    double startX = (contentSize.width / ratio - SelectionMenuFactory.selectionMenuSize.width) / 2;
    ui.Offset selectionMenuPosition;
    if (startY > 0) {
      print("选择弹窗, 上方");
      // 显示在选中高亮上方
      selectionMenuPosition = ui.Offset(startX, startY);
    } else if (endYMargin + selectionMenuHeight < contentSize.height) {
      print("选择弹窗, 下方");
      // 显示在选中高亮下方
      selectionMenuPosition = ui.Offset(startX, endYMargin);
    } else {
      print("选择弹窗, 居中");
      // 居中显示
      selectionMenuPosition = ui.Offset.infinite;
    }
    return selectionMenuPosition;
  }

  @override
  String toString() {
    return "selectionStartY = $selectionStartY, selectionEndY = $selectionEndY";
  }
}