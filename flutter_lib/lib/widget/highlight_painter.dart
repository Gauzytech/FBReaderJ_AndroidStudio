import 'package:flutter/material.dart';
import 'package:flutter_lib/reader/animation/model/highlight_coordinate.dart';

class HighlightPainter extends CustomPainter {
  static const drawModeOutline = 1;
  static const drawModeFill = 2;

  /// 线画笔
  final Paint _linePaint = Paint();

  /// 填充画笔
  final Paint _fillPaint = Paint();

  /// 轮廓线画笔
  final Paint _outLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true // 是否启动抗锯齿
    ..strokeJoin = StrokeJoin.round // 画笔笔触类型
    ..strokeWidth = 4; //画笔的宽度
  // ..color = Colors.blueAccent; // 画笔颜色
  // ..blendMode = BlendMode.colorDodge; // 模式
  List<HighlightCoordinate>? highlightCoordinates;

  HighlightPainter({Key? key}) {
    Paint.enableDithering = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightCoordinates != null) {
      print('时间测试, 绘制高亮, $highlightCoordinates');
      for (var item in highlightCoordinates!) {
        if (item.drawMode == drawModeOutline) {
          drawOutline(canvas, item.xs, item.ys);
        } else if (item.drawMode == drawModeFill) {
          drawPolygonalLine(canvas, item.xs, item.ys);
        }
      }
    }
  }

  void updateHighlight(
      NeatColor highlightColor, List<HighlightCoordinate> coordinates) {
    print('时间测试, 更新高亮, $highlightColor');
    _outLinePaint.color = highlightColor.toColor();
    highlightCoordinates = List.from(coordinates);
  }

  void clearHighlight() {
    print('时间测试, 清除高亮');
    highlightCoordinates = null;
  }

  void drawPolygonalLine(Canvas canvas, List<int> xs, List<int> ys) {
    final Path path = Path();
    final int last = xs.length - 1;
    path.moveTo(xs[last].toDouble(), ys[last].toDouble());
    for (int i = 0; i <= last; ++i) {
      path.lineTo(xs[i].toDouble(), ys[i].toDouble());
    }
    canvas.drawPath(path, _linePaint);
  }

  void drawOutline(Canvas canvas, List<int> xs, List<int> ys) {
    int last = xs.length - 1;
    double xStart = (xs[0] + xs[last]) / 2;
    double yStart = (ys[0] + ys[last]) / 2;
    double xEnd = xStart;
    double yEnd = yStart;
    int offset = 5;
    if (xs[0] != xs[last]) {
      if (xs[0] > xs[last]) {
        xStart -= offset;
        xEnd += offset;
      } else {
        xStart += offset;
        xEnd -= offset;
      }
    } else {
      if (ys[0] > ys[last]) {
        yStart -= offset;
        yEnd += offset;
      } else {
        yStart += offset;
        yEnd -= offset;
      }
    }
    final Path path = Path();
    path.moveTo(xStart, yStart);
    for (int i = 0; i <= last; ++i) {
      path.lineTo(xs[i].toDouble(), ys[i].toDouble());
    }
    path.lineTo(xEnd, yEnd);
    canvas.drawPath(path, _outLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    List<HighlightCoordinate>? oldCoordinates =
        (oldDelegate as HighlightPainter).highlightCoordinates;
    print('时间测试, shouldRepaint');
    if (oldCoordinates == null || highlightCoordinates == null) return true;
    for (var i = 0; i < oldCoordinates.length; i++) {
      if (!oldCoordinates[i].equals(highlightCoordinates![i])) {
        print('时间测试, shouldRepaint = true');
        return true;
      }
    }
    print('时间测试, shouldRepaint = false');
    return false;
  }
}
