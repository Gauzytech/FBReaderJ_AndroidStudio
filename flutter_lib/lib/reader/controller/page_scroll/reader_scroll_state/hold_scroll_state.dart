import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state/reader_scroll_state.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state_delegate.dart';

/// 阅读内容滚动状态：保持, 通常发生在手指按下的时候
/// see [HoldScrollActivity]
class HoldScrollState extends ReaderScrollState with ScrollHoldController {
  HoldScrollState({
    required ReaderScrollStateDelegate delegate,
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
