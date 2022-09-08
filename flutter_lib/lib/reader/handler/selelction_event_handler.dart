import 'dart:ui';

import 'package:flutter/gestures.dart';

import '../controller/reader_content_handler.dart';

const dragStart = 'on_selection_drag_start';
const dragMove = 'on_selection_drag_move';
const dragEnd = 'on_selection_drag_end';
const longPressStart = 'long_press_start';
const longPressUpdate = 'long_press_update';
const longPressEnd = 'long_press_end';
const tapUp = 'on_tap_up';

class SelectionEventHandler {
  Offset? _selectionTouchOffset;
  ReaderContentHandler readerContentHandler;

  SelectionEventHandler({required this.readerContentHandler});

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
}
