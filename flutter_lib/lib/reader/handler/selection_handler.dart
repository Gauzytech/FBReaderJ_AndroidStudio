import 'package:flutter/material.dart';
import 'package:flutter_lib/reader/ui/selection_menu_factory.dart';
import 'dart:ui' as ui;

import '../controller/reader_content_handler.dart';

enum NativeCmd {
  dragStart('on_selection_drag_start'),
  dragMove('on_selection_drag_move'),
  dragEnd('on_selection_drag_end'),
  longPressStart('long_press_start'),
  longPressMove('long_press_move'),
  longPressEnd('long_press_end'),
  tapUp('on_tap_up'),
  selectionClear('selection_clear'),
  selectedText('selected_text');

  final String cmdName;
  const NativeCmd(this.cmdName);
}

const longPressStart = 'long_press_start';
const longPressUpdate = 'long_press_update';
const longPressEnd = 'long_press_end';
const tapUp = 'on_tap_up';
const selectionClear = 'selection_clear';
const selectedText = 'selected_text';

enum SelectionIndicator { topStart, bottomEnd }

/// TODO
/// 1. (已完成) 把这个选择, 高亮的绘制移到一个独立的图层, 就是在内容custom painter上再覆盖一层透明的选择高亮层,
/// 因为长按划选每次会触发内容图片的重绘(高亮和内容一起绘制), 在老机器上有点卡.
/// 参考: https://medium.flutterdevs.com/repaintboundary-in-flutter-9e2f426ff579, 中的_buildCursor()
/// 2. tapUp改selectionResult
/// 3. 局部刷新selectionMenu, 防止本页内容随selectionMenu显示隐藏刷新
/// 4. 搞懂shouldPaint的调用
/// 5. 增加添加本地图书功能 - DEMO测试
/// 6. 研究pageView源码优化翻页效果
class SelectionHandler {

  // 翻页划选最多5页
  static const int crossPageLimit = 5;
  int crossPageCount = 1;

  Offset? _selectionTouchOffset;
  ReaderContentHandler readerContentHandler;

  // 跨页划选指示器
  GlobalKey topIndicatorKey;
  GlobalKey bottomIndicatorKey;

  // 划选弹窗
  bool _selectionState = false;
  Offset? _selectionMenuPosition;
  SelectionMenuFactory? _menuFactory;

  SelectionHandler(
      {required this.readerContentHandler,
      required this.topIndicatorKey,
      required this.bottomIndicatorKey}) {
    _menuFactory = SelectionMenuFactory();
  }

  Offset? get menuPosition => _selectionMenuPosition;

  bool get isSelectionStateEnabled => _selectionState;

  SelectionMenuFactory get factory => _menuFactory!;

  /// 长按事件处理操作
  /// 保存当前坐标
  void _setSelectionTouch(Offset? offset) {
    _selectionTouchOffset = offset;
  }

  /// 判断是否坐标重复了
  bool _isDuplicateTouch(Offset offset) {
    int prevDx = _selectionTouchOffset?.dx.toInt() ?? -1;
    int prevDy = _selectionTouchOffset?.dy.toInt() ?? -1;
    return offset.dx.toInt() == prevDx && offset.dy.toInt() == prevDy;
  }

  void updateSelectionState(bool enable) {
    _selectionState = enable;
    if(!enable) {
      crossPageCount = 1;
    }
  }

  void updateSelectionMenuPosition(Offset? position) {
    _selectionMenuPosition = position;
  }

