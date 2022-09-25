import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lib/modal/base_view_model.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';
import 'package:flutter_lib/reader/controller/touch_event.dart';
import 'package:flutter_lib/reader/handler/selelction_event_handler.dart';
import 'package:flutter_lib/widget/base/base_stateful_view.dart';
import 'package:flutter_lib/widget/content_painter.dart';
import 'package:provider/provider.dart';

import 'animation/controller_animation_with_listener_number.dart';
import 'controller/page_pan_gesture_recognizer.dart';
import 'controller/reader_content_handler.dart';
import 'controller/reader_page_manager.dart';

class ReaderWidget extends BaseStatefulView<ReaderViewModel> {
  // 放大镜的半径
  static const double radius = 124;
  static const double targetDiameter = 2 * radius * 333 / 293;
  static const double magnifierMargin = 144;

  // 放大倍数
  static const double factor = 1;

  // 画笔
  // Paint myPaint = Paint();

  // 页脚的bitmap
  // private Bitmap myFooterBitmap;

  const ReaderWidget({Key? key}) : super(key: key);

  @override
  BaseStatefulViewState<BaseStatefulView<BaseViewModel>, ReaderViewModel>
  buildState() {
    return ReaderBookContentViewState();
  }

// ui.Image drawOnBitmap() {
//   ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//   Canvas canvas = Canvas(pictureRecorder);
//
//   canvas.drawImage(image, offset, paint);
//
//
// }
}

