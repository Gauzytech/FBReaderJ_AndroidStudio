import 'package:flutter/material.dart';

import '../reader/controller/reader_page_manager.dart';
import '../reader/controller/touch_event.dart';

class ContentPainter extends CustomPainter {
  // final Paint _paint = Paint()
  //   ..color = Colors.blueAccent // 画笔颜色
  //   ..strokeCap = StrokeCap.round //画笔笔触类型
  //   ..isAntiAlias = true //是否启动抗锯齿
  //   ..strokeWidth = 6.0 //画笔的宽度
  //   ..style = PaintingStyle.stroke // 样式
  //   ..blendMode = BlendMode.colorDodge; // 模式

  // final ui.Image? _image;

  ReaderPageManager pageManager;
  TouchEvent? currentTouchData;
  Offset? _selectionTouchOffset;
  int currentPageIndex = 0;
  int currentChapterId = 0;

  ContentPainter(this.pageManager, {Key? key});

  @override
  Future paint(Canvas canvas, Size size) async {
    // TODO: implement paint
    // if (_image != null) {
//      canvas.drawImageRect(_image, Offset(0.0, 0.0) & Size(_image.width.toDouble(), _image.height.toDouble()), Offset(0.0, 0.0) & Size(200, 200), _paint);

    //   canvas.drawImage(_image!, Offset.zero, Paint());
    //   print("flutter内容绘制流程, _image draw finish");
    // }

    pageManager.setPageSize(size);
    pageManager.onPageDraw(canvas);
  }

  ///是否需要重绘
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return pageManager.shouldRepaint(oldDelegate, this);
  }

  Future<bool> canScroll(TouchEvent event) async {
    return await pageManager.canScroll(event);
  }

  /// 缓存触摸事件判断滑动方向
  /// 注意多线程全局变量问题
  void setCurrentTouchEvent(TouchEvent event) {
    currentTouchData = event;
  }

  /// 将重绘数据给painter canvas
  bool startCurrentTouchEvent(TouchEvent event) {
    return pageManager.setCurrentTouchEvent(event);
  }

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

  Offset lastTouchPosition() {
    return currentTouchData?.touchPosition ?? Offset.zero;
  }
}