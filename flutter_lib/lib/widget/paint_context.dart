import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_lib/model/pair.dart';
import 'package:flutter_lib/reader/model/paint/image_element_paint_data.dart';
import 'package:flutter_lib/reader/model/selection/highlight_block.dart';
import 'package:flutter_lib/reader/model/user_settings/font_entry.dart';

enum FillMode {
  tile,
  tileMirror,
  fullscreen,
  stretch,
  tileVertically,
  tileHorizontally
}

abstract class PaintContext {
  static const space = 32;
  // private final SystemInfo mySystemInfo;
  //
  // protected ZLPaintContext(SystemInfo systemInfo) {
  //   mySystemInfo = systemInfo;
  // }

  // public final SystemInfo getSystemInfo() {
  // return mySystemInfo;
  // }

  void clear(ui.Canvas canvas, ColorData wallpaperFile, FillMode mode);

  void clear2(ui.Canvas canvas, ColorData colorData);

  /// 获取背景色
  ///
  /// @return 背景色
  late ColorData backgroundColor;

  /// 是否重置字体
  bool _myResetFont = true;

  /// 字体集合
  List<FontEntry>? _myFontEntries;

  /// 字体大小
  int _myFontSize = 0;

  /// 字体-粗体
  bool _myFontIsBold = false;

  /// 字体-斜体
  bool _myFontIsItalic = false;

  /// 字体-下划线
  bool _myFontIsUnderlined = false;

  /// 字体-中划线
  bool _myFontIsStrikeThrough = false;

  int _mySpaceWidth = -1;
  int _myStringHeight = -1;
  final Map<String, int> _myCharHeights = SplayTreeMap();
  int _myDescent = -1;

  TextStyle get textStyle;

  /// 设置字体相关属性（内部实现）
  /// 有一个属性变化就RestFont
  ///
  /// @param entries       字体集合
  /// @param size          字体大小
  /// @param bold          粗体
  /// @param italic        斜体
  /// @param underline     下划线
  /// @param strikeThrough 中划线
  void setFont(
    List<FontEntry>? entries,
    int size,
    bool bold,
    bool italic,
    bool underline,
    bool strikeThrough,
  ) {
    if (entries != null && entries != _myFontEntries) {
      _myFontEntries = entries;
      _myResetFont = true;
    }

    if (_myFontSize != size) {
      _myFontSize = size;
      _myResetFont = true;
    }
    if (_myFontIsBold != bold) {
      _myFontIsBold = bold;
      _myResetFont = true;
    }
    if (_myFontIsItalic != italic) {
      _myFontIsItalic = italic;
      _myResetFont = true;
    }
    if (_myFontIsUnderlined != underline) {
      _myFontIsUnderlined = underline;
      _myResetFont = true;
    }
    if (_myFontIsStrikeThrough != strikeThrough) {
      _myFontIsStrikeThrough = strikeThrough;
      _myResetFont = true;
    }

    if (_myResetFont) {
      _myResetFont = false;
      setFontInternal(
          _myFontEntries!, size, bold, italic, underline, strikeThrough);
      _mySpaceWidth = -1;
      _myStringHeight = -1;
      _myDescent = -1;
      _myCharHeights.clear();
    }
  }

  /// 设置字体相关属性（内部实现）
  ///
  /// @param entries       字体集合
  /// @param size          字体大小
  /// @param bold          粗体
  /// @param italic        斜体
  /// @param underline     下划线
  /// @param strikeThrough 中划线
  void setFontInternal(List<FontEntry> entries, int size, bool bold,
      bool italic, bool underline, bool strikeThrough);

  /// 设置文字颜色
  ///
  /// @param color 颜色
  void setTextColor(ColorData? colorData);

  void setExtraFoot(int textSize, ColorData colorData);

  /// 设置线颜色
  ///
  /// @param color 线颜色
  void setLineColor(ColorData? colorData);

  /// 设置线的宽度
  ///
  /// @param width 线的宽度
  void setLineWidth(double width);

  /// 设置填充颜色
  ///
  /// @param color 颜色
  void setFillColor(ColorData? color) {
    setFillColorWithOpacity(color, 0xFF);
  }

  /// 设置填充颜色
  ///
  /// @param color 颜色
  /// @param alpha 透明度
  void setFillColorWithOpacity(ColorData? colorData, double opacity);

  /// 获取宽度
  ///
  /// @return 宽度
  late double width;

  /// 获取高度
  ///
  /// @return 高度
  late double height;

