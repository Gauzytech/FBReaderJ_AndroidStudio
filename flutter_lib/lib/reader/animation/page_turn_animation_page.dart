import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/modal/pair.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';
import 'package:flutter_lib/reader/animation/model/animation_data.dart';
import 'package:flutter_lib/reader/animation/model/spring_animation_range.dart';

import '../../modal/view_model_reader.dart';
import '../controller/touch_event.dart';
import 'base_animation_page.dart';

/// 滑动动画 ///
/// ps 正在研究怎么加上惯性 (ScrollPhysics:可滑动组件的滑动控制器,android 对应：ClampingScrollPhysics，ScrollController呢？)
///
/// AnimationController 有fling动画，不过需要传入滑动距离
/// ScrollPhysics 提供了滑动信息，createBallisticSimulation 方法需要传入一个position(初始化的时候创建) 和 velocity(手势监听的DragEndDetails中有速度)
/// 实在不行直接用小部件实现？
///
/// 结论：自己算个毛，交给模拟器实现去……
class PageTurnAnimation extends BaseAnimationPage {
  static const velocityThreshHold = 200;

  Offset eventStartPoint = Offset.zero;

  /// 本次触摸事件Y轴上开始的滑动距离:
  /// 1. 在moveDown事件, 会将currentMoveDy赋值给本变量,
  /// 2. currentMoveDy是用户一直滑动到现在的总滑动距离
  double mStartDx = 0;

  ///记录总滚动距离, eg: 用户手指一直滑
  double currentMoveDx = 0;

  /// 上次滑动的index
  /// 负数是下一页, 正数是上一页
  int lastIndex = 0;

  /// 翻到下一页
  bool isTurnToNext = true;

  AnimationController? _currentAnimationController;

  // todo 这两个参数干啥的？
  late Tween<Offset> currentAnimationTween;
  late Animation<Offset> currentAnimation;
  AnimationData? progressAnimation;

  final Paint _paint = Paint();

  PageTurnAnimation(
    ReaderViewModel viewModel,
    AnimationController animationController,
  ) : super(
            readerViewModel: viewModel,
            animationController: animationController) {
    _setContentViewModel(viewModel);
  }

  void _setContentViewModel(ReaderViewModel viewModel) {
    viewModel.registerContentOperateCallback((operate) {
      eventStartPoint = Offset.zero;
      mStartDx = 0;
      lastIndex = 0;
      currentMoveDx = 0;
    });
  }

