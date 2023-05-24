import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/reader_scroll_phase.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_phase_delegate.dart';

/// 阅读内容滚动状态：保持, 通常发生在手指按下的时候
///
/// 具体功能方法模仿[HoldScrollActivity].
class HoldScrollPhase extends ReaderScrollPhase implements ScrollHoldController {
  HoldScrollPhase({
    required ReaderScrollPhaseDelegate delegate,
    this.onHoldCanceled,
  }) : super(delegate);

  /// Called when [dispose] is called.
  final VoidCallback? onHoldCanceled;

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;

  @override
  double get velocity => 0.0;

  @override
  void cancel() {
    delegate.goBallistic(0.0);
  }

  @override
  void dispose() {
    onHoldCanceled?.call();
    super.dispose();
  }
}
