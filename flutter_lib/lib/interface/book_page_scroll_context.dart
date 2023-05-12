import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/model/user_settings/page_mode.dart';

abstract class BookPageScrollContext {

  /// A [TickerProvider] to use when animating the scroll position.
  TickerProvider get vsync;

  /// 当前坐标系的方向
  /// right/down, [0, 0]在左上角
  /// left/up, [0, 0]在右下角
  AxisDirection get axisDirection;

  /// 当前书页滚动模式
  /// 翻页模式/垂直滚动模式
  PageMode get pageMode;

  /// 第一次进入阅读界面的内容初始化
  void initialize(int width, int height);

  /// 通知[ContentPainter]开始重绘
  void invalidateContent([String? tag]);
}