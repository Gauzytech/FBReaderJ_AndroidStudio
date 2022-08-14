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
    bool turnNextPage = direction.right;
    double endDx = 0;

    // 2. 计算 下一页的坐标
    if (animateToNewPage) {
      // 继续向前, 到下一页或者上一页
      if (turnNextPage) {
        // 下一页(负数), 从down坐标开始往左平移一个屏幕的距离
        endDx = eventStartPoint.dx - currentSize.width;
      } else {
        // 上一页(正数), 从down坐标开始往右平移一个屏幕的距离
        endDx = eventStartPoint.dx + currentSize.width;
      }
      print('flutter动画流程:getFlingSpringSimulation, 前进');
    } else {
      // 回弹
      endDx = eventStartPoint.dx;
      print('flutter动画流程:getFlingSpringSimulation, 回弹');
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
        direction: getSpringDirection(animateToNewPage, turnNextPage),
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
    bool turnNextPage = moveDistanceX < 0;
    return Pair(animationForward, turnNextPage);
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
        // readerViewModel.shift(true);
        canvas.translate(actualOffsetX + currentSize.width, 0);
        canvas.drawImage(nextPage, Offset.zero, _paint);
        print('flutter动画流程:onDraw下一页, '
            'actualOffsetX = $actualOffsetX, '
            'currentMoveDx = $currentMoveDx, '
            'translate = ${actualOffsetX - currentSize.width}');
      } else {
        print('flutter动画流程:onDraw[无nextPage], '
            'actualOffsetX = $actualOffsetX, '
            'currentMoveDx = $currentMoveDx');
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
        // readerViewModel.shift(false);
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
      print('flutter动画流程:onDraw[不绘制上下页], '
          'actualOffsetX = $actualOffsetX, '
          'currentMoveDx = $currentMoveDx, 只绘制current');
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
      case TouchEvent.ACTION_DRAG_START:
        // 手指按下, 保存起点
        if (!mStartDx.isNaN && !mStartDx.isInfinite) {
          print('flutter动画流程:onTouchEvent${event.touchPoint}, 保存dragStart的坐标, '
              'mStartDx = $currentMoveDx');
          eventStartPoint = event.touchPosition;
          mStartDx = currentMoveDx;
        }
        break;
      case TouchEvent.ACTION_MOVE:
      case TouchEvent.ACTION_FLING_RELEASED:
        print(
            'flutter动画流程:onTouchEvent${event.touchPoint}, ${event.actionName}, eventStart = $eventStartPoint');
        handleEvent(event);
        break;
      case TouchEvent.ACTION_DRAG_END:
        break;
      case TouchEvent.ACTION_ANIMATION_DONE:
        print(
            'flutter动画流程:onTouchEvent${event.touchPoint}, ANIMATION_DONE, 动画执行完毕, 清理坐标数据');
        // 动画执行完毕，清除进行中的动画数据
        progressAnimation = null;
        mStartDx = 0;
        lastIndex = 0;
        currentMoveDx = 0;
        break;
      case TouchEvent.ACTION_CANCEL:
        // 这里不会执行, 见setCurrentTouchEvent
        break;
      default:
        break;
    }
  }

  @override
  bool shouldCancelAnimation() {
    return true;
  }

  void drawStatic(Canvas canvas) {}

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
                '$currentIndex vs. $lastIndex,'
                'shift下一页');
            // 翻页完成了, 进行img shift操作
            // if (isCanGoNext()) {
            //   readerViewModel.nextPage();
            // } else {
            //   return;
            // }
            readerViewModel.shiftPage(PageIndex.next);
            readerViewModel.onScrollingFinished(PageIndex.next);
          } else if (currentIndex + 1 > lastIndex) {
            print('flutter动画流程:handleEvent[${event.actionName}], '
                '$currentIndex vs. $lastIndex, '
                'shift上一页');
            // 翻页完成了, 进行img shift操作
            // if (isCanGoPre()) {
            //   readerViewModel.prePage();
            // } else {
            //   return;
            // }
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