  /// 获取字符串宽度
  ///
  /// @param string 字符串
  /// @return 字符串宽度
  int getWordWidth(String string) {
    // return getStringWidth(string.characters, 0, string.length);
    return 0;
  }

  /// 使用{@link org.geometerplus.zlibrary.ui.android.view.ZLAndroidPaintContext.myTextPaint}获取字符串宽度
  ///
  /// @param chars 字符串数组
  /// @param offset 偏移量
  /// @param length 字符长度
  /// @return 字符串宽度
  Pair<TextPainter?, double> getStringWidth(List<String> chars, int offset, int length, {Size? stringSize});

  int getExtraWordWidth(String string) {
    return getExtraStringWidth(string.characters, 0, string.length);
  }

  int getExtraStringWidth(Characters string, int offset, int length);

  /// 获取空格宽度
  ///
  /// @return 空格宽度
  int getSpaceWidth() {
    int spaceWidth = _mySpaceWidth;
    if (spaceWidth == -1) {
      spaceWidth = getSpaceWidthInternal();
      _mySpaceWidth = spaceWidth;
    }
    return spaceWidth;
  }

  /// 获取空格宽度（内部实现）
  ///
  /// @return 空格宽度
  int getSpaceWidthInternal();

  /// 获取字符串高度
  ///
  /// @return 字符串高度
  int getStringHeight() {
    int stringHeight = _myStringHeight;
    if (stringHeight == -1) {
      stringHeight = getStringHeightInternal();
      _myStringHeight = stringHeight;
    }
    return stringHeight;
  }

  /// 获取字符串高度
  ///
  /// @return 字符串高度
  int getStringHeightInternal();

  int getCharHeight(String chr) {
    final int? h = _myCharHeights[chr];
    if (h != null) {
      return h;
    }
    final int he = getCharHeightInternal(chr);
    _myCharHeights[chr] = he;
    return he;
  }

  int getCharHeightInternal(String chr);

  int getDescent(TextPainter textPainter) {
    int descent = _myDescent;
    if (descent == -1) {
      descent = getDescentInternal(textPainter);
      _myDescent = descent;
    }
    print('ceshi123, descent = $descent');
    return descent;
  }

  /// 字符baseline到bottom到距离.
  /// 见https://www.jianshu.com/p/71cf11c120f0
  int getDescentInternal(TextPainter textPainter);

  void drawString(ui.Canvas canvas, double x, double y, List<TextSpan> content);

  /// 获得书页中的插图, 耗时操作
  Size imageSize(String imageUrl, Size maxSize, ScalingType scaling);

  void drawImage(
    ui.Canvas canvas,
    double x,
    double y,
    ImageElementPaintData imageData,
    ColorAdjustingMode adjustingMode,
  );

  /// 绘制线（抽象）
  ///
  /// @param x0 起始X
  /// @param y0 起始Y
  /// @param x1 结束X
  /// @param y1 结束Y
  void drawLine(ui.Canvas canvas, double x0, double y0, double x1, double y1);

  /// 绘制实心矩形（抽象）
  ///
  /// @param x0 起始X
  /// @param y0 起始Y
  /// @param x1 结束X
  /// @param y1 结束Y
  void fillRectangle(ui.Canvas canvas, double x0, double y0, double x1, double y1);

  void drawHeader(int x, int y, String title);

  void drawFooter(int x, int y, String progress);

  /// 绘制多边形线
  ///
  /// @param xs X坐标集合
  /// @param ys Y坐标集合
  void drawPolygonalLine(ui.Canvas canvas, List<double> xs, List<double> ys);

  /// 绘制实心多边形（抽象）
  ///
  /// @param xs X坐标集合
  /// @param ys Y坐标集合
  void fillPolygon(ui.Canvas canvas, List<double> xs, List<double> ys);

  /// 绘制轮廓线
  ///
  /// @param xs X坐标集合
  /// @param ys Y坐标集合
  void drawOutline(ui.Canvas canvas, List<double> xs, List<double> ys);

  /// 绘制实心圆（抽象）
  ///
  /// @param x      圆心X
  /// @param y      圆心Y
  /// @param radius 圆半径
  void fillCircle(ui.Canvas canvas, double x, double y, double radius);

  /// 绘制书签（抽象）
  ///
  /// @param x0 起始X
  /// @param y0 起始Y
  /// @param x1 结束X
  /// @param y1 结束Y
  void drawBookMark(ui.Canvas canvas, double x0, double y0, double x1, double y1);
}
