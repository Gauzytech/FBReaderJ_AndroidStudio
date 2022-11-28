import 'package:flutter/cupertino.dart';
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';
import 'package:flutter_lib/reader/animation/cover_animation_page.dart';
import 'package:flutter_lib/reader/animation/page_turn_animation_page.dart';
import 'package:flutter_lib/reader/controller/book_page_controller.dart';
import 'package:flutter_lib/reader/controller/page_repository.dart';
import 'package:flutter_lib/reader/controller/page_physics/book_page_physics.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';
import 'package:flutter_lib/reader/controller/render_state.dart';

import '../../widget/content_painter.dart';
import '../animation/base_animation_page.dart';
import '../animation/slide_animation_page.dart';
import 'touch_event.dart';

mixin PageManagerDelegate {
  BookPageScrollContext get scrollContext;

  void updatePosition(ReaderViewModel viewModel);
}

/// 管理所有[ReaderBookContentView]的渲染行为
class ReaderPageViewModel with PageManagerDelegate {
  static const TYPE_ANIMATION_SIMULATION_TURN = 1;
  static const TYPE_ANIMATION_COVER_TURN = 2;
  static const TYPE_ANIMATION_SLIDE_TURN = 3;
  static const TYPE_ANIMATION_PAGE_TURN = 4;

  late BaseAnimationPage currentAnimationPage;
  RenderState? currentState;
  TouchEvent? currentTouchData;

  GlobalKey contentKey;
  GlobalKey topIndicatorKey;
  GlobalKey bottomIndicatorKey;
  AnimationController animationController;
  int currentAnimationType;

  // 书页滚动控制
  BookPageController get controller => _pageController!;
  BookPageController? _pageController;

  // 渲染position
  BookPagePosition get position => _position!;
  BookPagePosition? _position;

  // 当前翻页模式的滚动物理行为
  BookPagePhysics? _physics;

  @override
  BookPageScrollContext get scrollContext => _scrollContext!;
  final BookPageScrollContext? _scrollContext;

  PageRepository? _pageRepository;

  ReaderPageViewModel({
    required this.contentKey,
    required this.topIndicatorKey,
    required this.bottomIndicatorKey,
    required this.animationController,
    required this.currentAnimationType,
    required ReaderViewModel viewModel,
    BookPageController? pageController,
    BookPageScrollContext? scrollContext,
    PageRepository? pageRepository,
  })  : assert(pageController != null),
        _pageController = pageController,
        assert(scrollContext != null),
        _scrollContext = scrollContext {
    assert(pageRepository != null);
    _pageRepository = pageRepository;
    _pageRepository?.attach(this);
    _setCurrentAnimation(currentAnimationType, viewModel);
    _setAnimationController(animationController);
  }

  bool isAnimationInProgress() {
    return currentState == RenderState.ANIMATING;
  }

  bool isAnimationPaused() {
    return currentState == RenderState.ANIMATION_PAUSED;
  }

  Future<bool> canScroll(TouchEvent event) async {
    // 中断动画时发生的event
    if (isAnimationPaused()) {
      return true;
    }

    if (currentAnimationPage.isForward(event)) {
      bool canScroll =
          await _pageRepository!.canScroll(PageIndex.next);
      // 判断下一页是否存在
      bool nextExist =
          currentAnimationPage.readerViewModel.pageExist(PageIndex.next);
      print(
          "flutter动画流程:canScroll${event.touchPoint}, next canScroll: $canScroll, pageExist: $nextExist");
      if (!nextExist) {
        currentAnimationPage.readerViewModel.buildPageAsync(PageIndex.next);
      }
      return canScroll && nextExist;
    } else {
      bool canScroll =
          await currentAnimationPage.readerViewModel.canScroll(PageIndex.prev);
      // 判断上一页是否存在
      bool prevExist =
          currentAnimationPage.readerViewModel.pageExist(PageIndex.prev);
      print(
          "flutter动画流程:canScroll${event.touchPoint}, prev canScroll: $canScroll, pageExist: $prevExist");
      if (!prevExist) {
        currentAnimationPage.readerViewModel.buildPageAsync(PageIndex.prev);
      }
      return canScroll && prevExist;
    }
  }

  bool setCurrentTouchEvent(TouchEvent event) {
    /// 如果正在执行动画，判断是否需要中止动画
    switch (currentAnimationType) {
      // 左右翻页
      case TYPE_ANIMATION_PAGE_TURN:
        // 翻页惯性动画进行中
        if (isAnimationInProgress()) {
          if (event.action == EventAction.dragStart) {
            // 手指按下并开始移动
            print('flutter动画流程:中断动画${event.touchPoint}, ${event.actionName}');
            _pauseAnimation(event);
            _startTouchEvent(event);
          }
          return false;
        } else if (isAnimationPaused()) {
          // 翻页惯性动画被中断: 一般是在动画进行中手指再次触摸屏幕时发生
          if (event.action == EventAction.dragEnd) {
            print('flutter动画流程:恢复动画${event.touchPoint}, ${event.actionName}');
            // 重新计算回弹spring动画
            _resumeAnimation();
            return false;
          } else {
            // 手指移动事件
            _startTouchEvent(event);
          }
        } else {
          _startTouchEvent(event);
        }
        break;
      default:
        if (currentState == RenderState.ANIMATING) {
          if (currentAnimationPage.shouldCancelAnimation()) {
            if (event.action == EventAction.dragStart) {
              cancelAnimation();
            }
          }
        }
        _startTouchEvent(event);
    }
    return true;
  }

