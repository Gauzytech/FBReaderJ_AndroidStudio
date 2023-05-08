import 'package:flutter/physics.dart';
import 'package:flutter/src/rendering/viewport_offset.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_position.dart';

import 'book_page_physics.dart';

/// 垂直无限滚动翻页的物理行为
class PageVerticalScrollPhysics with BookPagePhysics {
  @override
  double applyPhysicsToUserOffset(
      ReaderScrollPosition position, double offset) {
    return 0;
  }

  @override
  Simulation? createBallisticSimulation(
      ReaderScrollPosition position, double velocity) {
    return null;
  }

  @override
  double getTargetPixels(
      BookPagePosition position, Tolerance tolerance, double velocity) {
    return 0;
  }
}
