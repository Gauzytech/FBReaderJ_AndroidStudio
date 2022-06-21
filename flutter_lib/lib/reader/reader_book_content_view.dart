import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lib/modal/base_view_model.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';
import 'package:flutter_lib/reader/controller/touch_event.dart';
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

class ReaderBookContentViewState
    extends BaseStatefulViewState<ReaderWidget, ReaderViewModel>
    with TickerProviderStateMixin {
  final _methodChannel = const MethodChannel('com.flutter.book.reader');

  // 图书主内容区域
  final GlobalKey contentKey = GlobalKey();
  final GlobalKey footerKey = GlobalKey();

  ContentPainter? _contentPainter;

  late ReaderPageManager pageManager;
  AnimationController? animationController;

  late ReaderContentHandler _readerContentHandler;

  @override
  void onInitState() {
    // handler必须在这里初始化, 因为里面注册了原生交互的方法, 只能执行一次
    _readerContentHandler = ReaderContentHandler(
        methodChannel: _methodChannel, readerBookContentViewState: this);
  }

  @override
  void loadData(BuildContext context, ReaderViewModel? viewModel) {
    ReaderViewModel readerViewModel = ArgumentError.checkNotNull(viewModel, 'ReaderViewModel');

    switch (readerViewModel.getConfigData().currentAnimationMode) {
    // case ReaderPageManager.TYPE_ANIMATION_SIMULATION_TURN:
      case ReaderPageManager.TYPE_ANIMATION_COVER_TURN:
        animationController = AnimationControllerWithListenerNumber(
          vsync: this,
        );
        break;
      case ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN:
      case ReaderPageManager.TYPE_ANIMATION_PAGE_TURN:
        animationController = AnimationControllerWithListenerNumber.unbounded(
          vsync: this,
        );
        break;
    }

    if (animationController != null) {
      readerViewModel.getConfigData().currentAnimationMode =
          ReaderPageManager.TYPE_ANIMATION_PAGE_TURN;

      pageManager = ReaderPageManager(
          canvasKey: contentKey,
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
          child: FittedBox(
            child: SizedBox(
              width: contentSize[0],
              height: contentSize[1],
              child: RawGestureDetector(
                gestures: <Type, GestureRecognizerFactory>{
                  PagePanGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                          PagePanGestureRecognizer>(
                    () => PagePanGestureRecognizer(),
                    (PagePanGestureRecognizer recognizer) {
                      recognizer.setMenuOpen(false);
                      recognizer.onDown = (detail) {
                        print("flutter动画流程:触摸事件, ------------------触摸事件[onDown], ${detail.localPosition}------------------>>>>>>>>");
                        onDownEvent(detail, readerViewModel);
                      };
                      recognizer.onUpdate = (detail) {
                        print("flutter动画流程:触摸事件, ------------------触摸事件[onUpdate], ${detail.localPosition}------------------>>>>>>>>>");
                        if (!readerViewModel.getMenuOpenState()) {
                          onUpdateEvent(detail, readerViewModel);
                        }
                      };
                      recognizer.onEnd = (detail) {
                        print("flutter动画流程:触摸事件, ------------------触摸事件[onEnd], $detail ------------------>>>>>>>>>");
                        if (!readerViewModel.getMenuOpenState()) {
                          onEndEvent(detail, readerViewModel);
                        }
                      };
                    },
                  ),
                  LongPressGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                          LongPressGestureRecognizer>(
                    () => LongPressGestureRecognizer(),
                    (LongPressGestureRecognizer recognizer) {
                      recognizer.onLongPress = () {
                        print("flutter动画流程:触摸事件, ------------------长按事件------------------>>>>>>>>>");
                      };
                    },
                  )
                },
                child: CustomPaint(
                  key: contentKey,
                  painter: _contentPainter,
                ),
              ),
            ),
          ),
        ),
        Container(
          key: footerKey,
          width: double.infinity,
          color: Colors.green.shade200,
          child: const Text('底部: 显示图书电量和页码'),
        ),
      ],
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
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  void onDownEvent(DragDownDetails detail, ReaderViewModel readerViewModel) {
    // 如果动画正在进行, 直接忽略event
    if (!_contentPainter!
        .isDuplicateEvent(TouchEvent.ACTION_DOWN, detail.localPosition)) {
      _contentPainter?.setCurrentTouchEvent(
        TouchEvent.fromOnDown(
          TouchEvent.ACTION_DOWN,
          detail.localPosition,
        ),
      );
      _contentPainter
          ?.startCurrentTouchEvent(_contentPainter!.currentTouchData!);
      contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
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
        _contentPainter?.startCurrentTouchEvent(event);
        contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
      } else {
        print('flutter动画流程:触摸事件, 忽略$event');
      }
    }
  }

  Future<void> onEndEvent(
      DragEndDetails detail, ReaderViewModel readerViewModel) async {
    if (!_contentPainter!.isDuplicateEvent(
      TouchEvent.ACTION_UP,
      _contentPainter!.lastTouchPosition(),
    )) {
      TouchEvent event = TouchEvent<DragEndDetails>.fromOnEnd(
        TouchEvent.ACTION_UP,
        _contentPainter!.lastTouchPosition(),
        detail,
      );
      _contentPainter?.setCurrentTouchEvent(event);
      // 检查上一页/下一页是否存在
      if (await pageManager.canScroll(event)) {
        _contentPainter?.startCurrentTouchEvent(event);
        contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
      } else {
        print('flutter动画流程:触摸事件, 忽略$event');
      }
    }
  }
}
