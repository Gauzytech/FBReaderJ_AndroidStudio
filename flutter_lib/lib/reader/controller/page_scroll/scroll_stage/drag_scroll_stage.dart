import 'package:flutter/foundation.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_drag_controller.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scroll_stage/reader_scroll_stage.dart';

import '../reader_scroll_stage_delegate.dart';

/// 具体功能方法模仿[DragScrollActivity].
class DragScrollStage extends ReaderScrollStage {
  DragScrollStage({
    required ReaderScrollStageDelegate delegate,
    ReaderDragController? controller,
  })  : _controller = controller,
        super(delegate);

  ReaderDragController? _controller;

  @override
  bool get isScrolling => true;

  @override
  bool get shouldIgnorePointer => true;

  @override
  double get velocity => 0.0;

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($_controller)';
  }
}
