import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import '../controller/reader_content_handler.dart';

const dragStart = 'on_selection_drag_start';
const dragMove = 'on_selection_drag_move';
const dragEnd = 'on_selection_drag_end';
const longPressStart = 'long_press_start';
const longPressUpdate = 'long_press_update';
const longPressEnd = 'long_press_end';
const tapUp = 'on_tap_up';

enum SelectionIndicator {
  topStart, bottomEnd
}

class SelectionEventHandler {
  Offset? _selectionTouchOffset;
  ReaderContentHandler readerContentHandler;
  GlobalKey topIndicatorKey;
  GlobalKey bottomIndicatorKey;
  bool _selectionMenuShown = false;

  SelectionEventHandler(
      {required this.readerContentHandler,
      required this.topIndicatorKey,
      required this.bottomIndicatorKey});

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

  void setSelectionMenuState(bool isShow) {
    _selectionMenuShown = isShow;
  }

  bool isSelectionMenuShown() {
    return _selectionMenuShown;
  }

  void onSelectionDragStart(DragStartDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程[onDragStart], 有长按选中弹窗, 进行选中区域操作$position}");
    _setSelectionTouch(position);
    readerContentHandler.callNativeMethod(
      dragStart,
      position.dx.toInt(),
      position.dy.toInt(),
    );
  }

  void onSelectionDragMove(DragUpdateDetails detail) {
    Offset position = detail.localPosition;
    print('flutter动画流程[onDragUpdate], 有长按选中弹窗, 进行选中区域操作$position');
    if (!_isDuplicateTouch(position)) {
      _setSelectionTouch(position);
      readerContentHandler.callNativeMethod(
        dragMove,
        position.dx.toInt(),
        position.dy.toInt(),
      );
    }
  }

  void onSelectionDragEnd(DragEndDetails detail) {
    print("flutter动画流程[onDragEnd], 长按选择操作$detail");
    _setSelectionTouch(null);
    readerContentHandler.callNativeMethod(dragEnd, 0, 0);
  }

  void onLongPressStart(LongPressStartDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程:触摸事件, ------------长按事件开始  $position-------->>>>>>>>>");
    if (!_isDuplicateTouch(position)) {
      _setSelectionTouch(position);
      readerContentHandler.callNativeMethod(
        longPressStart,
        position.dx.toInt(),
        position.dy.toInt(),
      );
    }
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程:触摸事件, ------------长按事件移动 $position--------->>>>>>>>>");
    if (!_isDuplicateTouch(position)) {
      _setSelectionTouch(position);
      readerContentHandler.callNativeMethod(
        longPressUpdate,
        position.dx.toInt(),
        position.dy.toInt(),
      );
    }
  }

  void onLongPressUp() {
    print("flutter动画流程:触摸事件, ------------长按事件结束------------>>>>>>>>>");
    _setSelectionTouch(null);
    readerContentHandler.callNativeMethod(longPressEnd, 0, 0);
  }

  void onTagUp(TapUpDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程:触摸事件, -------------onTapUp $position--------->>>>>>>>>");
    readerContentHandler.callNativeMethod(
      tapUp,
      position.dx.toInt(),
      position.dy.toInt(),
    );
  }

  SelectionIndicator? enableCrossPageIndicator(
    BuildContext context,
    Offset touchPosition,
  ) {
    var ratio = MediaQuery.of(context).devicePixelRatio;
    if(overlapWithTopIndicator(touchPosition, ratio)) {
      return SelectionIndicator.topStart;
    } else if(overlapWithBottomIndicator(touchPosition, ratio)) {
      return SelectionIndicator.bottomEnd;
    }
    return null;
  }

  bool overlapWithTopIndicator(Offset touchPosition, double ratio) {
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

  bool overlapWithBottomIndicator(Offset touchPosition, double ratio) {
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
}
