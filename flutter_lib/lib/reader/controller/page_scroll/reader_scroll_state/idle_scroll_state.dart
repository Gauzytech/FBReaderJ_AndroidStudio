import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state/reader_scroll_state.dart';

/// 阅读内容滚动状态：静止
/// see [IdleScrollActivity]
class IdleScrollState extends ReaderScrollState {

  IdleScrollState(super.delegate);

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