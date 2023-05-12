import 'dart:ui';

/// 几何属性
class Geometry {
  /// 屏幕大小
  final Size screenSize;

  /// 区域大小
  final Size areaSize;

  /// 左边距
  final int leftMargin;

  /// 顶部边距
  final int topMargin;

  Geometry(int screenWidth, int screenHeight, int width, int height,
      this.leftMargin, this.topMargin)
      : screenSize = Size(screenWidth + .0, screenHeight + .0),
        areaSize = Size(width + .0, height + .0);

  Geometry.fromJson(Map<String, dynamic> json)
      : screenSize = Size(json['ScreenSize']['Width'] + .0,
            json['ScreenSize']['Height'] + .0),
        areaSize = Size(
            json['AreaSize']['Width'] + .0, json['AreaSize']['Height'] + .0),
        leftMargin = json['LeftMargin'],
        topMargin = json['TopMargin'];
}
