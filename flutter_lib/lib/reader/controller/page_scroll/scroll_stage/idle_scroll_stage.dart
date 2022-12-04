import 'package:flutter_lib/reader/controller/page_scroll/scroll_stage/reader_scroll_stage.dart';

/// 阅读内容滚动状态：静止
///
/// 具体功能方法模仿[IdleScrollActivity]
class IdleScrollStage extends ReaderScrollStage {

  IdleScrollStage(super.delegate);

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