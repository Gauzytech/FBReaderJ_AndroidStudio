
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../page_scroll/book_page_position.dart';
import '../page_scroll/reader_scroll_position.dart';

/// 图书内容翻页动画行为当控制器
mixin BookPagePhysics {

  /// 当用户拖动书页松开手指后，创建接下来的轨迹模拟惯性效果
  Simulation? createBallisticSimulation(
    ReaderScrollPosition position,
    double velocity,
  );

  /// 获得上一页/下一页的渲染坐标
  double getTargetPixels(BookPagePosition position, Tolerance tolerance, double velocity);

  // todo 翻译
  /// Used by [DragScrollPhase] and other user-driven activities to convert
  /// an offset in logical pixels as provided by the [DragUpdateDetails] into a
  /// delta to apply (subtract from the current position) using
  /// [ReaderScrollPhaseDelegate.setPixels].
  ///
  /// This is used by some [ReaderScrollPosition] subclasses to apply friction during
  /// overscroll situations.
  ///
  /// This method must not adjust parts of the offset that are entirely within
  /// the bounds described by the given `position`.
  ///
  /// The given `position` is only valid during this method call. Do not keep a
  /// reference to it to use later, as the values may update, may not update, or
  /// may update to reflect an entirely unrelated scrollable.
  double applyPhysicsToUserOffset(ReaderScrollPosition position, double offset);

  /// 计算模拟动画的[pixels]运动方向
  ScrollDirection getSimulationPixelsDirection(ReaderScrollPosition position, double velocity, bool reversed);
}