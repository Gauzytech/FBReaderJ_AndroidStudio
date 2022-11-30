import 'package:flutter/material.dart';

import '../reader/controller/reader_page_view_model.dart';
import '../reader/controller/touch_event.dart';

mixin BookContentPainter {

  void setCurrentTouchEvent(TouchEvent event);

  bool startCurrentTouchEvent(TouchEvent? event);

  bool isDuplicateEvent(EventAction eventAction, Offset touchPosition);

  Offset lastTouchPosition();
}

class ContentPainter extends CustomPainter with BookContentPainter {
  // final Paint _paint = Paint()
  //   ..color = Colors.blueAccent // 画笔颜色
  //   ..strokeCap = StrokeCap.round //画笔笔触类型
  //   ..isAntiAlias = true //是否启动抗锯齿
  //   ..strokeWidth = 6.0 //画笔的宽度
  //   ..style = PaintingStyle.stroke // 样式
  //   ..blendMode = BlendMode.colorDodge; // 模式

  // final ui.Image? _image;

  final ReaderPageViewModel _pageViewModel;
  TouchEvent? currentTouchData;
  int currentPageIndex = 0;
  int currentChapterId = 0;

  ContentPainter({required ReaderPageViewModel pageViewModel, Key? key})
      : _pageViewModel = pageViewModel;

  @override
  Future paint(Canvas canvas, Size size) async {
    // TODO: implement paint
    // if (_image != null) {
//      canvas.drawImageRect(_image, Offset(0.0, 0.0) & Size(_image.width.toDouble(), _image.height.toDouble()), Offset(0.0, 0.0) & Size(200, 200), _paint);

    //   canvas.drawImage(_image!, Offset.zero, Paint());
    //   print("flutter内容绘制流程, _image draw finish");
    // }

    if (!_pageViewModel.readerViewModel.isPageDataEmpty()) {
      print('flutter内容绘制流程, 开始绘制');
      _pageViewModel.setPageSize(size);
      _pageViewModel.onPageDraw(canvas);
    } else {
      print('flutter内容绘制流程, 没有bitmap缓存数据, 绘制空白');
    }
  }

  ///是否需要重绘
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return _pageViewModel.shouldRepaint(oldDelegate, this);
  }

  Future<bool> canScroll(TouchEvent event) async {
    return await _pageViewModel.canScroll(event);
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
}