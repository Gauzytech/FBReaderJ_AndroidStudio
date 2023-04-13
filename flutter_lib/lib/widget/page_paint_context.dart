import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_lib/model/pair.dart';
import 'package:flutter_lib/reader/animation/model/highlight_block.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/font_entry.dart';
import 'package:flutter_lib/utils/font_util.dart';
import 'package:flutter_lib/utils/paint_modify.dart';
import 'package:flutter_lib/widget/paint_context.dart';
import 'package:google_fonts/google_fonts.dart';

import '../reader/animation/model/paint/image_element_paint_data.dart';
import '../reader/animation/model/user_settings/geometry.dart';

class PagePaintContext extends PaintContext {
  /// 文字样式
  TextStyle _textStyle = const TextStyle(color: Colors.black);

  /// 线画笔
  Paint _myLinePaint = Paint()
    ..style = PaintingStyle.stroke;

  /// 填充画笔
  Paint _myFillPaint = Paint()
    ..isAntiAlias = true;

  /// 轮廓线画笔
  /// 设置轮廓画笔, 比如: 长按选中图片或者超链接
  Paint _myOutlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true // 是否启动抗锯齿
    ..strokeJoin = StrokeJoin.round // 画笔笔触类型
    ..strokeWidth = 4; //画笔的宽度

  final Paint _myExtraPaint = Paint()..isAntiAlias = true;
  final Path _myPath = Path();

  final Paint _transparentPaint = Paint()
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
      : _myGeometry = geometry,
        _myScrollbarWidth = scrollbarWidth {
    Paint.enableDithering = true;
  }

  @override
  void clear(ui.Canvas canvas, ColorData wallpaperFile, FillMode mode) {
    // todo
  }

  @override
  void clear2(ui.Canvas canvas, ColorData colorData) {
    _myBackgroundColor = colorData;
    _myFillPaint = _myFillPaint.copyWith(color: colorData.toColor());
    canvas.drawRect(
      Rect.fromLTRB(
        0, 0, _myGeometry.areaSize.width, _myGeometry.areaSize.height),
      _transparentPaint,
    );
  }

  @override
  void drawBookMark(ui.Canvas canvas, double x0, double y0, double x1, double y1) {
    _myPath.reset();
    _myPath.moveTo(x0, y0);
    _myPath.lineTo(x1, y0);
    _myPath.lineTo(x1, y1);
    _myPath.lineTo((x1 + x0) / 2, y1 - (y1 - y0) / 5);
    _myPath.lineTo(x0, y1);
    _myPath.close();
    canvas.drawPath(_myPath, _myFillPaint);
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
          _myFillPaint = _myFillPaint.copyWith(blendMode: BlendMode.lighten);
          break;
        case ColorAdjustingMode.darkenToBackground:
          _myFillPaint = _myFillPaint.copyWith(blendMode: BlendMode.darken);
          break;
        case ColorAdjustingMode.none:
          break;
      }

