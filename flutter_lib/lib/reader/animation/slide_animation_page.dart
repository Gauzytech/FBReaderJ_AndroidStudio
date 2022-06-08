import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';

import '../controller/touch_event.dart';
import 'base_animation_page.dart';

/// 滑动动画 ///
/// ps 正在研究怎么加上惯性 (ScrollPhysics:可滑动组件的滑动控制器,android 对应：ClampingScrollPhysics，ScrollController呢？)///
/// AnimationController 有fling动画，不过需要传入滑动距离
/// ScrollPhysics 提供了滑动信息，createBallisticSimulation 方法需要传入一个position(初始化的时候创建) 和 velocity(手势监听的DragEndDetails中有速度)
/// 实在不行直接用小部件实现？
///
/// 结论：自己算个毛，交给模拟器实现去……
class SlidePageAnimation extends BaseAnimationPage {
  late ClampingScrollPhysics physics;

  Offset mStartPoint = Offset.zero;
  double mStartDy = 0;
  double currentMoveDy = 0;

  /// 滑动偏移量
  double dy = 0;

  /// 上次滑动的index
  int lastIndex = 0;

  /// 翻到下一页
  bool isTurnToNext = true;

  AnimationController? _currentAnimationController;

  // todo 这两个参数干啥的？
  late Tween<Offset> currentAnimationTween;
  late Animation<Offset> currentAnimation;

  SlidePageAnimation(
    ReaderViewModel viewModel,
    AnimationController animationController,
  ) : super(
            readerViewModel: viewModel,
            animationController: animationController) {
    physics = const ClampingScrollPhysics();
    _setContentViewModel(viewModel);
  }

  void _setContentViewModel(ReaderViewModel viewModel) {
    // super.setContentViewModel(viewModel);
    viewModel.registerContentOperateCallback((operate) {
      mStartPoint = Offset.zero;
      mStartDy = 0;
      dy = 0;
      lastIndex = 0;
      currentMoveDy = 0;
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

  @override
  Simulation getFlingAnimationSimulation(
      AnimationController controller, DragEndDetails details) {
    ClampingScrollSimulation simulation;
    simulation = ClampingScrollSimulation(
      position: mTouch.dy,
      velocity: details.velocity.pixelsPerSecond.dy,
      tolerance: Tolerance.defaultTolerance,
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
        if (!dy.isNaN && !dy.isInfinite) {
          mStartPoint = event.touchPosition;
          mStartDy = currentMoveDy;
          dy = 0;
        }

        break;
      case TouchEvent.ACTION_MOVE:
        if (!mTouch.dy.isInfinite && !mStartPoint.dy.isInfinite) {
          double tempDy = event.touchPosition.dy - mStartPoint.dy;
          if (!currentSize.height.isInfinite &&
              currentSize.height != 0 &&
              !dy.isInfinite &&
              !currentMoveDy.isInfinite) {
            int currentIndex = (tempDy + mStartDy) ~/ currentSize.height;

            if (lastIndex != currentIndex) {
              if (currentIndex < lastIndex) {
                if (isCanGoNext()) {
                  readerViewModel.nextPage();
                } else {
                  return;
                }
              } else if (currentIndex + 1 > lastIndex) {
                if (isCanGoPre()) {
                  readerViewModel.prePage();
                } else {
                  return;
                }
              }
            }

            mTouch = event.touchPosition;
            dy = mTouch.dy - mStartPoint.dy;
            isTurnToNext = mTouch.dy - mStartPoint.dy < 0;
            lastIndex = currentIndex;
            if (!dy.isInfinite && !currentMoveDy.isInfinite) {
              currentMoveDy = mStartDy + dy;
            }
          }
        }
        break;
      case TouchEvent.ACTION_UP:
      case TouchEvent.ACTION_CANCEL:
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
    double actualOffset = currentMoveDy < 0
        ? -((currentMoveDy).abs() % currentSize.height)
        : (currentMoveDy) % currentSize.height;

    canvas.save();
    if (actualOffset < 0) {
      if (readerViewModel.getNextOrPrevPageDebug(true) != null) {
        canvas.translate(0, actualOffset + currentSize.height);
        // canvas.drawPicture(readerViewModel.getNextPage().pagePicture);
        canvas.drawImage(readerViewModel.getNextOrPrevPageDebug(true)!,
            Offset.zero, Paint());
        print("flutter动画流程, 滚动翻页, $actualOffset, draw下一页");
      } else {
        if (!isCanGoNext()) {
          dy = 0;
          actualOffset = 0;
          currentMoveDy = 0;

          if (_currentAnimationController != null &&
              !_currentAnimationController!.isCompleted) {
            _currentAnimationController!.stop();
          }
        }
      }
    } else if (actualOffset > 0) {
      if (readerViewModel.getPrePage() != null) {
        canvas.translate(0, actualOffset - currentSize.height);
        // canvas.drawPicture(readerViewModel.getPrePage().pagePicture);
        canvas.drawImage(readerViewModel.getPrePage()!, Offset.zero, Paint());
        print("flutter动画流程, 滚动翻页, $actualOffset, draw上一页");
      } else {
        if (!isCanGoPre()) {
          dy = 0;
          lastIndex = 0;
          actualOffset = 0;
          currentMoveDy = 0;

          if (_currentAnimationController != null &&
              !_currentAnimationController!.isCompleted) {
            _currentAnimationController!.stop();
          }
        }
      }
    }

    canvas.restore();
    canvas.save();

    // if (readerViewModel.getCurrentPage().pagePicture != null) {
    //   canvas.translate(0, actualOffset);
    //   canvas.drawPicture(readerViewModel.getCurrentPage().pagePicture);
    // }

    if (readerViewModel.getCurrentPage() != null) {
      canvas.translate(0, actualOffset);
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

  @override
  bool isForward(TouchEvent event) {
    return event.touchPosition.dy - mStartPoint.dy < 0;
  }
}
