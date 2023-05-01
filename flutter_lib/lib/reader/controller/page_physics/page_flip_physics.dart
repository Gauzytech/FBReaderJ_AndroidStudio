import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_position.dart';

import 'book_page_physics.dart';

/// 水平翻页的物理行为
class PageFlipPhysics with BookPagePhysics {
  /// 创建图书滚动的物理行为.
  PageFlipPhysics();

  /// 计算滚动的默认精度, 见[ScrollPhysics], _kDefaultTolerance.
  Tolerance get tolerance => Tolerance(
        velocity: 1.0 / (0.050 * ui.window.devicePixelRatio),
        // logical pixels per second
        distance: 1.0 / ui.window.devicePixelRatio, // logical pixels
      );

  /// 回弹效果的配置, 见[ScrollPhysics], _kDefaultSpring
  SpringDescription spring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 100.0,
    ratio: 1.1,
  );

  @override
  Simulation? createBallisticSimulation(
      ReaderScrollPosition position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    final double target = getTargetPixels(position as BookPagePosition, tolerance, velocity);
    if (target != position.pixels) {
      print('flutter翻页行为[创建惯性模拟], 创建动画, ${position.pixels} -> $target');
      return ScrollSpringSimulation(spring, position.pixels, target, velocity,
          tolerance: tolerance);
    }
    return null;
  }

  @override
  double getTargetPixels(
      BookPagePosition position, Tolerance tolerance, double velocity) {
    double page = position.page!;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }

    return position.getPixelsFromPage(page.roundToDouble());
  }

  @override
  double applyPhysicsToUserOffset(ReaderScrollPosition position, double offset) {
    return offset;
  }

  @override
  String toString() => 'PageTurnPhysics';
}