      canvas.drawImage(
        image,
        Offset(x, y - image.height),
        _myFillPaint,
      );
      _myFillPaint = _myFillPaint.copyWith(blendMode: BlendMode.srcOver);
    }
  }

  @override
  void drawLine(ui.Canvas canvas, double x0, double y0, double x1, double y1) {
    _myLinePaint = _myLinePaint.copyWith(isAntiAlias: false);
    canvas.drawLine(Offset(x0, y0), Offset(x1, y1), _myLinePaint);
    final points = [Offset(x0, y0), Offset(x1, y1)];
    canvas.drawPoints(ui.PointMode.points, points, _myLinePaint);
    _myLinePaint = _myLinePaint.copyWith(isAntiAlias: true);
  }

  @override
  void drawOutline(ui.Canvas canvas, List<double> xs, List<double> ys) {
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
    canvas.drawPath(path, _myOutlinePaint);
  }

  @override
  void fillCircle(ui.Canvas canvas, double x, double y, double radius) {
    canvas.drawCircle(Offset(x, y), radius, _myFillPaint);
  }

  @override
  void fillPolygon(ui.Canvas canvas, List<double> xs, List<double> ys) {
    final Path path = Path();
    final int last = xs.length - 1;
    path.moveTo(xs[last], ys[last]);
    for (int i = 0; i <= last; ++i) {
      path.lineTo(xs[i], ys[i]);
    }
    canvas.drawPath(path, _myFillPaint);
  }

  @override
  void drawPolygonalLine(ui.Canvas canvas, List<double> xs, List<double> ys) {
    final Path path = Path();
    final int last = xs.length - 1;
    path.moveTo(xs[last], ys[last]);
    for (int i = 0; i <= last; ++i) {
      path.lineTo(xs[i], ys[i]);
    }
    canvas.drawPath(path, _myLinePaint);
  }

  @override
  void fillRectangle(ui.Canvas canvas, double x0, double y0, double x1, double y1) {
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
    canvas.drawRect(Rect.fromLTRB(x0, y0, x1 + 1, y1 + 1), _myFillPaint);
  }

  @override
  ColorData get backgroundColor => _myBackgroundColor;

  @override
  void setFillColorWithOpacity(ColorData? colorData, double opacity) {
    if (colorData != null) {
      _myFillPaint = _myFillPaint.copyWith(color: colorData.toColor(opacity));
    }
  }

  @override
  void setLineColor(ColorData? colorData) {
    if(colorData != null) {
      _myLinePaint = _myLinePaint.copyWith(color: colorData.toColor());
      _myOutlinePaint = _myOutlinePaint.copyWith(color: colorData.toColor());
    }
  }

  @override
  void setLineWidth(double width) {
    _myLinePaint = _myLinePaint.copyWith(strokeWidth: width);
  }

  /// ------------------------ 绘制文字的操作 ------------------------
  @override
  Size drawString2(
    ui.Canvas canvas,
    double x,
    double y,
    List<String> chars,
    int offset,
    int length, {
    TextPainter? painter,
  }) {
    if (painter != null) {
      painter.paint(canvas, Offset(x, y));
      return painter.size;
    } else {
      var buffer = StringBuffer();
      bool containsSoftHyphen = false;
      for (int i = offset; i < offset + length; ++i) {
        if (chars[i] == String.fromCharCode(0xAD)) {
          containsSoftHyphen = true;
          break;
        }
        buffer.write(chars[i]);
      }

      if (containsSoftHyphen) {
        StringBuffer corrected = StringBuffer();
        for (int o = offset; o < offset + length; ++o) {
          final String chr = chars[o];
          if (chr != String.fromCharCode(0xAD)) {
            corrected.write(chr);
          }
        }
        buffer = corrected;
      }
      print('ceshi123, flutter draw: ${buffer.toString()}, [$x, $y], total = ${chars.length}');

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: buffer.toString(),
          style: _textStyle,
        ),
        locale: WidgetsBinding.instance.window.locale,
        textDirection: TextDirection.ltr,
      )..layout();

      // todo 根据y绘制出来的高度不对
      textPainter.paint(canvas, Offset(x, y));
      return textPainter.size;
    }
  }

  @override
  Pair<TextPainter?, double> getStringWidth(List<String> chars,
      int offset,
      int length, {
        Size? stringSize,
      }) {
    if (stringSize != null) return Pair(null, stringSize.width + 0.5);

    var buffer = StringBuffer();
    bool containsSoftHyphen = false;
    for (int i = offset; i < offset + length; ++i) {
      if (chars[i] == String.fromCharCode(0xAD)) {
        containsSoftHyphen = true;
        break;
      }
      buffer.write(chars[i]);
    }

    if (containsSoftHyphen) {
      StringBuffer corrected = StringBuffer();
      for (int o = offset; o < offset + length; ++o) {
        final String chr = chars[o];
        if (chr != String.fromCharCode(0xAD)) {
          corrected.write(chr);
        }
      }
      buffer = corrected;
    }

    TextPainter textPainter = TextPainter(
      locale: WidgetsBinding.instance.window.locale,
      text: TextSpan(
        text: buffer.toString(),
        style: _textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return Pair(textPainter, textPainter.width + 0.5);
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
  void setFontInternal(
    List<FontEntry> entries,
    int size,
    bool bold,
    bool italic,
    bool underline,
    bool strikeThrough,
  ) {
    print('flutter内容绘制流程, setFontInternal');

    FontTypeFace? typeface;
    for (var fontEntry in entries) {
      typeface = FontUtil.fontTypeFace(fontEntry.family);
      break;
    }
    ui.TextDecoration textDecoration;
    if (underline) {
      textDecoration = ui.TextDecoration.underline;
    } else if (strikeThrough) {
      textDecoration = ui.TextDecoration.lineThrough;
    } else {
      textDecoration = ui.TextDecoration.none;
    }
    ui.FontWeight fontWeight = bold ? FontWeight.bold : FontWeight.normal;
    ui.FontStyle fontStyle = italic ? FontStyle.italic : FontStyle.normal;
    switch (typeface) {
      case FontTypeFace.serif:
        _textStyle = GoogleFonts.robotoSerif(
          fontSize: size.toDouble(),
          decoration: textDecoration,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        );
        break;
      case FontTypeFace.monospace:
        _textStyle = GoogleFonts.robotoMono(
          fontSize: size.toDouble(),
          decoration: textDecoration,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        );
        break;
      default:
        _textStyle = _textStyle.copyWith(
          fontSize: size.toDouble(),
          decoration: textDecoration,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        );
    }
  }

  @override
  void setTextColor(ColorData? colorData) {
    if(colorData != null) {
      _textStyle = _textStyle.copyWith(color: colorData.toColor());
    }
  }

  @override
  int getCharHeightInternal(String chr) {
    // todo
    return 0;
  }

  @override
  int getDescentInternal(TextPainter textPainter) {
    return (textPainter
        .computeLineMetrics()
        .first
        .descent + 0.5).toInt();
  }

  @override
  int getExtraStringWidth(Characters string, int offset, int length) {
    // todo
    return 0;
  }

  @override
  int getSpaceWidthInternal() {
    // todo
    return 0;
  }

  @override
  int getStringHeightInternal() => (_textStyle.fontSize! + 0.5).toInt();

  @override
  Size imageSize(String imageUrl, Size maxSize, ScalingType scaling) {
    // todo
    return const Size(0, 0);
  }
}
