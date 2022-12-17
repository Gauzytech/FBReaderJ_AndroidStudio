import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scroll_stage/reader_scroll_stage.dart';

/// 手指抬起后, onDragUp, 执行模拟惯性动画.
///
/// 具体功能方法模仿[BallisticScrollActivity].
class BallisticScrollStage extends ReaderScrollStage {
  BallisticScrollStage(
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
  void resetActivity() {
    delegate.goBallistic(velocity);
  }

  void _tick() {
    if (!applyMoveTo(_controller.value)) {
      delegate.goIdle();
    }
  }

  @protected
  bool applyMoveTo(double value) {
    print('flutter翻页行为, 模拟动画progress, $value');
    return delegate.setPixels(value).abs() < precisionErrorTolerance;
  }

  void _end() {
    print('flutter翻页行为, 模拟动画结束');
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
