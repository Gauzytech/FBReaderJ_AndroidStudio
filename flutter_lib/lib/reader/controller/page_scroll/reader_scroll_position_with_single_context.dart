import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/page_mode.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state/ballistic_scroll_state.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state/idle_scroll_state.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state_delegate.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_position.dart';

import 'reader_scroll_state/hold_scroll_state.dart';

class ReaderScrollPositionWithSingleContext extends ReaderScrollPosition
    implements ReaderScrollStateDelegate {

  ReaderScrollPositionWithSingleContext({
    required super.context,
    required super.physics,
    double? initialPixels = 0.0,
  }) {
    if (!hasPixels && initialPixels != null) {
      correctPixels(initialPixels);
    }

    // 初始化当前滚动行为是静止
    if (scrollState == null) {
      goIdle();
    }
    assert(scrollState != null);
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
    assert(scrollState!.isScrolling);
    return super.setPixels(newPixels);
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    setPixels(pixels - physics.applyPhysicsToUserOffset(this, delta));
  }

  @override
  void goIdle() {
    beginScrollState(IdleScrollState(this));
  }

  @override
  void goBallistic(double velocity) {
    assert(hasPixels);
    final Simulation? simulation = physics.createBallisticSimulation(this, velocity);
    if(simulation != null) {
      beginScrollState(BallisticScrollState(this, simulation, context.vsync));
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
    final double previousVelocity = scrollState!.velocity;
    final HoldScrollState holdState = HoldScrollState(
      delegate: this,
      onHoldCanceled: holdCancelCallback,
    );
    beginScrollState(holdState);
    _heldPreviousState = previousVelocity;
    return holdState;
  }

  @override
  void dispose() {
    // _currentDrag?.dispose();
    // _currentDrag = null;
    super.dispose();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('${context.runtimeType}');
    description.add('$physics');
    description.add('$scrollState');
    description.add('$userScrollDirection');
  }
}
