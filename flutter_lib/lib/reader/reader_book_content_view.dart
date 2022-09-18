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
import 'dart:ui' as ui;

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

class ReaderBookContentViewState
    extends BaseStatefulViewState<ReaderWidget, ReaderViewModel>
    with TickerProviderStateMixin {
  final _methodChannel = const MethodChannel('platform_channel_methods');
  final _eventChannel =
      const EventChannel('platform_channel_events/page_repaint');

  // 图书主内容区域
  final GlobalKey contentKey = GlobalKey();
  final GlobalKey footerKey = GlobalKey();
  final GlobalKey topIndicatorKey = GlobalKey();
  final GlobalKey bottomIndicatorKey = GlobalKey();
  bool showCrossPageSelectionIndicator = false;

  ContentPainter? _contentPainter;

  late ReaderPageManager pageManager;
  AnimationController? animationController;

  late ReaderContentHandler _readerContentHandler;
  late SelectionEventHandler _selectionEventHandler;
  final PagePanDragRecognizer _pagePanDragRecognizer = PagePanDragRecognizer();

  @override
  void onInitState() {
    // handler必须在这里初始化, 因为里面注册了原生交互的方法, 只能执行一次
    _readerContentHandler = ReaderContentHandler(
        methodChannel: _methodChannel,
        eventChannel: _eventChannel,
        readerBookContentViewState: this);
    _selectionEventHandler =
        SelectionEventHandler(readerContentHandler: _readerContentHandler);
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

      pageManager = ReaderPageManager(
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
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: <Type, GestureRecognizerFactory>{
              PagePanDragRecognizer:
                  GestureRecognizerFactoryWithHandlers<PagePanDragRecognizer>(
                () => _pagePanDragRecognizer,
                (PagePanDragRecognizer recognizer) {
                  recognizer.setMenuOpen(false);
                  recognizer.onStart = (detail) {
                    if (recognizer.isSelectionMenuShown()) {
                      _selectionEventHandler.onSelectionDragStart(detail);
                    } else {
                      print(
                          "flutter动画流程[onDragStart], 进行翻页操作${detail.localPosition}");
                      onDragStart(detail, readerViewModel);
                    }
                  };
                  recognizer.onUpdate = (detail) {
                    if (recognizer.isSelectionMenuShown()) {
                      _selectionEventHandler.onSelectionDragMove(detail);
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
                    if (recognizer.isSelectionMenuShown()) {
                      _selectionEventHandler.onSelectionDragEnd(detail);
                    } else if (!readerViewModel.getMenuOpenState()) {
                      print("flutter动画流程[onDragEnd], 进行翻页操作$detail");
                      onEndEvent(detail, readerViewModel);
                    } else {
                      print('flutter动画流程[onDragEnd], 忽略事件$detail');
                    }
                  };
                },
              ),
              LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(),
                (LongPressGestureRecognizer recognizer) {
                  recognizer.onLongPressStart = (detail) {
                    _pagePanDragRecognizer.setSelectionMenuState(true);
                    _selectionEventHandler.onLongPressStart(detail);
                  };
                  recognizer.onLongPressMoveUpdate = (detail) {
                    _selectionEventHandler.onLongPressMoveUpdate(detail);
                  };
                  recognizer.onLongPressUp = () {
                    _selectionEventHandler.onLongPressUp();
                  };
                },
              ),
              TapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                      () => TapGestureRecognizer(),
                      (TapGestureRecognizer recognizer) {
                recognizer.onTapUp = (detail) {
                  // todo 只让indicator刷新, customPainter不应该刷新
                  setState(() {
                    showCrossPageSelectionIndicator = true;
                  });
                  // showCrossPageSelectionIndicator = true;
                  // bottomIndicatorKey.currentContext
                  //     ?.findRenderObject()
                  //     ?.markNeedsPaint();

                  // _selectionEventHandler.onTagUp(detail);
                  // _pagePanDragRecognizer.setSelectionMenuState(false);
                };
              })
            },
            child: FittedBox(
              child: Stack(
                children: <Widget>[
                  SizedBox(
                    width: contentSize[0],
                    height: contentSize[1],
                    child: CustomPaint(
                      key: contentKey,
                      painter: _contentPainter,
                    ),
                  ),
                  Positioned.fill(
                    child: Visibility(
                      visible: showCrossPageSelectionIndicator,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Container(
                          // key: topIndicatorKey,
                          width: 150,
                          height: 150,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Visibility(
                      visible: showCrossPageSelectionIndicator,
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
          ),
        ),
        Container(
          key: footerKey,
          width: double.infinity,
          height: getFooterHeight(),
          color: Colors.green.shade200,
          child: const Text('底部: 显示图书电量和页码'),
        ),
      ],
    );
  }

  double getFooterHeight() {
    return ui.window.physicalSize.height * 0.01;
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
    super.dispose();
  }

  void onDragStart(DragStartDetails detail, ReaderViewModel readerViewModel) {
    // 如果动画正在进行, 直接忽略event
    if (!_contentPainter!
        .isDuplicateEvent(TouchEvent.ACTION_DRAG_START, detail.localPosition)) {
      _contentPainter?.setCurrentTouchEvent(
        TouchEvent.fromOnDown(
          TouchEvent.ACTION_DRAG_START,
          detail.localPosition,
        ),
      );
      _contentPainter
          ?.startCurrentTouchEvent(_contentPainter!.currentTouchData!);
      RenderObject? renderObject =
          contentKey.currentContext?.findRenderObject();
      print("渲染刷新, ${renderObject?.isRepaintBoundary}");
      renderObject?.markNeedsPaint();
    }
  }

  Future<void> onUpdateEvent(
      DragUpdateDetails detail, ReaderViewModel readerViewModel) async {
    if (!_contentPainter!.isDuplicateEvent(
      TouchEvent.ACTION_MOVE,
      detail.localPosition,
    )) {
      TouchEvent event = TouchEvent.fromOnUpdate(
        TouchEvent.ACTION_MOVE,
        detail.localPosition,
      );
      _contentPainter?.setCurrentTouchEvent(event);
      // 检查上一页/下一页是否存在
      if (await pageManager.canScroll(event)) {
        if (_contentPainter?.startCurrentTouchEvent(event) == true) {
          contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
        } else {
          print('flutter动画流程:忽略onUpdate: ${detail.localPosition}');
        }
      }
    }
  }

  Future<void> onEndEvent(
      DragEndDetails detail, ReaderViewModel readerViewModel) async {
    if (!_contentPainter!.isDuplicateEvent(
      TouchEvent.ACTION_DRAG_END,
      _contentPainter!.lastTouchPosition(),
    )) {
      TouchEvent event = TouchEvent<DragEndDetails>.fromOnEnd(
        TouchEvent.ACTION_DRAG_END,
        _contentPainter!.lastTouchPosition(),
        detail,
      );
      _contentPainter?.setCurrentTouchEvent(event);
      // 检查上一页/下一页是否存在
      if (await pageManager.canScroll(event)) {
        _contentPainter?.startCurrentTouchEvent(event);
        contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
      }
    }
  }
}
