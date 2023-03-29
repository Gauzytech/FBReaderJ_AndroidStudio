import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_lib/reader/animation/model/page_paint_metadata.dart';

import '../reader/controller/reader_page_view_model.dart';
import '../reader/controller/touch_event.dart';

mixin BookContentPainter {

  void setCurrentTouchEvent(TouchEvent event);

  bool startCurrentTouchEvent(TouchEvent? event);

  bool isDuplicateEvent(EventAction eventAction, Offset touchPosition);

  Offset lastTouchPosition();

  void onPagePaintMetaUpdate(PagePaintMetaData data);

  Future<bool> canScroll(ScrollDirection scrollDirection);
}

class ContentPainter extends CustomPainter with BookContentPainter {

  final ReaderPageViewModel _pageViewModel;
  TouchEvent? currentTouchData;
  int currentPageIndex = 0;
  int currentChapterId = 0;

  ContentPainter({required ReaderPageViewModel pageViewModel, Key? key})
      : _pageViewModel = pageViewModel;

  @override
  void paint(Canvas canvas, Size size) {
    if (!_pageViewModel.readerViewModel.isPageDataEmpty()) {
      _pageViewModel.setPageSize(size);
      _pageViewModel.onPageDraw(canvas);
    } else {
      print('flutter内容绘制流程, 没有bitmap缓存数据, 空白, 不绘制');
    }
  }

  ///是否需要重绘
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return _pageViewModel.shouldRepaint(oldDelegate, this);
  }

  @override
  Future<bool> canScroll(ScrollDirection scrollDirection) async {
    // return await _pageViewModel.canScrollNew(scrollDirection);
    return _pageViewModel.canScrollPage(scrollDirection);
  }

  /// 缓存触摸事件判断滑动方向
  /// 注意多线程全局变量问题
  @override
  void setCurrentTouchEvent(TouchEvent event) {
    currentTouchData = event;
  }

  /// 将重绘数据给painter canvas
  @override
  bool startCurrentTouchEvent(TouchEvent? event) {
    return _pageViewModel.setCurrentTouchEvent(event ?? currentTouchData!);
  }

  @override
  bool isDuplicateEvent(EventAction eventAction, Offset touchPosition) {
    if (currentTouchData == null) return false;

    if (eventAction == EventAction.dragStart ||
        eventAction == EventAction.move) {
      return currentTouchData!.action == eventAction &&
          currentTouchData!.touchPosition == touchPosition;
    } else {
      return currentTouchData!.action == EventAction.dragEnd ||
          // 如果之前事件是down, 中间没有move事件，证明这只是个点击操作, 而不是fling
          currentTouchData!.action == EventAction.dragStart;
    }
  }

  @override
  Offset lastTouchPosition() {
    return currentTouchData?.touchPosition ?? Offset.zero;
  }

  @override
  void onPagePaintMetaUpdate(PagePaintMetaData data) => _pageViewModel.onPagePreDraw(data);
}