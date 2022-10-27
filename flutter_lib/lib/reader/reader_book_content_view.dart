import 'dart:async';
import 'dart:ui' as ui;

import 'package:ele_progress/ele_progress.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lib/modal/base_view_model.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';
import 'package:flutter_lib/reader/controller/touch_event.dart';
import 'package:flutter_lib/reader/handler/selection_handler.dart';
import 'package:flutter_lib/reader/ui/selection_menu_factory.dart';
import 'package:flutter_lib/widget/base/base_stateful_view.dart';
import 'package:flutter_lib/widget/content_painter.dart';
import 'package:flutter_lib/widget/highlight_painter.dart';
import 'package:provider/provider.dart';

import 'animation/controller_animation_with_listener_number.dart';
import 'animation/model/highlight_block.dart';
import 'animation/model/selection_cursor.dart';
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
}

class ReaderBookContentViewState extends BaseStatefulViewState<ReaderWidget, ReaderViewModel>
    with TickerProviderStateMixin {
  final _methodChannel = const MethodChannel('platform_channel_methods');

  // 翻页倒计时
  Timer? _timer;
  static const int timeFactorLimit = 50;
  int currentTimeFactor = 0;

  // 图书主内容区域
  final GlobalKey contentKey = GlobalKey();
  final GlobalKey highlightLayerKey = GlobalKey();
  final GlobalKey topIndicatorKey = GlobalKey();
  final GlobalKey bottomIndicatorKey = GlobalKey();
  double _topStartIndicatorOpacity = 0;
  double _bottomEndIndicatorOpacity = 0;

  ContentPainter? _contentPainter;
  final HighlightPainter _highlightPainter = HighlightPainter();

  AnimationController? animationController;

  late ReaderContentHandler _readerContentHandler;
  late SelectionHandler _selectionHandler;

  @override
  void onInitState() {
    // handler必须在这里初始化, 因为里面注册了原生交互的方法, 只能执行一次
    print('时间测试, onInitState');
    _readerContentHandler =
        ReaderContentHandler(methodChannel: _methodChannel, viewState: this);
    _selectionHandler = SelectionHandler(
        readerContentHandler: _readerContentHandler,
        topIndicatorKey: topIndicatorKey,
        bottomIndicatorKey: bottomIndicatorKey);
  }

  @override
  void loadData(BuildContext context, ReaderViewModel? viewModel) {
    print('时间测试, loadData');
    ReaderViewModel readerViewModel =
        ArgumentError.checkNotNull(viewModel, 'ReaderViewModel');

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
                if (_selectionHandler.isSelectionStateEnabled) {
                  // 拖动开始，此时划选模式应该已经激活，隐藏划选弹窗
                  hideSelectionMenu();
                  _selectionHandler.onDragStart(detail);
                  var indicator = _selectionHandler
                      .enableCrossPageIndicator(detail.localPosition);
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
                if (_selectionHandler.isSelectionStateEnabled) {
                  _selectionHandler.onDragMove(detail);
                  var indicator = _selectionHandler
                      .enableCrossPageIndicator(detail.localPosition);
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
                if (_selectionHandler.isSelectionStateEnabled) {
                  _selectionHandler.onDragEnd(detail);
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
                updateSelectionState(true);
                // 长按开始，隐藏划选弹窗
                hideSelectionMenu();
                _selectionHandler.onLongPressStart(detail);
                //todo 激活跨页划选
              };
              recognizer.onLongPressMoveUpdate = (detail) {
                _selectionHandler.onLongPressMove(detail);
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
              // 点击事件，隐藏划选弹窗
              if (_selectionHandler.isSelectionStateEnabled) {
                _selectionHandler.onTagUp(detail);
                hideSelectionMenu();
                updateHighlight(null, null);
                updateSelectionState(false);
              } else {
                navigatePageNoAnimation(detail.localPosition, null);
              }
            };
          })
        },
        child: Stack(
          children: <Widget>[
            _buildHighlightLayer(contentSize.width, contentSize.height),
            SizedBox(
              width: contentSize.width,
              height: contentSize.height,
              child: RepaintBoundary(
                child: CustomPaint(
                  key: contentKey,
                  painter: _contentPainter,
                ),
              ),
            ),
            Positioned.fill(
              child: _buildSelectionIndicator(
                topIndicatorKey,
                _topStartIndicatorOpacity,
                AlignmentDirectional.topStart,
              ),
            ),
            Positioned.fill(
              child: _buildSelectionIndicator(
                bottomIndicatorKey,
                _bottomEndIndicatorOpacity,
                AlignmentDirectional.bottomEnd,
              ),
            ),
            _selectionHandler.menuPosition != null
                ? _buildSelectionMenuLayer()
                : const SizedBox(width: 0, height: 0),
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
  Future<void> navigatePageNoAnimation(
      Offset touchPosition, SelectionIndicator? indicator) async {
    var eventAction = getEventAction(touchPosition, indicator);
    if (eventAction != null) {
      TouchEvent event =
          TouchEvent(action: eventAction, touchPosition: touchPosition);
      if (await _contentPainter!.canScroll(event)) {
        _contentPainter?.startCurrentTouchEvent(event);
        updateHighlight(null, null);
        contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
        setState(() {
          _selectionHandler.crossPageCount++;
        });
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
          return EventAction.noAnimationForward;
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
    if(_timer == null && _selectionHandler.crossPageCount < SelectionHandler.crossPageLimit) {
      print('倒计时, 倒计时开始: $currentTimeFactor');
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        setState(() {
          currentTimeFactor++;
        });
        print('倒计时, 倒计时进行中: $currentTimeFactor');
        // 倒计时结束，取消倒计时并进行翻页操作
        if (currentTimeFactor == timeFactorLimit) {
          print('倒计时, 倒计时结束: $currentTimeFactor, 进行翻页');
          _cancelTimer();
          // todo
          //  1. 5页的翻页划选限制 (完成)
          //  2. 在最后一页划选页取消划选之后, 前面的缓存页没有刷新,
          //  3. 处理图片选中
          navigatePageNoAnimation(touchPosition, indicator);
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
    print('倒计时, 倒计时取消: $currentTimeFactor');
    _timer?.cancel();
    _timer = null;
    setState(() {
      currentTimeFactor = 0;
    });
  }

  /// [position]必须是global position, 因为设置[Positioned]会自动乘以deviceRatio
  void showSelectionMenu(Offset position) {
    setState(() {
      _selectionHandler.updateSelectionMenuPosition(position);
    });
  }

  void hideSelectionMenu() {
    if (_selectionHandler.menuPosition != null) {
      setState(() {
        _selectionHandler.updateSelectionMenuPosition(null);
      });
    }
  }

  void updateSelectionState(bool enable) {
    _selectionHandler.updateSelectionState(enable);
  }

  Widget _buildHighlightLayer(double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: RepaintBoundary(
        child: CustomPaint(
          key: highlightLayerKey,
          painter: _highlightPainter,
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(
      GlobalKey key, double opacity, AlignmentDirectional alignment) {
    return Opacity(
      opacity: opacity,
      child: Align(
        alignment: alignment,
        child: SizedBox(
          key: key,
          width: 200,
          height: 150,
          // color: Colors.greenAccent,
          child: EProgress(
              progress: currentTimeFactor * 2,
              type: ProgressType.liquid,
              strokeWidth: 0,
              textStyle: const TextStyle(
                fontSize: 40,
                color: Colors.red,
              ),
              backgroundColor: Colors.grey,
              format: (progress) {
                return '${_selectionHandler.crossPageCount}/${SelectionHandler.crossPageLimit}';
              }),
        ),
      ),
    );
  }

  Widget _buildSelectionMenuLayer() {
    Offset position = _selectionHandler.menuPosition!;
    if (position.isInfinite) {
      print('选择弹窗, 显示居中');
      return Positioned.fill(
        child: Align(
          alignment: Alignment.center,
          child: _selectionHandler.factory.buildSelectionMenu((menuItem) {
            _handleSelectionAction(menuItem);
          }),
        ),
      );
    } else {
      print('选择弹窗, 自定义位置 = ${_selectionHandler.menuPosition}');
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: _selectionHandler.factory.buildSelectionMenu((menuItem) {
          _handleSelectionAction(menuItem);
        }),
      );
    }
  }

  void _handleSelectionAction(SelectionItem menuItem) {
    switch (menuItem) {
      case SelectionItem.note:
        break;
      case SelectionItem.copy:
        _selectionHandler.copy();
        break;
      case SelectionItem.search:
        break;
    }
  }

  void showText(String text) {
    showDialog(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            title: const Text('选中文字'),
            titlePadding: const EdgeInsets.all(10),
            elevation: 5,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Text(text),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
                child: OutlinedButton(
                  child: const Text("关闭"),
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                ),
              )
            ],
          );
        });
  }

  void updateHighlight(List<HighlightBlock>? blocks, List<SelectionCursor>? selectionCursors) {
    _highlightPainter.updateHighlight(blocks, selectionCursors);
    highlightLayerKey.currentContext?.findRenderObject()?.markNeedsPaint();
  }
}
