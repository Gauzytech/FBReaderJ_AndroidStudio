import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_lib/reader/animation/model/highlight_block.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';
import 'package:flutter_lib/utils/paint_modify.dart';
import 'package:flutter_lib/widget/paint_context.dart';

import '../reader/animation/model/image_element_paint_data.dart';
import '../reader/animation/model/user_settings/geometry.dart';

class PagePaintContext extends PaintContext {
  final String _tag = "[PaintContext], 画笔context]";

  /// 画布
  final Canvas _myCanvas;

  /// 文字画笔
  Paint _myTextPaint = Paint()..isAntiAlias = true;

  /// 线画笔
  Paint _myLinePaint = Paint()..style = PaintingStyle.stroke;

  /// 填充画笔
  Paint _myFillPaint = Paint()..isAntiAlias = true;

  /// 轮廓线画笔
  /// 设置轮廓画笔, 比如: 长按选中图片或者超链接
  Paint _myOutlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true // 是否启动抗锯齿
    ..strokeJoin = StrokeJoin.round // 画笔笔触类型
    ..strokeWidth = 4; //画笔的宽度

  final Paint _myExtraPaint = Paint()..isAntiAlias = true;
  final Path _myPath = Path();

  Paint _transparentPaint = Paint()
    ..color = Colors.transparent
    ..blendMode = BlendMode.clear
    ..isAntiAlias = true;

  final Geometry _myGeometry;
  final int _myScrollbarWidth;

  ColorData _myBackgroundColor = ColorData(0, 0, 0);

  @override
  double get width => _myGeometry.areaSize.width - _myScrollbarWidth;

  @override
  double get height => _myGeometry.areaSize.height;

  PagePaintContext(Canvas canvas, Geometry geometry, int scrollbarWidth)
      : _myCanvas = canvas,
        _myGeometry = geometry,
        _myScrollbarWidth = scrollbarWidth {
    Paint.enableDithering = true;
  }

  @override
  void clear(ColorData wallpaperFile, FillMode mode) {
    // TODO: implement clear
  }

  @override
  void clearColor(ColorData colorData) {
    _myBackgroundColor = colorData;
    _myFillPaint = _myFillPaint.withColor(colorData.toColor());
    _myCanvas.drawRect(
      Rect.fromLTRB(
          0, 0, _myGeometry.areaSize.width, _myGeometry.areaSize.height),
      _transparentPaint,
    );
  }

  @override
  void drawBookMark(double x0, double y0, double x1, double y1) {
    _myPath.reset();
    _myPath.moveTo(x0, y0);
    _myPath.lineTo(x1, y0);
    _myPath.lineTo(x1, y1);
    _myPath.lineTo((x1 + x0) / 2, y1 - (y1 - y0) / 5);
    _myPath.lineTo(x0, y1);
    _myPath.close();
    _myCanvas.drawPath(_myPath, _myFillPaint);
  }

  @override
  void drawImage(
      ui.Canvas canvas,
      double x,
      double y,
      ImageElementPaintData imageData,
      ColorAdjustingMode adjustingMode) {

    // 1. 加载image对象
    ui.Image? image = imageData.image;
    if(image != null) {
      switch (adjustingMode) {
        case ColorAdjustingMode.lightenToBackground:
          _myFillPaint = _myFillPaint.withBlendMode(BlendMode.lighten);
          break;
        case ColorAdjustingMode.darkenToBackground:
          _myFillPaint = _myFillPaint.withBlendMode(BlendMode.darken);
          break;
        case ColorAdjustingMode.none:
          break;
      }

      print('flutter内容绘制流程, drawImage = $x, $y, [${image.width}, ${image.height}]');
      canvas.drawImage(
        image,
        Offset(x, y - image.height),
        _myFillPaint,
      );
      _myFillPaint = _myFillPaint.withBlendMode(BlendMode.srcOver);
    }
  }

  @override
  void drawLine(double x0, double y0, double x1, double y1) {
    _myLinePaint = _myLinePaint.withAntiAlias(false);
    _myCanvas.drawLine(Offset(x0, y0), Offset(x1, y1), _myLinePaint);
    final points = [Offset(x0, y0), Offset(x1, y1)];
    _myCanvas.drawPoints(ui.PointMode.points, points, _myLinePaint);
    _myLinePaint = _myLinePaint.withAntiAlias(true);
  }

  @override
  void drawOutline(List<double> xs, List<double> ys) {
    final int last = xs.length - 1;
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
    _myCanvas.drawPath(path, _myOutlinePaint);
  }

