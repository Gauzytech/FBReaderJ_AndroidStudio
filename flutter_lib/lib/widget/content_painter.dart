import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ContentPainter extends CustomPainter {
  // final Paint _paint = Paint()
  //   ..color = Colors.blueAccent // 画笔颜色
  //   ..strokeCap = StrokeCap.round //画笔笔触类型
  //   ..isAntiAlias = true //是否启动抗锯齿
  //   ..strokeWidth = 6.0 //画笔的宽度
  //   ..style = PaintingStyle.stroke // 样式
  //   ..blendMode = BlendMode.colorDodge; // 模式

  final ui.Image? _image;

  ContentPainter(this._image, {Key? key});

  @override
  Future paint(Canvas canvas, Size size) async{
    // TODO: implement paint
    if (_image != null) {
//      canvas.drawImageRect(_image, Offset(0.0, 0.0) & Size(_image.width.toDouble(), _image.height.toDouble()), Offset(0.0, 0.0) & Size(200, 200), _paint);

      canvas.drawImage(_image!, Offset.zero, Paint());
      print("flutter内容绘制流程, _image draw finish");
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    ///是否需要重绘
    return _image != (oldDelegate as ContentPainter)._image;
  }
}