class ReaderBookContentViewState extends BaseStatefulViewState<ReaderWidget, ReaderViewModel>
    with TickerProviderStateMixin {
  final _methodChannel = const MethodChannel('platform_channel_methods');

  // 翻页倒计时
  Timer? _timer;
  int currentTimer = 0;

  // 图书主内容区域
  final GlobalKey contentKey = GlobalKey();
  final GlobalKey topIndicatorKey = GlobalKey();
  final GlobalKey bottomIndicatorKey = GlobalKey();
  double _topStartIndicatorOpacity = 0;
  double _bottomEndIndicatorOpacity = 0;

  ContentPainter? _contentPainter;

  AnimationController? animationController;

  late ReaderContentHandler _readerContentHandler;
  late SelectionEventHandler _selectionHandler;

  @override
  void onInitState() {
    // handler必须在这里初始化, 因为里面注册了原生交互的方法, 只能执行一次
    _readerContentHandler = ReaderContentHandler(
        methodChannel: _methodChannel,
        readerBookContentViewState: this);
    _selectionHandler = SelectionEventHandler(
        readerContentHandler: _readerContentHandler,
        topIndicatorKey: topIndicatorKey,
        bottomIndicatorKey: bottomIndicatorKey);
  }

  @override
  void loadData(BuildContext context, ReaderViewModel? viewModel) {
    ReaderViewModel readerViewModel = ArgumentError.checkNotNull(viewModel, 'ReaderViewModel');

    switch (readerViewModel.getConfigData().currentAnimationMode) {
    // case ReaderPageManager.TYPE_ANIMATION_SIMULATION_TURN:
      case ReaderPageManager.TYPE_ANIMATION_COVER_TURN:
        animationController = AnimationControllerWithListenerNumber(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        );
        break;
      case ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN:
      case ReaderPageManager.TYPE_ANIMATION_PAGE_TURN:
        animationController = AnimationControllerWithListenerNumber.unbounded(
          duration: const Duration(milliseconds: 150),
          vsync: this,
        );
        break;
    }

    if (animationController != null) {
      readerViewModel.getConfigData().currentAnimationMode =
          ReaderPageManager.TYPE_ANIMATION_PAGE_TURN;

      ReaderPageManager pageManager = ReaderPageManager(
          canvasKey: contentKey,
          topIndicatorKey: topIndicatorKey,
          bottomIndicatorKey: bottomIndicatorKey,
          animationController: animationController!,
          currentAnimationType:
          readerViewModel.getConfigData().currentAnimationMode,
          viewModel: readerViewModel);
      readerViewModel.setContentHandler(_readerContentHandler);
      _contentPainter = ContentPainter(pageManager);
    }

    // 透明状态栏
    // SystemChrome.setSystemUIOverlayStyle(
    //   const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
    // );
  }

  @override
  Widget onBuildView(BuildContext context, ReaderViewModel? viewModel) {
    ReaderViewModel readerViewModel =
    ArgumentError.checkNotNull(viewModel, 'ReaderViewModel');

    final contentSize = readerViewModel.getContentSize();
    return FittedBox(
      // GestureDetector需要放在fittedBox里，
      // 不然触摸事件的localPosition没有通过density转化为真正的屏幕坐标系
      child: RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: <Type, GestureRecognizerFactory>{
          PagePanDragRecognizer:
              GestureRecognizerFactoryWithHandlers<PagePanDragRecognizer>(
            () => PagePanDragRecognizer(),
            (PagePanDragRecognizer recognizer) {
              recognizer.setMenuOpen(false);
              recognizer.onStart = (detail) {
                if (_selectionHandler.isSelectionMenuShown()) {
                  _selectionHandler.onSelectionDragStart(detail);
                  var indicator = _selectionHandler.enableCrossPageIndicator(
                      context, detail.localPosition);
                  if (indicator != null) {
                    showIndicator(indicator, detail.localPosition);
                  }
                } else {
                  print(
                      "flutter动画流程[onDragStart], 进行翻页操作${detail.localPosition}");
                  onDragStart(detail, readerViewModel);
                }
              };
              recognizer.onUpdate = (detail) {
                if (_selectionHandler.isSelectionMenuShown()) {
                  _selectionHandler.onSelectionDragMove(detail);
                  var indicator = _selectionHandler.enableCrossPageIndicator(
                      context, detail.localPosition);
                  if (indicator != null) {
                    showIndicator(indicator, detail.localPosition);
                  } else {
                    hideIndicator();
                  }
                } else if (!readerViewModel.getMenuOpenState()) {
                  print(
                      'flutter动画流程[onDragUpdate], 进行翻页操作${detail.localPosition}');
                  onUpdateEvent(detail, readerViewModel);
                } else {
                  print(
                      'flutter动画流程[onDragUpdate], 忽略事件${detail.localPosition}');
                }
              };
              recognizer.onEnd = (detail) {
                if (_selectionHandler.isSelectionMenuShown()) {
                  _selectionHandler.onSelectionDragEnd(detail);
                  hideIndicator();
                } else if (!readerViewModel.getMenuOpenState()) {
                  print("flutter动画流程[onDragEnd], 进行翻页操作$detail");
                  onEndEvent(detail, readerViewModel);
                } else {
                  print('flutter动画流程[onDragEnd], 忽略事件$detail');
                }
              };
            },
          ),
          LongPressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(),
                (LongPressGestureRecognizer recognizer) {
              recognizer.onLongPressStart = (detail) {
                _selectionHandler.setSelectionMenuState(true);
                _selectionHandler.onLongPressStart(detail);
              };
              recognizer.onLongPressMoveUpdate = (detail) {
                _selectionHandler.onLongPressMoveUpdate(detail);
              };
              recognizer.onLongPressUp = () {
                _selectionHandler.onLongPressUp();
              };
            },
          ),
          TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  () => TapGestureRecognizer(),
                  (TapGestureRecognizer recognizer) {
                recognizer.onTapUp = (detail) {
                  if (_selectionHandler.isSelectionMenuShown()) {
                    _selectionHandler.onTagUp(detail);
                    _selectionHandler.setSelectionMenuState(false);
                  } else {
                    navigatePageWithoutAnimation(detail.localPosition, null);
              }
                };
              })
        },
        child: Stack(
          children: <Widget>[
            SizedBox(
              width: contentSize[0],
              height: contentSize[1],
              child: RepaintBoundary(
                child: CustomPaint(
                  key: contentKey,
                  painter: _contentPainter,
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: _topStartIndicatorOpacity,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Container(
                    key: topIndicatorKey,
                    width: 150,
                    height: 150,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: _bottomEndIndicatorOpacity,
                child: Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: Container(
                    key: bottomIndicatorKey,
                    width: 150,
                    height: 150,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  ReaderViewModel? buildViewModel(BuildContext context) {
    return Provider.of<ReaderViewModel>(context);
  }

  @override
  bool isBindViewModel() {
    return false;
  }

  void refreshContentPainter() {
    print('flutter内容绘制流程, refreshContentPainter, ${contentKey.currentContext != null}');
    contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
  }

  @override
  void dispose() {
    animationController?.dispose();
    _cancelTimer();
    super.dispose();
  }

  void onDragStart(DragStartDetails detail, ReaderViewModel readerViewModel) {
    // 如果动画正在进行, 直接忽略event
    if (!_contentPainter!.isDuplicateEvent(
      EventAction.dragStart,
      detail.localPosition,
    )) {
      _contentPainter?.setCurrentTouchEvent(
        TouchEvent.fromOnDown(
          EventAction.dragStart,
          detail.localPosition,
        ),
      );
      _contentPainter
          ?.startCurrentTouchEvent(_contentPainter!.currentTouchData!);
      contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
    }
  }

  Future<void> onUpdateEvent(DragUpdateDetails detail, ReaderViewModel readerViewModel) async {
    if (!_contentPainter!.isDuplicateEvent(
      EventAction.move,
      detail.localPosition,
    )) {
      TouchEvent event = TouchEvent.fromOnUpdate(
        EventAction.move,
        detail.localPosition,
      );
      _contentPainter?.setCurrentTouchEvent(event);
      // 检查上一页/下一页是否存在
      if (await _contentPainter!.canScroll(event)) {
        if (_contentPainter?.startCurrentTouchEvent(event) == true) {
          contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
        } else {
          print('flutter动画流程:忽略onUpdate: ${detail.localPosition}');
        }
      }
    }
  }

  Future<void> onEndEvent(DragEndDetails detail, ReaderViewModel readerViewModel) async {
    if (!_contentPainter!.isDuplicateEvent(
      EventAction.dragEnd,
      _contentPainter!.lastTouchPosition(),
    )) {
      TouchEvent event = TouchEvent<DragEndDetails>.fromOnEnd(
        EventAction.dragEnd,
        _contentPainter!.lastTouchPosition(),
        detail,
      );
      _contentPainter?.setCurrentTouchEvent(event);
      // 检查上一页/下一页是否存在
      if (await _contentPainter!.canScroll(event)) {
        _contentPainter?.startCurrentTouchEvent(event);
        contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
      }
    }
  }

  // 根据点击区域实现无动画翻页
  Future<void> navigatePageWithoutAnimation(
      Offset touchPosition, SelectionIndicator? indicator) async {
    var eventAction = getEventAction(touchPosition, indicator);
    if (eventAction != null) {
      TouchEvent event =
          TouchEvent(action: eventAction, touchPosition: touchPosition);
      if (await _contentPainter!.canScroll(event)) {
        _contentPainter?.startCurrentTouchEvent(event);
        contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
      }
    }
  }

  EventAction? getEventAction(
      Offset? touchPosition, SelectionIndicator? indicator) {
    switch (indicator) {
      case SelectionIndicator.topStart:
        // 上一页
        return EventAction.noAnimationBackward;
      case SelectionIndicator.bottomEnd:
        // 下一页
        return EventAction.noAnimationForward;
      default:
        double widthPx = ui.window.physicalSize.width;
        double ratio = 0.25;
        var prevPageRegion = [0, (widthPx * ratio).round()];
        var nextPageRegion = [(widthPx - widthPx * ratio).round(), widthPx];
        if (touchPosition!.dx >= prevPageRegion[0] &&
            touchPosition.dx <= prevPageRegion[1]) {
          // 上一页
          return EventAction.noAnimationBackward;
        } else if (touchPosition.dx >= nextPageRegion[0] &&
            touchPosition.dx <= nextPageRegion[1]) {
          // 下一页
          return EventAction.noAnimationBackward;
        } else {
          return null;
        }
    }
  }

  void showIndicator(SelectionIndicator indicator, Offset touchPosition) {
    if (indicator == SelectionIndicator.topStart) {
      if (_topStartIndicatorOpacity == 0) {
        setState(() {
          _topStartIndicatorOpacity = 1;
        });
        startTimer(indicator, touchPosition);
      }
    } else {
      if (_bottomEndIndicatorOpacity == 0) {
        setState(() {
          _bottomEndIndicatorOpacity = 1;
        });
        startTimer(indicator, touchPosition);
      }
    }
  }

  void startTimer(SelectionIndicator indicator, Offset touchPosition) {
    if(_timer == null) {
      print('倒计时, 倒计时开始: $currentTimer');
      _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        currentTimer++;
        print('倒计时, 倒计时进行中: $currentTimer');
        // 倒计时结束，取消倒计时并进行翻页操作
        if (currentTimer == 4) {
          print('倒计时, 倒计时结束: $currentTimer, 进行翻页');
          _cancelTimer();
          // todo
          //  1. 5页的翻页划选限制
          //  2. 现在上一页选中文字会在翻页之后丢失,
          //  3. 选中所有翻页页面的文字
          //  4. 处理图片选中
          navigatePageWithoutAnimation(touchPosition, indicator);
        }
      });
    }
  }

  void hideIndicator() {
    if (_topStartIndicatorOpacity == 1) {
      // 显示翻页划选区域, 并启动倒计时
      setState(() {
        _topStartIndicatorOpacity = 0;
      });
      _cancelTimer();
    }

    if (_bottomEndIndicatorOpacity == 1) {
      // 显示翻页划选区域, 并启动倒计时
      setState(() {
        _bottomEndIndicatorOpacity = 0;
      });
      _cancelTimer();
    }
  }

  void _cancelTimer() {
    print('倒计时, 倒计时取消: $currentTimer');
    _timer?.cancel();
    _timer = null;
    currentTimer = 0;
  }
}
