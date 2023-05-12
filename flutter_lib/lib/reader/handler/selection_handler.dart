import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_lib/reader/ui/selection_menu_factory.dart';

import '../controller/native_interface.dart';
import '../controller/page_repository.dart';

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
/// 2. (已完成) tapUp改selectionResult
/// 3. 局部刷新selectionMenu, 防止本页内容随selectionMenu显示隐藏刷新
/// 4. 搞懂shouldPaint的调用
/// 5. (已完成) 增加添加本地图书功能 - DEMO测试
/// 6. (已完成) 研究pageView源码优化翻页效果
class SelectionHandler {

  // 翻页划选最多5页
  static const int crossPageLimit = 5;

  int get crossPageCount => _crossPageCount;
  int _crossPageCount = 1;

  Offset? _selectionTouchOffset;
  PageRepository readerContentHandler;

  // 跨页划选指示器
  GlobalKey topIndicatorKey;
  GlobalKey bottomIndicatorKey;

  Offset? get menuPosition => _selectionMenuPosition;
  Offset? _selectionMenuPosition;

  SelectionMenuFactory get factory => _menuFactory!;
  final SelectionMenuFactory? _menuFactory;

  SelectionHandler({
    required this.readerContentHandler,
    required this.topIndicatorKey,
    required this.bottomIndicatorKey,
  }) : _menuFactory = SelectionMenuFactory();

  void increaseCrossPageCount() {
    _crossPageCount++;
  }

  void resetCrossPageCount() {
    print('跨页划选, reset page count');
    _crossPageCount = 1;
  }

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

  void updateSelectionMenuPosition(Offset? position) {
    _selectionMenuPosition = position;
  }

  /// 拖拽操作开始
  void onDragStart(DragStartDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程[onDragStart], 有长按选中弹窗, 进行选中区域操作 $position");
    _setSelectionTouch(position);
    readerContentHandler.callNativeMethod(
      NativeScript.dragStart,
      position.dx,
      position.dy,
    );
  }

  /// 拖拽移动中
  void onDragMove(DragUpdateDetails detail) {
    Offset position = detail.localPosition;
    if (!_isDuplicateTouch(position)) {
      print('flutter动画流程[onDragUpdate], 有长按选中弹窗, 进行选中区域操作 $position');
      _setSelectionTouch(position);
      readerContentHandler.callNativeMethod(
        NativeScript.dragMove,
        position.dx,
        position.dy,
      );
    }
  }

  /// 拖拽操作完成
  void onDragEnd(DragEndDetails detail) {
    print("flutter动画流程[onDragEnd], 进行选中区域操作 $detail");
    _setSelectionTouch(null);
    readerContentHandler.callNativeMethod(NativeScript.dragEnd, 0, 0);
  }

  void onLongPressStart(LongPressStartDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程:长按事件, ------------start $position-------->>>>>>>>>");
    if (!_isDuplicateTouch(position)) {
      _setSelectionTouch(position);
      readerContentHandler.callNativeMethod(
        NativeScript.longPressStart,
        position.dx,
        position.dy,
      );
    }
  }

  void onLongPressMove(LongPressMoveUpdateDetails detail) {
    Offset position = detail.localPosition;
    if (!_isDuplicateTouch(position)) {
      print("flutter动画流程:长按事件, ------------move $position--------->>>>>>>>>");
      _setSelectionTouch(position);
      readerContentHandler.callNativeMethod(
        NativeScript.longPressMove,
        position.dx,
        position.dy,
      );
    }
  }

  void onLongPressUp() {
    print("flutter动画流程:长按事件, ------------end------------>>>>>>>>>");
    _setSelectionTouch(null);
    readerContentHandler.callNativeMethod(NativeScript.longPressEnd, 0, 0);
  }

  void onTagUp(TapUpDetails detail) {
    Offset position = detail.localPosition;
    print("flutter动画流程:触摸事件, ------------onTapUp $position--------->>>>>>>>>");
    readerContentHandler.callNativeMethod(
      NativeScript.tapUp,
      position.dx,
      position.dy,
    );
  }

  SelectionIndicator? enableCrossPageIndicator(Offset touchPosition) {
    if (overlapWithTopIndicator(touchPosition)) {
      return SelectionIndicator.topStart;
    } else if (overlapWithBottomIndicator(touchPosition)) {
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
    readerContentHandler.callNativeMethod(NativeScript.selectedText, 0, 0);
  }
}