  @override
  Animation<Offset>? getCancelAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    return null;
  }

  @override
  Animation<Offset>? getConfirmAnimation(
      AnimationController controller, GlobalKey canvasKey) {
    return null;
  }

  /// 惯性动画， 用户手指抬起, 或者触摸行为取消之后, 我们执行
  /// 此时需要判断是自动滑到下一页还是恢复到这一页
  @override
  Simulation getFlingAnimationSimulation(
      AnimationController controller, DragEndDetails details) {
    // 1. 计算 动画到下一页, 还是回弹回到down时候的坐标
    double velocity = details.velocity.pixelsPerSecond.dx;
    double startDx = getCachedTouchData().dx;

    Pair direction = getAnimationDirection(eventStartPoint.dx, velocity);
    bool animateToNewPage = direction.left;
    bool goNextPage = direction.right;
    double endDx = 0;

    // 2. 计算下一页的坐标
    if (animateToNewPage) {
      print('flutter动画流程:getFlingSpringSimulation, 前进');
      // 继续向前, 到下一页或者上一页
      endDx = getEndDx(goNextPage);
    } else {
      print('flutter动画流程:getFlingSpringSimulation, 回弹');
      // 回弹
      endDx = eventStartPoint.dx;
    }

    print(
        'flutter动画流程:getFlingSpringSimulation current = ${getCachedTouchData()}, '
        'path: ${eventStartPoint.dx} -> $endDx, currentMoveDx = $currentMoveDx, startX = $mStartDx');

    // 2. 创建惯性动画
    ScrollSpringSimulation simulation =
        buildSpringSimulation(getCachedTouchData().dx, endDx, velocity);
    // 3. 保存正在进行的弹簧惯性动画
    progressAnimation = AnimationData(
      start: startDx,
      end: endDx,
      velocity: velocity,
      springRange: SpringAnimationRange(
        startPageMoveDx: getPageMoveDx(getMoveDistance(eventStartPoint.dx)),
        endPageMoveDx: getPageMoveDx(getMoveDistance(endDx)),
        direction: getSpringDirection(animateToNewPage, goNextPage),
      ),
    );
    _currentAnimationController = controller;
    return simulation;
  }

  SpringDirection getSpringDirection(bool animateToNewPage, bool turnNextPage) {
    if (animateToNewPage) {
      return turnNextPage
          ? SpringDirection.rightToLeftNext
          : SpringDirection.leftToRightPrev;
    } else {
      return SpringDirection.none;
    }
  }

  /// 因为是左右翻页, 计算下一页x轴终点坐标
  double getEndDx(bool goNextPage) {
    if (goNextPage) {
      // 下一页(负数), 从down坐标开始往左平移一个屏幕的距离
      return eventStartPoint.dx - currentSize.width;
    } else {
      // 上一页(正数), 从down坐标开始往右平移一个屏幕的距离
      return eventStartPoint.dx + currentSize.width;
    }
  }

  Simulation resumeFlingAnimationSimulation() {
    // 已知: 中断动画range, 起点 -> 终点
    // resume计算终点的规则:
    // 判断当前cacheTouchPoint靠近起点还是终点, 向最靠近的点animate

    final _progressAnimation =
        ArgumentError.checkNotNull(progressAnimation, 'progressAnimation');
    double startDx = getCachedTouchData().dx;
    double distanceToStart =
        (startDx - _progressAnimation.springRange.startPageMoveDx).abs();
    double distanceToEnd =
        (startDx - _progressAnimation.springRange.startPageMoveDx).abs();
    double targetMoveDx;
    if (distanceToStart < distanceToEnd) {
      targetMoveDx = _progressAnimation.springRange.startPageMoveDx;
      print('flutter动画流程:getFlingSpringSimulation, 回弹');
    } else {
      targetMoveDx = _progressAnimation.springRange.endPageMoveDx;
      print('flutter动画流程:getFlingSpringSimulation, 前进');
    }
    double endDx = targetMoveDx - mStartDx + eventStartPoint.dx;

    print(
        'flutter动画流程:getFlingSpringSimulation, current = ${getCachedTouchData()}, '
        'path: ${eventStartPoint.dx} -> $endDx, currentMoveDx = $currentMoveDx, startX = $mStartDx');

    // 2. 创建惯性动画
    ScrollSpringSimulation simulation =
        buildSpringSimulation(startDx, endDx, progressAnimation!.velocity);
    // 3. 保存正在进行的弹簧惯性动画
    progressAnimation = progressAnimation!.copy(startDx, endDx);
    return simulation;
  }

  /// 判断动画方向，上/下一页或者回弹
  Pair getAnimationDirection(double downEventDx, double velocity) {
    final double moveDistance = getCachedTouchData().dx - downEventDx;
    // 通过最短移动距离和手指滑过的速度判断是上/下一页还是回弹
    bool animationForward =
        moveDistance.abs() > minDiff() || velocity.abs() >= velocityThreshHold;
    // 负数: 用户左滑, 向左移动一屏距离，进入下一页
    double moveDistanceX = getCachedTouchData().dx - downEventDx;
    bool goNextPage = moveDistanceX < 0;
    return Pair(animationForward, goNextPage);
  }

  /// 创建惯性动画
  ScrollSpringSimulation buildSpringSimulation(
      double start, double end, double velocity) {
    return ScrollSpringSimulation(
      const SpringDescription(
        mass: 75, //质量
        stiffness: 10, //硬度
        damping: 0.75, //阻尼系数
      ),
      start,
      end,
      velocity,
    );
  }

  @override
  void onDraw(Canvas canvas) {
    // currentMoveDy负数: 往右滚动, 正数: 往左滚动
    double actualOffsetX = currentMoveDx < 0
        ? -((currentMoveDx).abs() % currentSize.width)
        : (currentMoveDx) % currentSize.width;
    canvas.save();
    if (actualOffsetX < 0) {
      // 绘制下一页
      // 在触摸事件发生时, 已经检查过nextPage是否存在, 所以nextPage肯定不为null
      ui.Image? nextPage = readerViewModel.getPage(PageIndex.next);
      if (nextPage != null) {
        canvas.translate(actualOffsetX + currentSize.width, 0);
        canvas.drawImage(nextPage, Offset.zero, _paint);
        print('flutter动画流程:onDraw下一页, actualOffsetX = $actualOffsetX, '
            'currentMoveDx = $currentMoveDx, '
            'translate = ${actualOffsetX - currentSize.width}');
      } else {
        print('flutter动画流程:onDraw[无nextPage], actualOffsetX = $actualOffsetX, '
            'currentMoveDx = $currentMoveDx');
        // todo 移除这部分逻辑, 因为页面是否存在的检查已经在触摸事件的canScroll中进行了
        if (!isCanGoNext()) {
          lastIndex = 0;
          actualOffsetX = 0;
          currentMoveDx = 0;

          if (_currentAnimationController?.isCompleted == false) {
            _currentAnimationController?.stop();
          }
        }
      }
    } else if (actualOffsetX > 0) {
      // 绘制上一页
      // 在触摸事件发生时, 已经检查过prevPage是否存在, 所以prevPage肯定不为null
      ui.Image? prevPage = readerViewModel.getPage(PageIndex.prev);
      if (prevPage != null) {
        canvas.translate(actualOffsetX - currentSize.width, 0);
        canvas.drawImage(prevPage, Offset.zero, _paint);
        print('flutter动画流程:onDraw上一页, '
            'actualOffsetX = $actualOffsetX, '
            'currentMoveDx = $currentMoveDx, '
            'translate = ${actualOffsetX - currentSize.width}');
      } else {
        print('flutter动画流程:onDraw[无prevPage], '
            'actualOffsetX = $actualOffsetX, '
            'currentMoveDx = $currentMoveDx');
        // todo 移除这部分逻辑, 因为页面是否存在的检查已经在触摸事件的canScroll中进行了
        if (!isCanGoPre()) {
          lastIndex = 0;
          actualOffsetX = 0;
          currentMoveDx = 0;

          if (_currentAnimationController?.isCompleted == false) {
            _currentAnimationController?.stop();
          }
        }
      }
    } else {
      print('flutter动画流程:onDraw[只绘制current], '
          'actualOffsetX = $actualOffsetX, '
          'currentMoveDx = $currentMoveDx');
      _resetData();
      readerViewModel.preloadAdjacentPage();
    }

    canvas.restore();
    canvas.save();
    ui.Image? currentPage = readerViewModel.getPage(PageIndex.current);
    if (currentPage != null) {
      canvas.translate(actualOffsetX, 0);
      canvas.drawImage(currentPage, Offset.zero, _paint);
    }
    canvas.restore();
  }

  @override
  void onTouchEvent(TouchEvent event) {
    switch (event.action) {
      case EventAction.dragStart:
        // 手指按下, 保存起点
        if (!mStartDx.isNaN && !mStartDx.isInfinite) {
          print('flutter动画流程:onTouchEvent${event.touchPoint}, 保存dragStart的坐标, '
              'mStartDx = $currentMoveDx');
          eventStartPoint = event.touchPosition;
          mStartDx = currentMoveDx;
        }
        break;
      // 手指移动，或者抬起
      case EventAction.move:
      case EventAction.flingReleased:
        print(
            'flutter动画流程:onTouchEvent${event.touchPoint}, ${event.actionName}, eventStart = $eventStartPoint');
        handleEvent(event);
        break;
      case EventAction.noAnimationForward:
      case EventAction.noAnimationBackward:
        if (!mStartDx.isNaN && !mStartDx.isInfinite) {
          // 无动画翻页执行步骤
          // 1. 保存起点，就是当前触摸的坐标
          eventStartPoint = event.touchPosition;
          mStartDx = currentMoveDx;
          // 2. 计算终点, 暂时算前进
          bool goNextPage = isForward(event);
          TouchEvent end = TouchEvent(
            action: event.action,
            touchPosition: Offset(getEndDx(goNextPage), event.touchPosition.dy),
          );
          handleEvent(end);
        }
        break;
      case EventAction.dragEnd:
      case EventAction.cancel:
        // 这里不会执行, 见setCurrentTouchEvent
        break;
      default:
        break;
    }
  }

  /// 清除所有翻页用到的临时数据
  void _resetData() {
    print('flutter动画流程，翻页完毕，清理所有临时数据');
    progressAnimation = null;
    mStartDx = 0;
    lastIndex = 0;
    currentMoveDx = 0;
  }

  @override
  bool shouldCancelAnimation() {
    return true;
  }

  @override
  bool isCancelArea() {
    return false;
  }

  @override
  bool isConfirmArea() {
    return false;
  }

  /// 竖屏: 最小滑动距离 = 宽度 / 3
  /// 横屏: 最小滑动距离 = 宽度 / 4
  double minDiff() {
    // final int minDiff = myDirection.IsHorizontal
    //     ? (myWidth > myHeight ? myWidth / 4 : myWidth / 3)
    //     : (myHeight > myWidth ? myHeight / 4 : myHeight / 3);

    return currentSize.width > currentSize.height
        ? currentSize.width / 4
        : currentSize.width / 3;
  }

  void handleEvent(TouchEvent event) {
    if (!getCachedTouchData().dx.isInfinite && !eventStartPoint.dx.isInfinite) {
      // 本次滑动偏移量，其实就是dy
      double moveDistanceX = getMoveDistance(event.touchPosition.dx);
      // 如果是中断动画, 判断是否越界了
      if (progressAnimation != null) {
        double targetCurrentMoveDx = getPageMoveDx(moveDistanceX);
        if (!progressAnimation!.springRange.isWithinRange(targetCurrentMoveDx)) {
          return;
        }
      }

      if (!currentSize.width.isInfinite &&
          currentSize.width != 0 &&
          !currentMoveDx.isInfinite) {
        // 总滚动距离 / 可渲染内容container高度 = 当前页面index
        // ~/是除法, 但返回整数
        int currentIndex = (moveDistanceX + mStartDx) ~/ currentSize.width;
        if (lastIndex != currentIndex) {
          if (currentIndex < lastIndex) {
            print('flutter动画流程:handleEvent[${event.actionName}], '
                '$currentIndex vs. $lastIndex, shift下一页');
            readerViewModel.shiftPage(PageIndex.next);
            readerViewModel.onScrollingFinished(PageIndex.next);
          } else if (currentIndex + 1 > lastIndex) {
            print('flutter动画流程:handleEvent[${event.actionName}], '
                '$currentIndex vs. $lastIndex, shift上一页');
            readerViewModel.shiftPage(PageIndex.prev);
            readerViewModel.onScrollingFinished(PageIndex.prev);
          } else {
            print('flutter动画流程:handleEvent[${event.actionName}], 不操作');
          }
        }

        // 保存当前触摸的坐标, 接下来onDraw会用到
        cacheCurrentTouchData(event.touchPosition);
        isTurnToNext = moveDistanceX < 0;
        lastIndex = currentIndex;
        // 更新currentMoveDx, drawBottomPage时候使用
        if (!moveDistanceX.isInfinite && !currentMoveDx.isInfinite) {
          currentMoveDx = getPageMoveDx(moveDistanceX);
          print('flutter动画流程:handleEvent[${event.actionName}], '
              '本次事件偏移量currentMoveDx = $currentMoveDx, ${progressAnimation?.springRange}');
        }
      }
    }
  }

  double getMoveDistance(double eventDx) {
    return eventDx - eventStartPoint.dx;
  }

  double getPageMoveDx(double moveDistance) {
    return mStartDx + moveDistance;
  }

  /// 使用当前触摸event坐标与down event坐标比较, 负数为下一页, 正数为上一页
  @override
  bool isForward(TouchEvent event) {
    // 如果是无动画翻页, 点击屏幕右侧，去下一页
    if (event.action == EventAction.noAnimationForward) {
      return true;
    } else if (event.action == EventAction.noAnimationBackward) {
      // 如果是无动画翻页, 点击屏幕左侧，去上一页
      return false;
    }
    return event.touchPosition.dx - eventStartPoint.dx < 0;
  }

  @override
  bool isAnimationCloseToEnd() {
    final _progressAnimation =
        ArgumentError.checkNotNull(progressAnimation, 'progressAnimation');
    print(
        'flutter动画流程:pause, ${currentMoveDx.roundToDouble()}, vs. ${_progressAnimation.springRange}');
    return currentMoveDx.roundToDouble() ==
            _progressAnimation.springRange.startPageMoveDx ||
        currentMoveDx.roundToDouble() ==
            _progressAnimation.springRange.endPageMoveDx;
  }
}
