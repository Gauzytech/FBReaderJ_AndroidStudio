import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';

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

  // late ClampingScrollPhysics physics;

  // Offset eventStartPoint = Offset.zero;

  /// 本次触摸事件Y轴上开始的滑动距离:
  /// 1. 在moveDown事件, 会将currentMoveDy赋值给本变量,
  /// 2. currentMoveDy是用户一直滑动到现在的总滑动距离
  // double mStartDy = 0;

  ///记录总滚动距离, eg: 用户手指一直滑
  // double currentMoveDy = 0;

  /// 本次touch事件滑动偏移量
  // double dy = 0;

  /// 上次滑动的index
  /// 负数是下一页, 正数是上一页
  // int lastIndex = 0;

  /// 翻到下一页
  // bool isTurnToNext = true;

  AnimationController? _currentAnimationController;

  /// beta
  Offset eventStartPointBeta = Offset.zero;
  double mStartDx = 0;
  double currentMoveDx = 0;
  double dx = 0;
  int lastIndexBeta = 0;
  bool isTurnToNextBeta = true;

  // todo 这两个参数干啥的？
  late Tween<Offset> currentAnimationTween;
  late Animation<Offset> currentAnimation;

  final Paint _paint = Paint();

  PageTurnAnimation(
    ReaderViewModel viewModel,
    AnimationController animationController,
  ) : super(
            readerViewModel: viewModel,
            animationController: animationController) {
    // physics = const ClampingScrollPhysics();
    _setContentViewModel(viewModel);
  }

  void _setContentViewModel(ReaderViewModel viewModel) {
    viewModel.registerContentOperateCallback((operate) {
      eventStartPointBeta = Offset.zero;
      mStartDx = 0;
      dx = 0;
      lastIndexBeta = 0;
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
    ClampingScrollSimulation simulation;

    // 惯性动画模拟器
    simulation = ClampingScrollSimulation(
      position: mTouchBeta.dx,
      velocity: details.velocity.pixelsPerSecond.dx,
      tolerance: Tolerance.defaultTolerance,
    );
    _currentAnimationController = controller;
    return simulation;
  }

  Simulation getFlingSpringSimulation(
      AnimationController controller, DragEndDetails details) {

    // 1. 计算 动画到下一页, 还是回弹回到down时候的坐标
    final double moveDistance = mTouchBeta.dx - eventStartPointBeta.dx;
    double velocity = details.velocity.pixelsPerSecond.dx;
    bool animationForward =
        moveDistance.abs() > minDiff() || velocity.abs() >= velocityThreshHold;

    double moveDistanceX = mTouchBeta.dx - eventStartPointBeta.dx;
    bool turnNextPage = moveDistanceX < 0;
    double destDx = 0;
    // 2. 计算 下一页的坐标
    if (animationForward) {
      // 继续向前, 到下一页或者上一页
      if (turnNextPage) {
        destDx = eventStartPointBeta.dx - currentSize.width;
      } else {
        destDx = eventStartPointBeta.dx + currentSize.width;
      }
    } else {
      // 回弹
      destDx = eventStartPointBeta.dx;
    }

    print('flutter惯性计算, velocity = $velocity, '
        'path: ${mTouchBeta.dx} -> ${eventStartPointBeta.dx} '
        'destDx = $destDx, animComplete: ${_currentAnimationController?.isAnimating}');

    ScrollSpringSimulation simulation = ScrollSpringSimulation(
      const SpringDescription(
        mass: 50, //质量
        stiffness: 10, //硬度
        damping: 0.75, //阻尼系数
      ),
      mTouchBeta.dx,
      destDx,
      velocity,
    );
    _currentAnimationController = controller;
    return simulation;
  }

  @override
  void onDraw(Canvas canvas) {
    drawBottomPage(canvas);
  }

  @override
  void onTouchEvent(TouchEvent event) {
    // if (event.touchPos == null) {
    //   return;
    // }

    switch (event.action) {
      case TouchEvent.ACTION_DOWN:
        // 手指按下, 保存起点
        if (!dx.isNaN && !dx.isInfinite) {
          print("flutter横向翻页1, down: ${event.touchPosition}, isAnimating = ${animationController.isAnimating}");
          eventStartPointBeta = event.touchPosition;
          mStartDx = currentMoveDx;
          dx = 0;
        }

        break;
      case TouchEvent.ACTION_MOVE:
        print("flutter横向翻页1, ACTION_MOVE eventX: ${event.touchPosition.dx}");
        handleEvent(event);
        break;
      case TouchEvent.ACTION_FLING_RELEASED:
        print('flutter横向翻页惯性, fling released, $event');
        handleEvent(event);
        break;
      case TouchEvent.ACTION_UP:
        print('flutter惯性计算, 动画执行完毕');
        // eventStartPointBeta = Offset.zero;
        // mStartDx = 0;
        // dx = 0;
        // lastIndexBeta = 0;
        // currentMoveDx = 0;
        break;
      case TouchEvent.ACTION_CANCEL:
        // 这里不会执行, 见setCurrentTouchEvent
        break;
      default:
        break;
    }
  }

  @override
  bool isShouldAnimatingInterrupt() {
    return true;
  }

  void drawBottomPage(Canvas canvas) {
    // currentMoveDy负数: 往右滚动, 正数: 往左滚动
    double actualOffsetX = currentMoveDx < 0
        ? -((currentMoveDx).abs() % currentSize.width)
        : (currentMoveDx) % currentSize.width;
    canvas.save();
    if (actualOffsetX < 0) {
      // 绘制下一页
      if (readerViewModel.getNextOrPrevPageDebug(true) != null) {
        canvas.translate(actualOffsetX + currentSize.width, 0);
        canvas.drawImage(readerViewModel.getNextOrPrevPageDebug(true)!, Offset.zero, _paint);
        print("flutter横向翻页2, actualOffsetX = $actualOffsetX, currentMoveDx = $currentMoveDx, draw下一页");
      } else {
        if (!isCanGoNext()) {
          dx = 0;
          actualOffsetX = 0;
          currentMoveDx = 0;

          if (_currentAnimationController != null &&
              !_currentAnimationController!.isCompleted) {
            _currentAnimationController!.stop();
          }
        }
      }
    } else if (actualOffsetX > 0) {
      // 绘制上一页
      if (readerViewModel.getNextOrPrevPageDebug(false) != null) {
        canvas.translate(actualOffsetX - currentSize.width, 0);
        canvas.drawImage(readerViewModel.getNextOrPrevPageDebug(false)!, Offset.zero, _paint);
        print("flutter横向翻页2, actualOffsetX = $actualOffsetX, currentMoveDx = $currentMoveDx, draw上一页");
      } else {
        if (!isCanGoPre()) {
          dx = 0;
          lastIndexBeta = 0;
          actualOffsetX = 0;
          currentMoveDx = 0;

          if (_currentAnimationController != null &&
              !_currentAnimationController!.isCompleted) {
            _currentAnimationController!.stop();
          }
        }
      }
    }

    canvas.restore();
    canvas.save();
    if (readerViewModel.getCurrentPage() != null) {
      canvas.translate(actualOffsetX, 0);
      canvas.drawImage(readerViewModel.getCurrentPage()!, Offset.zero, Paint());
    }
    canvas.restore();
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
    if (!mTouchBeta.dx.isInfinite && !eventStartPointBeta.dx.isInfinite) {
      // 本次滑动偏移量，其实就是dy
      double moveDistanceX = event.touchPosition.dx - eventStartPointBeta.dx;
      if (!currentSize.width.isInfinite &&
          currentSize.width != 0 &&
          !dx.isInfinite &&
          !currentMoveDx.isInfinite) {
        // 总滚动距离 / 可渲染内容container高度 = 当前页面index
        // ~/是除法, 但返回整数
        int currentIndex = (moveDistanceX + mStartDx) ~/ currentSize.width;
        print(
            "flutter横向翻页1, eventX: ${event.touchPosition.dx}, startPointX: ${eventStartPointBeta.dx}, "
                "currentIdx = $currentIndex. mStartDx = $mStartDx");
        if (lastIndexBeta != currentIndex) {
          if (currentIndex < lastIndexBeta) {
            print('flutter横向翻页, 下一页');
            if (isCanGoNext()) {
              readerViewModel.nextPage();
            } else {
              return;
            }
          } else if (currentIndex + 1 > lastIndexBeta) {
            print('flutter横向翻页, 上一页');

            if (isCanGoPre()) {
              readerViewModel.prePage();
            } else {
              return;
            }
          }
        }

        // if (moveDistanceX < 0 && moveDistanceX.abs() >= currentSize.width) {
        //   print('flutter横向翻页2, 切换到下一页');
        //   if (isCanGoNext()) {
        //     readerViewModel.nextPage();
        //   } else {
        //     return;
        //   }
        // } else if (moveDistanceX > 0 && moveDistanceX.abs() >= currentSize.width) {
        //   print('flutter横向翻页2, 切换到上一页');
        //   if (isCanGoPre()) {
        //     readerViewModel.prePage();
        //   } else {
        //     return;
        //   }
        // }

        // 保存当前触摸的坐标, 接下来onDraw会用到
        mTouchBeta = event.touchPosition;
        // 保存当前滑动偏移量
        dx = moveDistanceX;
        isTurnToNextBeta = moveDistanceX < 0;
        lastIndexBeta = currentIndex;
        // 更新currentMoveDx, drawBottomPage时候使用
        if (!dx.isInfinite && !currentMoveDx.isInfinite) {
          currentMoveDx = mStartDx + dx;
        }
      }
    }
  }

  /// 使用当前触摸event坐标与down event坐标比较, 负数为下一页, 正数为上一页
  @override
  bool isForward(TouchEvent event) {
    print("翻页检查, start: ${eventStartPointBeta.dx}, $event");
    double moveDistanceX = event.touchPosition.dx - eventStartPointBeta.dx;
    return moveDistanceX < 0;
  }
}
