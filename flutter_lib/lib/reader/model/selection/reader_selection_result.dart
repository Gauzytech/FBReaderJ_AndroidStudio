import 'package:flutter_lib/interface/debug_info_provider.dart';
import 'package:flutter_lib/reader/model/paint/paint_block.dart';
import 'package:flutter_lib/reader/model/selection/highlight_block.dart';
import 'package:flutter_lib/reader/model/selection/selection_cursor.dart';
import 'dart:ui' as ui;

import 'package:flutter_lib/reader/ui/selection_menu_factory.dart';

abstract class ReaderSelectionResult implements DebugInfoProvider {
  @override
  void debugFillDescription(List<String> description) {}

  static ReaderSelectionResult create(Map<String, dynamic> json) {
    int resultType = json['resultType'];
    switch (resultType) {
      case 0:
        return SelectionClearAll();
      case 1:
        return SelectionOpenDirectory();
      case 2:
        return SelectionHighlight.fromJson(json);
      case 3:
        return SelectionNoActionMenu();
      case 4:
        return SelectionNoOp();
      case 5:
        return SelectionOpenHyperLink();
      case 6:
        return SelectionActionMenu.fromJson(json);
      case 7:
        return SelectionOpenImage();
      case 8:
        return SelectionOpenVideo();
      default:
        throw Exception('Unsupported type: $resultType');
    }
  }
}

class SelectionHighlight extends ReaderSelectionResult {
  List<HighlightBlock> paintBlocks;
  SelectionCursor? leftCursor;
  SelectionCursor? rightCursor;

  SelectionHighlight.fromJson(Map<String, dynamic> json)
      : paintBlocks = PaintBlock.fromJsonHighlights(json['paint_blocks']),
        leftCursor = json['left_cursor'] != null
            ? SelectionCursor.fromJson(
                CursorDirection.left, json['left_cursor'])
            : null,
        rightCursor = json['right_cursor'] != null
            ? SelectionCursor.fromJson(
                CursorDirection.right, json['right_cursor'])
            : null;

  @override
  void debugFillDescription(List<String> description) {
    description.add("paintBlocks: $paintBlocks");
    description.add("leftCursor: $leftCursor");
    description.add("rightCursor: $rightCursor");
  }
}

class SelectionNoActionMenu extends ReaderSelectionResult {}

class SelectionNoOp extends ReaderSelectionResult {}

class SelectionOpenDirectory extends ReaderSelectionResult {}

class SelectionOpenHyperLink extends ReaderSelectionResult {}

class SelectionOpenImage extends ReaderSelectionResult {}

class SelectionOpenVideo extends ReaderSelectionResult {}

class SelectionActionMenu extends ReaderSelectionResult {
  int selectionStartY;
  int selectionEndY;

  SelectionActionMenu.fromJson(Map<String, dynamic> json)
      : selectionStartY = json['selection_start_y'],
        selectionEndY = json['selection_end_y'];

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
  void debugFillDescription(List<String> description) {
    description.add("selectionStartY: $selectionStartY");
    description.add("selectionEndY: $selectionEndY");
  }
}

class SelectionClearAll extends ReaderSelectionResult {}
