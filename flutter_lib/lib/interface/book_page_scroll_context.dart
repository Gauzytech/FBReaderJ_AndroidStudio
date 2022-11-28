import 'package:flutter/widgets.dart';

import '../reader/animation/model/user_settings/page_mode.dart';

abstract class BookPageScrollContext {

  /// A [TickerProvider] to use when animating the scroll position.
  TickerProvider get vsync;

  /// 当前书页滚动模式
  /// 翻页模式/垂直滚动模式
  PageMode get pageMode;

  /// 通知[ContentPainter]开始重绘
  void invalidateContent();
}