import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/page_mode.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_drag_controller.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_phase_delegate.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_position.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/ballistic_scroll_phase.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/drag_scroll_phase.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/hold_scroll_phase.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/idle_scroll_phase.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/reader_scroll_phase.dart';

class ReaderScrollPositionWithSingleContext extends ReaderScrollPosition
    implements ReaderScrollPhaseDelegate {
  ReaderScrollPositionWithSingleContext({
    required super.context,
    required super.physics,
    double? initialPixels = 0.0,
    super.oldPosition,
  }) {
    if (!hasPixels && initialPixels != null) {
      correctPixels(initialPixels);
    }

    // 初始化当前滚动行为是静止
    if (scrollPhase == null) {
      goIdle();
    }
    assert(scrollPhase != null);
  }

  @override
  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;

  @override
  ScrollDirection get pixelsDirection => _pixelsDirection;
  ScrollDirection _pixelsDirection = ScrollDirection.idle;

  /// Velocity from a previous scrollState temporarily held by [hold] to potentially
  /// transfer to a next scrollState.
  double _heldPreviousPhaseVelocity = 0.0;

  @override
  PageMode get pageMode => context.pageMode;

  @override
  AxisDirection get axisDirection => context.axisDirection;

  @override
  double setPixels(double newPixels) {
    assert(scrollPhase!.isScrolling);
    return super.setPixels(newPixels);
  }

  @override
  void absorb(ReaderScrollPosition other) {
    super.absorb(other);
    if (other is! ReaderScrollPositionWithSingleContext) {
      goIdle();
      return;
    }
    scrollPhase!.updateDelegate(this);
    _userScrollDirection = other._userScrollDirection;
    _pixelsDirection = other._pixelsDirection;
    assert(_currentDrag == null);
    if (other._currentDrag != null) {
      _currentDrag = other._currentDrag;
      _currentDrag!.updateDelegate(this);
      other._currentDrag = null;
    }
  }

  @override
  void beginScrollPhase(ReaderScrollPhase? newPhase) {
    _heldPreviousPhaseVelocity = 0.0;
    if (newPhase == null) {
      return;
    }
    assert(newPhase.delegate == this);
    super.beginScrollPhase(newPhase);
    _currentDrag?.dispose();
    _currentDrag = null;
    if (!scrollPhase!.isScrolling) {
      updateUserScrollDirection(ScrollDirection.idle);
    }
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    updatePixelsDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
  }

  @override
  void goIdle() {
    beginScrollPhase(IdleScrollPhase(this));
  }

  /// 根据[physics]开始一个simulation, 来确定[pixels]的位置，以一定的速度开始.
  ///
  /// 此方法遵循 [ScrollPhysics.createBallisticSimulation]，
  /// 通常有两种模拟效果:
  /// 1. 回弹模拟: 发生在在当前position越界时
  /// 2. 摩擦模拟: 发生在当前position在边界之内但速度为0时
  ///
  /// velocity = logical pixels / sec.
  @override
  void goBallistic(double velocity) {
    assert(hasPixels);
    final Simulation? simulation =
        physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      bool reversed = axisDirectionIsReversed(axisDirection);
      updatePixelsDirection(physics.getSimulationPixelsDirection(this, velocity, reversed));
      beginScrollPhase(BallisticScrollPhase(this, simulation, context.vsync));
    } else {
      print('flutter翻页行为[goBallistic]: go idle');
      goIdle();
    }
  }

  /// 更新[userScrollDirection] .
  @protected
  @visibleForTesting
  void updateUserScrollDirection(ScrollDirection value) {
    if (userScrollDirection == value) {
      return;
    }
    _userScrollDirection = value;
    // todo 发送一个scrollDirection更新的通知
    // didUpdateScrollDirection(value);
  }

  void updatePixelsDirection(ScrollDirection value) {
    if (_pixelsDirection == value) {
      return;
    }
    _pixelsDirection = value;
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    final double previousVelocity = scrollPhase!.velocity;
    final HoldScrollPhase holdPhase = HoldScrollPhase(
      delegate: this,
      onHoldCanceled: holdCancelCallback,
    );
    beginScrollPhase(holdPhase);
    _heldPreviousPhaseVelocity = previousVelocity;
    return holdPhase;
  }

  ReaderDragController? _currentDrag;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final ReaderDragController drag = ReaderDragController(
      delegate: this,
      details: details,
      onDragCanceled: dragCancelCallback,
    );
    beginScrollPhase(DragScrollPhase(delegate: this, controller: drag));
    assert(_currentDrag == null);
    _currentDrag = drag;
    return drag;
  }

  @override
  void dispose() {
    _currentDrag?.dispose();
    _currentDrag = null;
    super.dispose();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${context.runtimeType}');
    description.add('$physics');
    description.add('$scrollPhase');
    description.add('$userScrollDirection');
  }
}
