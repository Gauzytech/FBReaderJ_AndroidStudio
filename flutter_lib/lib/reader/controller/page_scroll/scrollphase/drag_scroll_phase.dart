import 'package:flutter/foundation.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_drag_controller.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/reader_scroll_phase.dart';

import '../reader_scroll_phase_delegate.dart';

/// 具体功能方法模仿[DragScrollActivity].
class DragScrollPhase extends ReaderScrollPhase {
  DragScrollPhase({
    required ReaderScrollPhaseDelegate delegate,
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
