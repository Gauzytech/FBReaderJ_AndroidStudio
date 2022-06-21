import 'package:flutter/cupertino.dart';
import 'package:flutter_lib/modal/animation_type.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';
import 'package:flutter_lib/reader/animation/cover_animation_page.dart';
import 'package:flutter_lib/reader/animation/page_turn_animation_page.dart';
import 'package:flutter_lib/reader/controller/render_state.dart';

import '../../widget/content_painter.dart';
import '../animation/base_animation_page.dart';
import '../animation/slide_animation_page.dart';
import 'touch_event.dart';

class ReaderPageManager {
  static const TYPE_ANIMATION_SIMULATION_TURN = 1;
  static const TYPE_ANIMATION_COVER_TURN = 2;
  static const TYPE_ANIMATION_SLIDE_TURN = 3;
  static const TYPE_ANIMATION_PAGE_TURN = 4;

  late BaseAnimationPage currentAnimationPage;
  RenderState? currentState;
  TouchEvent? currentTouchData;

  GlobalKey canvasKey;
  AnimationController animationController;
  int currentAnimationType;

  ReaderPageManager({
    required this.canvasKey,
    required this.animationController,
    required this.currentAnimationType,
    required ReaderViewModel viewModel,
  }) {
    _setCurrentAnimation(currentAnimationType, viewModel);
    _setAnimationController(animationController);
  }

  bool isAnimationInProgress() {
    return currentState == RenderState.ANIMATING;
  }

  Future<bool> canScroll(TouchEvent event) async {
    if(currentAnimationPage.isForward(event)) {
      bool canScroll = await currentAnimationPage.readerViewModel.canScroll(PageIndex.next);
      print("flutter动画流程, $event, next canScroll: $canScroll");
      // 判断下一页是否存在
      bool nextExist = currentAnimationPage.readerViewModel.pageExist(PageIndex.next);
      if(!nextExist) {
        currentAnimationPage.readerViewModel.buildPageAsync(PageIndex.next);
      }
      return canScroll && nextExist;
    } else {
      bool canScroll = await currentAnimationPage.readerViewModel.canScroll(PageIndex.prev);
      print("flutter动画流程, $event, prev canScroll: $canScroll");
      // 判断上一页是否存在
      bool prevExist = currentAnimationPage.readerViewModel.pageExist(PageIndex.prev);
      if(!prevExist) {
        currentAnimationPage.readerViewModel.buildPageAsync(PageIndex.prev);
      }
      return canScroll && prevExist;
    }
  }

  void setCurrentTouchEvent(TouchEvent event) {
    /// 如果正在执行动画，判断是否需要中止动画
    if (currentState == RenderState.ANIMATING) {
      if (currentAnimationPage.isShouldAnimatingInterrupt()) {
        if (event.action == TouchEvent.ACTION_DOWN) {
          interruptCancelAnimation();
        }
      }
    }

    /// 用户抬起手指后，是否需要执行动画
    if (event.action == TouchEvent.ACTION_UP ||
        event.action == TouchEvent.ACTION_CANCEL) {
      print('flutter动画流程:触摸事件, 手指离开屏幕: $event');
      switch (currentAnimationType) {
        // case TYPE_ANIMATION_SIMULATION_TURN:
        case TYPE_ANIMATION_COVER_TURN:
          if (currentAnimationPage.isCancelArea()) {
            startCancelAnimation();
          } else if (currentAnimationPage.isConfirmArea()) {
            startConfirmAnimation();
          }
          break;
        case TYPE_ANIMATION_SLIDE_TURN:
          startFlingAnimation(event.touchDetail);
          break;
        case TYPE_ANIMATION_PAGE_TURN:
          startSpringAnimation(event);
          break;
        default:
          break;
      }
    } else {
      print('flutter动画流程:触摸事件, 手指未离开屏幕, onTouchEvent: $event');
      currentTouchData = event;
      currentAnimationPage.onTouchEvent(event);
    }
  }

  void setPageSize(Size size) {
    currentAnimationPage.setSize(size);
  }

  void onPageDraw(Canvas canvas) {
    currentAnimationPage.onDraw(canvas);
  }

  void _setCurrentAnimation(int animationType, ReaderViewModel viewModel) {
    // currentAnimationType = animationType;
    switch (animationType) {
      // case TYPE_ANIMATION_SIMULATION_TURN:
      //   currentAnimationPage = SimulationTurnPageAnimation();
      //   break;
      case TYPE_ANIMATION_COVER_TURN:
        currentAnimationPage = CoverPageAnimation(
            readerViewModel: viewModel,
            animationController: animationController);
        break;
      case TYPE_ANIMATION_SLIDE_TURN:
        currentAnimationPage =
            SlidePageAnimation(viewModel, animationController);
        break;
      case TYPE_ANIMATION_PAGE_TURN:
        currentAnimationPage =
            PageTurnAnimation(viewModel, animationController);
        break;
      default:
        break;
    }
  }

