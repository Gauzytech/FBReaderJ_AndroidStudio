import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/reader_scroll_phase.dart';

/// 阅读内容滚动状态：静止
///
/// 具体功能方法模仿[IdleScrollActivity]
class IdleScrollPhase extends ReaderScrollPhase {

  IdleScrollPhase(super.delegate);

  @override
  void applyNewDimensions() {
    delegate.goBallistic(0.0);
  }

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;

  @override
  double get velocity => 0.0;
}