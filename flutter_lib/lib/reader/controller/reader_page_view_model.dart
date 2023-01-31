import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';
import 'package:flutter_lib/reader/animation/cover_animation_page.dart';
import 'package:flutter_lib/reader/animation/model/page_paint_metadata.dart';
import 'package:flutter_lib/reader/animation/page_turn_animation_page.dart';
import 'package:flutter_lib/reader/controller/page_repository.dart';
import 'package:flutter_lib/reader/controller/render_state.dart';

import '../../interface/content_selection_delegate.dart';
import '../../widget/content_painter.dart';
import '../animation/base_animation_page.dart';
import '../animation/slide_animation_page.dart';
import '../reader_content_view.dart';
import 'touch_event.dart';

mixin ReaderPageViewModelDelegate {
  BookPageScrollContext get scrollContext;

  ContentSelectionDelegate get selectionDelegate;

  ReaderViewModel get readerViewModel;

  void initialize(int width, int height);
}

/// 管理所有[ReaderBookContentView]的渲染行为
class ReaderPageViewModel with ReaderPageViewModelDelegate {
  static const TYPE_ANIMATION_SIMULATION_TURN = 1;
  static const TYPE_ANIMATION_COVER_TURN = 2;
  static const TYPE_ANIMATION_SLIDE_TURN = 3;
  static const TYPE_ANIMATION_PAGE_TURN = 4;

  late BaseAnimationPage currentAnimationPage;
  RenderState? currentState;
  TouchEvent? currentTouchData;

  GlobalKey contentKey;
  AnimationController animationController;
  int currentAnimationType;

  @override
  BookPageScrollContext get scrollContext => _scrollContext;
  final BookPageScrollContext _scrollContext;

  @override
  ContentSelectionDelegate get selectionDelegate => _selectionDelegate;
  final ContentSelectionDelegate _selectionDelegate;

  @override
  ReaderViewModel get readerViewModel => currentAnimationPage.readerViewModel;

  ReaderPageViewModel({
    required this.contentKey,
    required this.animationController,
    required this.currentAnimationType,
    required ReaderViewModel viewModel,
    required BookPageScrollContext scrollContext,
    required ContentSelectionDelegate selectionDelegate,
    required PageRepository pageRepository,
  })  : _scrollContext = scrollContext,
        _selectionDelegate = selectionDelegate {
    pageRepository.attach(this);
    viewModel.setPageRepository(pageRepository);
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
      bool canScroll = await readerViewModel.canScroll(PageIndex.next);
      // 判断下一页是否存在
      bool nextExist = readerViewModel.pageExist(PageIndex.next);
      print(
          "flutter动画流程:canScroll${event.touchPoint}, next canScroll: $canScroll, pageExist: $nextExist");
      if (!nextExist) {
        readerViewModel.buildPageAsync(PageIndex.next);
      }
      return canScroll && nextExist;
    } else {
      bool canScroll = await readerViewModel.canScroll(PageIndex.prev);
      // 判断上一页是否存在
      bool prevExist = readerViewModel.pageExist(PageIndex.prev);
      print(
          "flutter动画流程:canScroll${event.touchPoint}, prev canScroll: $canScroll, pageExist: $prevExist");
      if (!prevExist) {
        readerViewModel.buildPageAsync(PageIndex.prev);
      }
      return canScroll && prevExist;
    }
  }

  Future<bool> canScrollNew(ScrollDirection scrollDirection) async {
    switch(scrollDirection) {
      case ScrollDirection.idle:
        return false;
      case ScrollDirection.forward:
        bool canScroll = await readerViewModel.canScroll(PageIndex.prev);
        // 判断上一页是否存在
        bool prevExist = readerViewModel.pageExist(PageIndex.prev);
        if (!prevExist) {
          readerViewModel.buildPageAsync(PageIndex.prev);
        }
        return canScroll && prevExist;
      case ScrollDirection.reverse:
        bool canScroll = await readerViewModel.canScroll(PageIndex.next);
        // 判断下一页是否存在
        bool nextExist = readerViewModel.pageExist(PageIndex.next);
        if (!nextExist) {
          readerViewModel.buildPageAsync(PageIndex.next);
        }
        return canScroll && nextExist;
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

  void setPageSize(Size size) => currentAnimationPage.setSize(size);

  /// 新翻页实现
  void onPagePreDraw(PagePaintMetaData data) =>
      currentAnimationPage.onPagePreDraw(data);

  void onPageDraw(Canvas canvas) {
    if (ReaderContentViewState.newScroll) {
      currentAnimationPage.onPageDraw(canvas);
    } else {
      currentAnimationPage.onDraw(canvas);
    }
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
            action: EventAction.move,
            touchPosition: animation.value,
            pixels: -1,
          ));
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
                pixels: -1,
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
        action: EventAction.dragEnd,
        touchPosition: Offset.zero,
        pixels: -1,
      );
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
          if (!animationController.value.isInfinite &&
              !animationController.value.isNaN) {
            currentAnimationPage.onTouchEvent(
              currentAnimationType == TYPE_ANIMATION_SLIDE_TURN
                  ? TouchEvent(
                      action: EventAction.move,
                      touchPosition: Offset(0, animationController.value),
                      pixels: -1)
                  : TouchEvent(
                      action: EventAction.flingReleased,
                      touchPosition: Offset(animationController.value, 0),
                      pixels: -1),
            );
            // 通知custom painter刷新
            scrollContext.invalidateContent("动画刷新");
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
        action: EventAction.dragEnd, touchPosition: Offset.zero, pixels: -1);
  }

  /* ------------------------------------------ 翻页相关 --------------------------------------------------- */
  @override
  void initialize(int width, int height) => scrollContext.initialize(width, height);
}