  int getCurrentAnimation() {
    return currentAnimationType;
  }

  // void setCurrentCanvasContainerContext(GlobalKey canvasKey) {
  //   this.canvasKey = canvasKey;
  // }

  void startConfirmAnimation() {
    Animation<Offset>? animation = currentAnimationPage.getConfirmAnimation(
        animationController, canvasKey);

    if (animation == null) {
      return;
    }
    setAnimation(animation);

    animationController.forward();
  }

  void startCancelAnimation() {
    Animation<Offset>? animation =
        currentAnimationPage.getCancelAnimation(animationController, canvasKey);

    if (animation == null) {
      return;
    }

    setAnimation(animation);

    animationController.forward();
  }

  void setAnimation(Animation<Offset> animation) {
    if (!animationController.isCompleted) {
      animation
        ..addListener(() {
          currentState = RenderState.ANIMATING;
          canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
          currentAnimationPage.onTouchEvent(TouchEvent(
              action: TouchEvent.ACTION_MOVE, touchPosition: animation.value));
        })
        ..addStatusListener((status) {
          switch (status) {
            case AnimationStatus.dismissed:
              break;
            case AnimationStatus.completed:
              currentState = RenderState.IDLE;
              TouchEvent event = TouchEvent(
                action: TouchEvent.ACTION_UP,
                touchPosition: const Offset(0, 0),
              );
              currentAnimationPage.onTouchEvent(event);
              currentTouchData = event.copy();
              animationController.stop();

              break;
            case AnimationStatus.forward:
            case AnimationStatus.reverse:
              currentState = RenderState.ANIMATING;

              break;
          }
        });
    }

    if (animationController.isCompleted) {
      animationController.reset();
    }
  }

  void startSpringAnimation(TouchEvent event) {
    if (event.touchDetail == null) return;

    Simulation? simulation = (currentAnimationPage as PageTurnAnimation)
        .getFlingSpringSimulation(animationController, event.touchDetail!);

    if (animationController.isCompleted) {
      animationController.reset();
    }

    animationController.animateWith(simulation);
  }

  void startFlingAnimation(DragEndDetails? details) {
    if (details == null) return;

    Simulation? simulation = currentAnimationPage.getFlingAnimationSimulation(
        animationController, details);

    if (animationController.isCompleted) {
      animationController.reset();
    }

    if(simulation != null) {
      animationController.animateWith(simulation);
    }
  }

  void interruptCancelAnimation() {
    print('flutter动画流程, 中断当前惯性动画');
    if (!animationController.isCompleted) {
      animationController.stop();
      currentState = RenderState.IDLE;
      TouchEvent event =
          TouchEvent(action: TouchEvent.ACTION_UP, touchPosition: Offset.zero);
      currentAnimationPage.onTouchEvent(event);
      currentTouchData = event.copy();
    }
  }

  bool shouldRepaint(CustomPainter oldDelegate, ContentPainter currentDelegate) {
    if (currentState == RenderState.ANIMATING || currentTouchData?.action == TouchEvent.ACTION_DOWN) {
      return true;
    }

    ContentPainter oldPainter = (oldDelegate as ContentPainter);
    return oldPainter.currentTouchData != currentDelegate.currentTouchData;
  }

  void _setAnimationController(AnimationController animationController) {
    // this.animationController = animationController;
    animationController.duration = const Duration(milliseconds: 300);

    if (currentAnimationType == TYPE_ANIMATION_SLIDE_TURN ||
        currentAnimationType == TYPE_ANIMATION_PAGE_TURN) {
      animationController
        ..addListener(() {
          currentState = RenderState.ANIMATING;
          // 通知custom painter刷新
          canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
          if (!animationController.value.isInfinite &&
              !animationController.value.isNaN) {
            print(
                'flutter横向翻页1, anim value update: ${animationController.value}');
            currentAnimationPage.onTouchEvent(
              currentAnimationType == TYPE_ANIMATION_SLIDE_TURN
                  ? TouchEvent(
                      action: TouchEvent.ACTION_MOVE,
                      touchPosition: Offset(0, animationController.value),
                    )
                  : TouchEvent(
                      action: TouchEvent.ACTION_FLING_RELEASED,
                      touchPosition: Offset(animationController.value, 0),
                    ),
            );
          }
        })
        ..addStatusListener((status) {
          print('flutter横向翻页惯性, anim status update: ${status.name}');
          switch (status) {
            case AnimationStatus.dismissed:
              break;

            case AnimationStatus.completed:
              currentState = RenderState.IDLE;
              TouchEvent event = TouchEvent(
                action: TouchEvent.ACTION_UP,
                touchPosition: Offset.zero,
              );
              currentAnimationPage.onTouchEvent(event);
              currentTouchData = event.copy();
              break;

            case AnimationStatus.forward:
            case AnimationStatus.reverse:
              currentState = RenderState.ANIMATING;
              break;
          }
        });
    }
  }

}