  // todo
  void onDragStart(DragStartDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程[onDragStart], 有长按选中弹窗, 进行选中区域操作$position}");
    _setSelectionTouch(position);
    readerContentHandler.callNativeMethod(
      NativeCmd.dragStart,
      position.dx.toInt(),
      position.dy.toInt(),
    );
  }

  // todo
  void onDragMove(DragUpdateDetails detail) {
    Offset position = detail.localPosition;
    print('flutter动画流程[onDragUpdate], 有长按选中弹窗, 进行选中区域操作$position');
    if (!_isDuplicateTouch(position)) {
      _setSelectionTouch(position);
      readerContentHandler.callNativeMethod(
        NativeCmd.dragMove,
        position.dx.toInt(),
        position.dy.toInt(),
      );
    }
  }

  // todo
  void onDragEnd(DragEndDetails detail) {
    print("flutter动画流程[onDragEnd], 长按选择操作$detail");
    _setSelectionTouch(null);
    readerContentHandler.callNativeMethod(NativeCmd.dragEnd, 0, 0);
  }

  void onLongPressStart(LongPressStartDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程:触摸事件, ------------长按事件开始  $position-------->>>>>>>>>");
    if (!_isDuplicateTouch(position)) {
      _setSelectionTouch(position);
      readerContentHandler.callNativeMethod(
        NativeCmd.longPressStart,
        position.dx.toInt(),
        position.dy.toInt(),
      );
    }
  }

  void onLongPressMove(LongPressMoveUpdateDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程:触摸事件, ------------长按事件移动 $position--------->>>>>>>>>");
    if (!_isDuplicateTouch(position)) {
      _setSelectionTouch(position);
      readerContentHandler.callNativeMethod(
        NativeCmd.longPressMove,
        position.dx.toInt(),
        position.dy.toInt(),
      );
    }
  }

  void onLongPressUp() {
    print("flutter动画流程:触摸事件, ------------长按事件结束------------>>>>>>>>>");
    _setSelectionTouch(null);
    readerContentHandler.callNativeMethod(NativeCmd.longPressEnd, 0, 0);
  }

  void onTagUp(TapUpDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程:触摸事件, -------------onTapUp $position--------->>>>>>>>>");
    readerContentHandler.callNativeMethod(
      NativeCmd.tapUp,
      position.dx.toInt(),
      position.dy.toInt(),
    );
  }

  SelectionIndicator? enableCrossPageIndicator(Offset touchPosition,) {
    if(overlapWithTopIndicator(touchPosition)) {
      return SelectionIndicator.topStart;
    } else if(overlapWithBottomIndicator(touchPosition)) {
      return SelectionIndicator.bottomEnd;
    }
    return null;
  }

  bool overlapWithTopIndicator(Offset touchPosition) {
    var ratio = ui.window.devicePixelRatio;
    var renderBox =
        topIndicatorKey.currentContext?.findRenderObject() as RenderBox;
    var topRight = renderBox.localToGlobal(Offset(renderBox.size.width, 0));
    var bottomLeft = renderBox.localToGlobal(Offset(0, renderBox.size.height));

    return isOverlap(
      touchPosition,
      0,
      topRight.dx * ratio,
      0,
      bottomLeft.dy * ratio,
    );
  }

  bool overlapWithBottomIndicator(Offset touchPosition) {
    var ratio = ui.window.devicePixelRatio;
    var renderBox =
        bottomIndicatorKey.currentContext?.findRenderObject() as RenderBox;
    var topLeft = renderBox.localToGlobal(Offset.zero);
    var topRight = renderBox.localToGlobal(Offset(renderBox.size.width, 0));
    var bottomLeft = renderBox.localToGlobal(Offset(0, renderBox.size.height));

    return isOverlap(
      touchPosition,
      topLeft.dx * ratio,
      topRight.dx * ratio,
      topLeft.dy * ratio,
      bottomLeft.dy * ratio,
    );
  }

  bool isOverlap(Offset touchPosition, double left, double right, double top,
      double bottom) {
    double touchDx = touchPosition.dx;
    double touchDy = touchPosition.dy;
    return touchDx >= left &&
        touchDx <= right &&
        touchDy >= top &&
        touchDy <= bottom;
  }

  void copy() {
    readerContentHandler.callNativeMethod(NativeCmd.selectedText, 0, 0);
  }
}
