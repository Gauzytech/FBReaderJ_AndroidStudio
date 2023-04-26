import 'package:flutter/material.dart';

import '../reader/animation/model/highlight_block.dart';
import '../reader/animation/model/selection_cursor.dart';

class HighlightPainter extends CustomPainter {
  static const drawModeOutline = 1;
  static const drawModeFill = 2;

  /// 线画笔
  final Paint _linePaint = Paint()..style = PaintingStyle.stroke;

  /// 填充画笔
  final Paint _fillPaint = Paint()..isAntiAlias = true;

  /// 轮廓线画笔
  final Paint _outLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true // 是否启动抗锯齿
    ..strokeJoin = StrokeJoin.round // 画笔笔触类型
    ..strokeWidth = 4; //画笔的宽度
  // ..color = Colors.blueAccent; // 画笔颜色
  // ..blendMode = BlendMode.colorDodge; // 模式

  final Paint _contentBackgroundPaint = Paint();

  bool get hasSelection =>
      _selectionHighlights != null && _selectionHighlights!.isNotEmpty;
  List<HighlightBlock>? _selectionHighlights;
  List<SelectionCursor>? _selectionCursors;

  HighlightPainter({Key? key}) {
    print('时间测试， init HighlightPainter');
    Paint.enableDithering = true;
    // 默认图书内容背景颜色
    _contentBackgroundPaint.color = Colors.white;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制图书内容的背景颜色 TODO 实现设置自定义背景颜色
    // canvas.drawRect(
    //   Rect.fromPoints(Offset.zero, Offset(size.width, size.height)),
    //   _contentBackgroundPaint,
    // );

    // 绘制高亮
    _selectionHighlights?.forEach((highLightBlock) {
      for (var coordinate in highLightBlock.coordinates) {
        if (coordinate.type == drawModeOutline) {
          _outLinePaint.color = highLightBlock.color.toColor();
          _drawOutline(canvas, coordinate.xs, coordinate.ys);
        } else if (coordinate.type == drawModeFill) {
          _fillPaint.color = highLightBlock.color.toColor();
          _fillPolygon(canvas, coordinate.xs, coordinate.ys);
        }
      }
    });

    // 绘制选中的左右光标
    _selectionCursors?.forEach((element) {
      _drawSelectionCursor(canvas, element);
    });
  }

  void updateHighlight(
    List<HighlightBlock>? blocks,
    List<SelectionCursor>? selectionCursors,
  ) {
    if (blocks != null) {
      print('时间测试, 更新高亮, $blocks');
      _selectionHighlights = List.from(blocks);
    } else {
      print('时间测试, 清除高亮');
      _selectionHighlights = null;
    }

    if (selectionCursors != null) {
      _selectionCursors = List.from(selectionCursors);
    } else {
      _selectionCursors = null;
    }
  }

  /// 绘制实心多边形
  ///
  /// @param xs X坐标集合
  /// @param ys Y坐标集合
  void _fillPolygon(Canvas canvas, List<int> xs, List<int> ys) {
    final Path path = Path();
    final int last = xs.length - 1;
    path.moveTo(xs[last].toDouble(), ys[last].toDouble());
    for (int i = 0; i <= last; ++i) {
      path.lineTo(xs[i].toDouble(), ys[i].toDouble());
    }
    canvas.drawPath(path, _fillPaint);
  }

  /// 绘制轮廓线
  ///
  /// @param xs X坐标集合
  /// @param ys Y坐标集合
  void _drawOutline(Canvas canvas, List<int> xs, List<int> ys) {
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

  /// 绘制选择小耳朵
  void _drawSelectionCursor(Canvas canvas, SelectionCursor cursor) {
    _fillPaint.color = cursor.color.toColor();
    final double unit = cursor.dpi / 130;
    final double xCenter = cursor.direction == CursorDirection.left
        ? cursor.point.x - unit - 1
        : cursor.point.x + unit + 1;
    _fillRectangle(canvas, xCenter - unit, cursor.point.y + cursor.dpi / 12,
        xCenter + unit, cursor.point.y - cursor.dpi / 12);
    if (cursor.direction == CursorDirection.left) {
      _fillCircle(canvas, xCenter, cursor.point.y - cursor.dpi / 12, unit * 5);
    } else {
      _fillCircle(canvas, xCenter, cursor.point.y + cursor.dpi / 12, unit * 5);
    }
  }

  void _fillRectangle(
      Canvas canvas, double x0, double y0, double x1, double y1) {
    if (x1 < x0) {
      double swap = x1;
      x1 = x0;
      x0 = swap;
    }
    if (y1 < y0) {
      double swap = y1;
      y1 = y0;
      y0 = swap;
    }
    canvas.drawRect(
        Rect.fromPoints(Offset(x0, y0), Offset(x1 + 1, y1 + 1)), _fillPaint);
  }

  void _fillCircle(Canvas canvas, double x, double y, double radius) {
    canvas.drawCircle(Offset(x, y), radius, _fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as HighlightPainter).compare(_selectionHighlights);
  }

  bool compare(List<HighlightBlock>? other) {
    if (other == null || _selectionHighlights == null) return true;
    for (var i = 0; i < other.length; i++) {
      if (other[i] != _selectionHighlights![i]) {
        return true;
      }
    }
    return false;
  }
}