  @override
  void fillCircle(double x, double y, double radius) {
    _myCanvas.drawCircle(Offset(x, y), radius, _myFillPaint);
  }

  @override
  void fillPolygon(List<double> xs, List<double> ys) {
    final Path path = Path();
    final int last = xs.length - 1;
    path.moveTo(xs[last], ys[last]);
    for (int i = 0; i <= last; ++i) {
      path.lineTo(xs[i], ys[i]);
    }
    _myCanvas.drawPath(path, _myFillPaint);
  }

  @override
  void drawPolygonalLine(List<double> xs, List<double> ys) {
    final Path path = Path();
    final int last = xs.length - 1;
    path.moveTo(xs[last], ys[last]);
    for (int i = 0; i <= last; ++i) {
      path.lineTo(xs[i], ys[i]);
    }
    _myCanvas.drawPath(path, _myLinePaint);
  }

  @override
  void fillRectangle(double x0, double y0, double x1, double y1) {
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
    _myCanvas.drawRect(Rect.fromLTRB(x0, y0, x1 + 1, y1 + 1), _myFillPaint);
  }

  @override
  ColorData get backgroundColor => _myBackgroundColor;

  @override
  void setFillColorWithOpacity(ColorData colorData, double opacity) {
    _myFillPaint = _myFillPaint.withColor(colorData.toColor(opacity));
  }

  @override
  void setLineColor(ColorData colorData) {
    _myLinePaint = _myLinePaint.withColor(colorData.toColor());
    _myOutlinePaint = _myOutlinePaint.withColor(colorData.toColor());
  }

  @override
  void setLineWidth(double width) {
    _myLinePaint = _myLinePaint.withStrokeWidth(width);
  }

  /// ------------------------ 绘制文字的操作 ------------------------
  @override
  void drawStringInternal(
      int x, int y, Characters string, int offset, int length) {
    // bool containsSoftHyphen = false;
    // for (int i = offset; i < offset + length; ++i) {
    //   if (string[i] == (char) 0xAD) {
    //     containsSoftHyphen = true;
    //     break;
    //   }
    // }
    // if (!containsSoftHyphen) {
    //   _myCanvas.drawText(string, offset, length, x, y, _myTextPaint);
    // } else {
    //   final char[] corrected = new char[length];
    //   int len = 0;
    //   for (int o = offset; o < offset + length; ++o) {
    //     final char chr = string[o];
    //     if (chr != (char) 0xAD) {
    //       corrected[len++] = chr;
    //     }
    //   }
    //   _myCanvas.drawText(corrected, 0, len, x, y, _myTextPaint);
    // }
  }

  @override
  void drawFooter(int x, int y, String progress) {
    // _myCanvas.drawText(progress, x, y, _myExtraPaint);
  }

  @override
  void drawHeader(int x, int y, String title) {
    // myCanvas.drawText(title, x, y, _myExtraPaint);
  }

  @override
  void setExtraFoot(int textSize, ColorData colorData) {
    // _myExtraPaint.setTextSize(textSize);
    // _myExtraPaint.setARGB(255, color.Red, color.Green, color.Blue);
  }

  @override
  void setFontInternal(List<FontEntry> entries, int size, bool bold,
      bool italic, bool underline, bool strikeThrough) {
    // Typeface typeface = null;
    // for (FontEntry e : entries) {
    //   typeface = AndroidFontUtil.typeface(getSystemInfo(), e, bold, italic);
    //   if (typeface != null) {
    //     break;
    //   }
    // }
    // myTextPaint.setTypeface(typeface);
    // myTextPaint.setTextSize(size);
    // myTextPaint.setUnderlineText(underline);
    // myTextPaint.setStrikeThruText(strikeThrought);
  }

  @override
  void setTextColor(ColorData colorData) {
    // _myTextPaint = _myTextPaint.withColor(colorData.toColor());
  }

  @override
  int getCharHeightInternal(String chr) {
    return 0;
  }

  @override
  int getDescentInternal() {
    return 0;
  }

  @override
  int getExtraStringWidth(Characters string, int offset, int length) {
    return 0;
  }

  @override
  int getSpaceWidthInternal() {
    return 0;
  }

  @override
  int getStringHeightInternal() {
    return 0;
  }

  @override
  int getStringWidth(Characters string, int offset, int length) {
    return 0;
  }

  @override
  Size imageSize(String imageUrl, Size maxSize, ScalingType scaling) {
    return const Size(0, 0);
  }
}