  void _startTouchEvent(TouchEvent event) {
    /// 用户抬起手指后，是否需要执行动画
    if (event.action == EventAction.dragEnd ||
        event.action == EventAction.cancel) {
      print('flutter动画流程:setCurrentTouchEvent${event.touchPoint}');
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
        case TYPE_ANIMATION_PAGE_TURN:
          startFlingAnimation(event.touchDetail);
          break;
        default:
          break;
      }
    } else {
      print('flutter动画流程:setCurrentTouchEvent${event.touchPoint}');
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

  void startConfirmAnimation() {
    Animation<Offset>? animation = currentAnimationPage.getConfirmAnimation(
        animationController, contentKey);

    if (animation == null) {
      return;
    }
    setAnimation(animation);
    animationController.forward();
  }

  void startCancelAnimation() {
    Animation<Offset>? animation = currentAnimationPage.getCancelAnimation(
        animationController, contentKey);

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
          scrollContext.invalidateContent();
          currentAnimationPage.onTouchEvent(TouchEvent(
              action: EventAction.move, touchPosition: animation.value));
        })
        ..addStatusListener((status) {
          switch (status) {
            case AnimationStatus.dismissed:
              break;
            case AnimationStatus.completed:
              currentState = RenderState.IDLE;
              TouchEvent event = TouchEvent(
                action: EventAction.dragEnd,
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

  void startFlingAnimation(DragEndDetails? details) {
    if (details == null) return;

    Simulation? simulation = currentAnimationPage.getFlingAnimationSimulation(
        animationController, details);

    if (animationController.isCompleted) {
      animationController.reset();
    }

    if (simulation != null) {
      animationController.animateWith(simulation);
    }
  }

  void cancelAnimation() {
    print('flutter动画流程:cancelAnimation, 中断当前惯性动画');
    if (!animationController.isCompleted) {
      animationController.stop();
      currentState = RenderState.IDLE;
      TouchEvent event = TouchEvent(
          action: EventAction.dragEnd, touchPosition: Offset.zero);
      currentAnimationPage.onTouchEvent(event);
      currentTouchData = event.copy();
    }
  }

  void _pauseAnimation(TouchEvent event) {
    if (!animationController.isCompleted) {
      print('flutter动画流程:_pauseAnimation, pause当前惯性动画');
      animationController.stop();
      currentState = RenderState.ANIMATION_PAUSED;
    }
  }

  void _resumeAnimation() {
    print('flutter动画流程:_resumeAnimation, resume当前惯性动画');
    currentState = RenderState.ANIMATING;
    Simulation simulation = (currentAnimationPage as PageTurnAnimation)
        .resumeFlingAnimationSimulation();
    animationController.animateWith(simulation);
  }

  bool shouldRepaint(
      CustomPainter oldDelegate, ContentPainter currentDelegate) {
    print('flutter内容绘制流程, shouldRepaint');
    if (currentState == RenderState.ANIMATING ||
        currentTouchData?.action == EventAction.dragStart) {
      return true;
    }

    ContentPainter oldPainter = (oldDelegate as ContentPainter);
    return oldPainter.currentTouchData != currentDelegate.currentTouchData;
  }

  void _setAnimationController(AnimationController animationController) {

    if (currentAnimationType == TYPE_ANIMATION_SLIDE_TURN ||
        currentAnimationType == TYPE_ANIMATION_PAGE_TURN) {
      animationController
        ..addListener(() {
          currentState = RenderState.ANIMATING;
          // 通知custom painter刷新
          scrollContext.invalidateContent();
          if (!animationController.value.isInfinite &&
              !animationController.value.isNaN) {
            currentAnimationPage.onTouchEvent(
              currentAnimationType == TYPE_ANIMATION_SLIDE_TURN
                  ? TouchEvent(
                      action: EventAction.move,
                      touchPosition: Offset(0, animationController.value),
                    )
                  : TouchEvent(
                      action: EventAction.flingReleased,
                      touchPosition: Offset(animationController.value, 0),
                    ),
            );
          }
        })
        ..addStatusListener((status) {
          print('flutter动画流程:动画监听, anim status update: ${status.name}');
          switch (status) {
            case AnimationStatus.dismissed:
              break;
            case AnimationStatus.completed:
              onAnimationComplete();
              break;
            case AnimationStatus.forward:
            case AnimationStatus.reverse:
              currentState = RenderState.ANIMATING;
              break;
          }
        });
    }
  }

  void onAnimationComplete() {
    currentState = RenderState.IDLE;
    currentTouchData = TouchEvent(
      action: EventAction.dragEnd,
      touchPosition: Offset.zero,
    );
  }

  bool isPageDataEmpty() {
    return _pageRepository?.isCacheEmpty() ?? true;
  }

  /* ------------------------------------------ 翻页行为 --------------------------------------------------- */
  @override
  void updatePosition(ReaderViewModel viewModel) {
    _physics = viewModel.getConfigData().getBookScrollPhysics();
    assert(_pageController != null);
    _position = controller.createBookPagePosition(_physics!, scrollContext);
    assert(_position != null);
    controller.attach(position);
  }
}
