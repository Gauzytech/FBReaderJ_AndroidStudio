import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/page_mode.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_drag_controller.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_position.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_stage_delegate.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scroll_stage/ballistic_scroll_stage.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scroll_stage/drag_scroll_stage.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scroll_stage/idle_scroll_stage.dart';

import 'scroll_stage/hold_scroll_stage.dart';

class ReaderScrollPositionWithSingleContext extends ReaderScrollPosition
    implements ReaderScrollStageDelegate {
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
    if (scrollStage == null) {
      goIdle();
    }
    assert(scrollStage != null);
  }

  // 代表当前用户触摸操作的滚动方向, 有三种情况:
  // 1. idle, 表示没有scroll
  // 2. forward, 正数
  //  a. 垂直滚动(从上往下): 书页内容显示上边部分，上一页
  //  b. 翻页滚动(从右往左): 书页内容显示左边部分，上一页
  // 3. reverse, 负数
  //  a. 垂直滚动(从上往下): 书页内容显示下边部分，下一页
  //  b. 翻页滚动(从左往右): 书页内容显示右边部分，下一页
  @override
  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;


  /// Velocity from a previous scrollState temporarily held by [hold] to potentially
  /// transfer to a next scrollState.
  double _heldPreviousState = 0.0;

  @override
  PageMode get pageMode => context.pageMode;

  @override
  double setPixels(double newPixels) {
    assert(scrollStage!.isScrolling);
    return super.setPixels(newPixels);
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
  }

  @override
  void goIdle() {
    beginScrollStage(IdleScrollStage(this));
  }

  @override
  void goBallistic(double velocity) {
    assert(hasPixels);
    final Simulation? simulation = physics.createBallisticSimulation(this, velocity);
    if(simulation != null) {
      beginScrollStage(BallisticScrollStage(this, simulation, context.vsync));
    } else {
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

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    final double previousVelocity = scrollStage!.velocity;
    final HoldScrollStage holdStage = HoldScrollStage(
      delegate: this,
      onHoldCanceled: holdCancelCallback,
    );
    beginScrollStage(holdStage);
    _heldPreviousState = previousVelocity;
    return holdStage;
  }

  ReaderDragController? _currentDrag;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final ReaderDragController drag = ReaderDragController(
      delegate: this,
      details: details,
    );
    beginScrollStage(DragScrollStage(delegate: this, controller: drag));
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
    description.add('$scrollStage');
    description.add('$userScrollDirection');
  }
}
