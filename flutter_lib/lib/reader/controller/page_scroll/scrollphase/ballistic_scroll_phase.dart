import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/reader_scroll_phase.dart';

/// 手指抬起后, onDragUp, 执行模拟惯性动画.
///
/// 具体功能方法模仿[BallisticScrollActivity].
class BallisticScrollPhase extends ReaderScrollPhase {
  BallisticScrollPhase(
    super.delegate,
    Simulation simulation,
    TickerProvider vsync,
  ) {
    _controller = AnimationController.unbounded(
      debugLabel: kDebugMode
          ? objectRuntimeType(this, 'BallisticScrollActivity')
          : null,
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateWith(simulation).whenComplete(_end);
  }

  late AnimationController _controller;

  @override
  void applyNewDimensions() {
    delegate.goBallistic(velocity);
  }

  @override
  void resetPhase() {
    delegate.goBallistic(velocity);
  }

  void _tick() {
    if (!applyMoveTo(_controller.value)) {
      delegate.goIdle();
    }
  }

  @protected
  bool applyMoveTo(double value) {
    return delegate.setPixels(value).abs() < precisionErrorTolerance;
  }

  void _end() {
    delegate.goBallistic(0.0);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => _controller.velocity;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($_controller)';
  }
}
