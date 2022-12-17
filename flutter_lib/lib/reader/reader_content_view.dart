import 'dart:async';
import 'dart:ui' as ui;

import 'package:ele_progress/ele_progress.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/interface/content_selection_delegate.dart';
import 'package:flutter_lib/modal/base_view_model.dart';
import 'package:flutter_lib/modal/view_model_reader.dart';
import 'package:flutter_lib/reader/animation/model/page_paint_metadata.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/page_mode.dart';
import 'package:flutter_lib/reader/controller/book_page_controller.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';
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
import 'controller/native_interface.dart';
import 'controller/page_physics/book_page_physics.dart';
import 'controller/page_repository.dart';
import 'controller/reader_page_view_model.dart';
import 'gestures/book_gesture_recognizer.dart';
import 'handler/selection_handler.dart' as handlers;

/// 图书内容widget
class ReaderContentView extends BaseStatefulView<ReaderViewModel> {
  ReaderContentView({
    Key? key,
    this.axisDirection = AxisDirection.right,
    required this.physics,
  }) : super(key: key) {
    controller = BookPageControllerImpl();
  }

  /// 翻页控制, 控制[BookPagePosition]的翻页渲染
  BookPageController? controller;

  /// 当前翻页模式行为
  final BookPagePhysics physics;

  /// 当前坐标系的方向
  final AxisDirection axisDirection;

  @override
  BaseStatefulViewState<BaseStatefulView<BaseViewModel>, ReaderViewModel>
      buildState() => ReaderContentViewState();
}

class ReaderContentViewState
    extends BaseStatefulViewState<ReaderContentView, ReaderViewModel>
    with TickerProviderStateMixin
    implements BookPageScrollContext, ContentSelectionDelegate {
  /// 书页渲染的坐标, 通过[PageController]创建
  BookPagePosition get position => _position!;
  BookPagePosition? _position;

  // 当前翻页模式的滚动物理行为
  BookPagePhysics? _physics;

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

  BookContentPainter? _contentPainter;
  final HighlightPainter _highlightPainter = HighlightPainter();

  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey =
      GlobalKey<RawGestureDetectorState>();
  Map<Type, GestureRecognizerFactory> _gestureRecognizers =
      const <Type, GestureRecognizerFactory>{};
  AnimationController? animationController;

  PageRepository? _pageRepository;
  late handlers.SelectionHandler _selectionHandler;

  BookPageController get _effectiveController => widget.controller!;
  ReaderPageViewModel? _readerPageViewModel;

  @override
  void didChangeDependencies() {
    print('flutter生命周期, didChangeDependencies');
    _updatePosition();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant ReaderContentView oldWidget) {
    print('flutter生命周期, didUpdateWidget');
    super.didUpdateWidget(oldWidget);
    if (_shouldUpdatePosition(oldWidget)) {
      _updatePosition();
    }
  }

  bool _shouldUpdatePosition(ReaderContentView oldWidget) {
    BookPagePhysics newPhysics = widget.physics;
    BookPagePhysics oldPhysics = oldWidget.physics;
    if (newPhysics.runtimeType != oldPhysics.runtimeType) {
      return true;
    }
    return widget.controller?.runtimeType != oldWidget.controller?.runtimeType;
  }

  @override
  void onInitState() {
    // handler必须在这里初始化, 因为里面注册了原生交互的方法, 只能执行一次
    print('flutter生命周期, onInitState');
    _pageRepository = PageRepository(methodChannel: _methodChannel);
    _selectionHandler = handlers.SelectionHandler(
      readerContentHandler: _pageRepository!,
      topIndicatorKey: topIndicatorKey,
      bottomIndicatorKey: bottomIndicatorKey,
    );
  }

  @override
  void loadData(BuildContext context, ReaderViewModel? viewModel) {
    print('flutter内容绘制流程, loadData');
    assert(viewModel != null, 'ReaderViewModel cannot be null');

    switch (viewModel!.getConfigData().currentAnimationMode) {
    // case ReaderPageManager.TYPE_ANIMATION_SIMULATION_TURN:
      case ReaderPageViewModel.TYPE_ANIMATION_COVER_TURN:
        animationController = AnimationControllerWithListenerNumber(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        );
        break;
      case ReaderPageViewModel.TYPE_ANIMATION_SLIDE_TURN:
      case ReaderPageViewModel.TYPE_ANIMATION_PAGE_TURN:
        animationController = AnimationControllerWithListenerNumber.unbounded(
          duration: const Duration(milliseconds: 150),
          vsync: this,
        );
        break;
    }

    if (animationController != null) {
      print('flutter内容绘制流程, create pageManager');

      // todo 这里要分两种情况，要重置整个viewTree的方法走viewModel, 只刷新特定CustomPainter的方法走pageManger
      _readerPageViewModel = ReaderPageViewModel(
          contentKey: contentKey,
          animationController: animationController!,
          currentAnimationType: viewModel.getConfigData().currentAnimationMode,
          viewModel: viewModel,
          scrollContext: this,
          selectionDelegate: this,
          pageRepository: _pageRepository!);
      _contentPainter = ContentPainter(pageViewModel: _readerPageViewModel!);
    }

    // 透明状态栏
    // SystemChrome.setSystemUIOverlayStyle(
    //   const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
    // );
  }

  @override
  Widget onBuildView(BuildContext context, ReaderViewModel? viewModel) {
    assert(viewModel != null, 'ReaderViewModel cannot be null');
    print("flutter内容绘制流程, onBuildView");
    _setGestureRecognizers(viewModel!);
    final contentSize = viewModel.contentSize;
    return FittedBox(
      // GestureDetector需要放在fittedBox里，
      // 不然触摸事件的localPosition没有通过density转化为真正的屏幕坐标系
      child: RawGestureDetector(
        key: _gestureDetectorKey,
        behavior: HitTestBehavior.translucent,
        gestures: _gestureRecognizers,
        child: Stack(
          children: <Widget>[
            _buildHighlightLayer(contentSize.width, contentSize.height),
            SizedBox(
              width: contentSize.width,
              height: contentSize.height,
              child: RepaintBoundary(
                child: CustomPaint(
                  key: contentKey,
                  painter: _contentPainter as ContentPainter,
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

  // todo 改成绑定ViewModel, 为啥改成true 翻页就没有simulation了
  @override
  bool isBindViewModel() {
    return false;
  }

  @override
  void dispose() {
    print('flutter内容绘制流程, dispose');
    animationController?.dispose();
    viewModel?.dispose();
    _cancelTimer();
    _pageRepository?.tearDown();
    _position?.removeListener(onPagePaintMetaUpdate);
    super.dispose();
  }

  void onDragStart(DragStartDetails detail) {
    // 如果动画正在进行, 直接忽略event
    if (!_contentPainter!.isDuplicateEvent(
      EventAction.dragStart,
      detail.localPosition,
    )) {
      _contentPainter?.setCurrentTouchEvent(
        TouchEvent.fromOnDown(
            EventAction.dragStart, detail.localPosition, position.pixels),
      );
      _contentPainter
          ?.startCurrentTouchEvent(null);
      invalidateContent();
    }
  }

  Future<void> onUpdateEvent(DragUpdateDetails detail) async {
    if (!_contentPainter!.isDuplicateEvent(
      EventAction.move,
      detail.localPosition,
    )) {
      TouchEvent event = TouchEvent.fromOnUpdate(
          EventAction.move, detail.localPosition, position.pixels);
      _contentPainter?.setCurrentTouchEvent(event);
      // 检查上一页/下一页是否存在
      if (await _readerPageViewModel!.canScroll(event)) {
        if (_contentPainter?.startCurrentTouchEvent(event) == true) {
          invalidateContent();
        } else {
          print('flutter动画流程:忽略onUpdate: ${detail.localPosition}');
        }
      }
    }
  }

  Future<void> onEndEvent(DragEndDetails detail) async {
    if (!_contentPainter!.isDuplicateEvent(
      EventAction.dragEnd,
      _contentPainter!.lastTouchPosition(),
    )) {
      TouchEvent event = TouchEvent<DragEndDetails>.fromOnEnd(
          EventAction.dragEnd,
          _contentPainter!.lastTouchPosition(),
          detail,
          position.pixels);
      _contentPainter?.setCurrentTouchEvent(event);
      // 检查上一页/下一页是否存在
      if (await _readerPageViewModel!.canScroll(event)) {
        _contentPainter?.startCurrentTouchEvent(event);
        invalidateContent();
      }
    }
  }

  // 根据点击区域实现无动画翻页
  Future<void> navigatePageNoAnimation(Offset touchPosition, SelectionIndicator? indicator) async {
    var eventAction = getEventAction(touchPosition, indicator);
    if (eventAction != null) {
      TouchEvent event = TouchEvent(
          action: eventAction,
          touchPosition: touchPosition,
          pixels: position.pixels);
      if (await _readerPageViewModel!.canScroll(event)) {
        _contentPainter?.startCurrentTouchEvent(event);
        updateHighlight(null, null);
        invalidateContent();
        setState(() {
          _selectionHandler.crossPageCount++;
        });
      }
    }
  }

  EventAction? getEventAction(Offset? touchPosition, SelectionIndicator? indicator) {
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
    if (_timer == null &&
        _selectionHandler.crossPageCount <
            handlers.SelectionHandler.crossPageLimit) {
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
          //  2. 在最后一页划选页取消划选之后, 前面的缓存页没有刷新, (完成)
          //  3. 处理图片选中
          navigatePageNoAnimation(touchPosition, indicator);
        }
      });
    }
  }

  void _processIndicator(NativeScript cmd, Offset? localPosition) {
    switch (cmd) {
      case NativeScript.dragStart:
      case NativeScript.longPressStart:
        {
          var indicator =
          _selectionHandler.enableCrossPageIndicator(localPosition!);
          if (indicator != null) {
            showIndicator(indicator, localPosition);
          }
        }
        break;
      case NativeScript.dragMove:
      case NativeScript.longPressMove:
        {
          var indicator =
          _selectionHandler.enableCrossPageIndicator(localPosition!);
          if (indicator != null) {
            showIndicator(indicator, localPosition);
          } else {
            hideIndicator();
          }
        }
        break;
      case NativeScript.dragEnd:
      case NativeScript.longPressEnd:
        hideIndicator();
        break;
      default:
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

  @override
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

  @override
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

  Widget _buildSelectionIndicator(GlobalKey key, double opacity, AlignmentDirectional alignment) {
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
                return '${_selectionHandler.crossPageCount}/${handlers.SelectionHandler.crossPageLimit}';
              }),
        ),
      ),
    );
  }

  // todo 把selectionMenu变成一个stateLessWidget, 避免点击menu导致触发onDragDown的点击冲突
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
        print("选择弹窗, copy");
        _selectionHandler.copy();
        break;
      case SelectionItem.search:
        break;
    }
  }

  @override
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

  @override
  void updateHighlight(List<HighlightBlock>? blocks, List<SelectionCursor>? selectionCursors) {
    _highlightPainter.updateHighlight(blocks, selectionCursors);
    highlightLayerKey.currentContext?.findRenderObject()?.markNeedsPaint();
  }

  void _setGestureRecognizers(ReaderViewModel viewModel) {
    switch (viewModel.getConfigData().currentAnimationMode) {
      case ReaderPageViewModel.TYPE_ANIMATION_SLIDE_TURN:
        _gestureRecognizers = <Type, GestureRecognizerFactory>{
          BookVerticalDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<
                      BookVerticalDragGestureRecognizer>(
                  () => BookVerticalDragGestureRecognizer(),
                  (BookVerticalDragGestureRecognizer instance) {
            instance
              ..onDown = _handleDragDown
              ..onStart = _handleDragStart
              ..onUpdate = _handleDragUpdate
              ..onEnd = _handleDragEnd
              ..onCancel = _handleDragCancel;
          }),
          LongPressGestureRecognizer: _longPressRecognizer(),
          TapGestureRecognizer: _tapRecognizer()
        };
        break;
    // case ReaderPageManager.TYPE_ANIMATION_SIMULATION_TURN:
      case ReaderPageViewModel.TYPE_ANIMATION_COVER_TURN:
      case ReaderPageViewModel.TYPE_ANIMATION_PAGE_TURN:
        _gestureRecognizers = <Type, GestureRecognizerFactory>{
          BookHorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              BookHorizontalDragGestureRecognizer>(
                  () => BookHorizontalDragGestureRecognizer(),
                  (BookHorizontalDragGestureRecognizer instance) {
            instance
              ..onDown = _handleDragDown
              ..onStart = _handleDragStart
              ..onUpdate = _handleDragUpdate
              ..onEnd = _handleDragEnd
              ..onCancel = _handleDragCancel;
          }),
          LongPressGestureRecognizer: _longPressRecognizer(),
          TapGestureRecognizer: _tapRecognizer()
        };
        break;
    }
  }

  Drag? _drag;
  ScrollHoldController? _hold;

  /// 这个方法在dragDown, longPressDown时都会调用
  void _handleDragDown(DragDownDetails details) {
    print(
        "flutter动画流程[onDragDown], isSelected: ${_selectionHandler.isSelectionStateEnabled}");
    // print("选择弹窗[onDragDown]}");
    // if (_selectionHandler.isSelectionStateEnabled) {
    //   // 此时划选模式应该已经激活，隐藏划选弹窗
    //   hideSelectionMenu();
    // }

    // 不是长按状态, 初始化drag滚动行为
    if(!_selectionHandler.isSelectionStateEnabled) {
      assert(_drag == null);
      assert(_hold == null);
      _hold = position.hold(_disposeHold);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (_selectionHandler.isSelectionStateEnabled) {
      // 如果划选模式已经激活，隐藏划选弹窗
      hideSelectionMenu();
      _selectionHandler.onDragStart(details);
      _processIndicator(NativeScript.dragStart, details.localPosition);
    } else {
      print("flutter动画流程[onDragStart], 进行翻页操作${details.localPosition}");

      assert(_drag == null);
      _drag = position.drag(details, _disposeDrag);
      assert(_drag != null);
      assert(_hold == null);

      // onDragStart(details);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_selectionHandler.isSelectionStateEnabled) {
      _selectionHandler.onDragMove(details);
      _processIndicator(NativeScript.dragMove, details.localPosition);
    } else {
      print(
          'flutter动画流程[onDragUpdate], 进行翻页操作 = ${details.localPosition}, primaryDelta = ${details.primaryDelta}');

      assert(_hold == null || _drag == null);
      _drag?.update(details);

      // onUpdateEvent(details);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_selectionHandler.isSelectionStateEnabled) {
      _selectionHandler.onDragEnd(details);
      _processIndicator(NativeScript.dragEnd, null);
    } else {
      print("flutter动画流程[onDragEnd], 进行翻页操作$details");
      // todo 把pixels转成当前onDraw自己的一套坐标
      assert(_hold == null || _drag == null);
      _drag?.end(details);
      assert(_drag == null);

      // onEndEvent(details);
    }
  }

  void _handleDragCancel() {}

  void _disposeHold() {
    _hold = null;
  }

  void _disposeDrag() {
    _drag = null;
  }

  GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>
      _longPressRecognizer() {
    return GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(),
        (LongPressGestureRecognizer instance) {
      instance
        ..onLongPressStart = _handleLongPressStart
        ..onLongPressMoveUpdate = _handleLongPressUpdate
        ..onLongPressEnd = _handleLongPressEnd
        ..onLongPressCancel = _handleLongPressCancel;
        });
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_selectionHandler.isSelectionStateEnabled) {
      updateSelectionState(true);
    } else {
      // 如果划选模式已经激活，隐藏划选弹窗
      hideSelectionMenu();
    }

    _selectionHandler.onLongPressStart(details);
    _processIndicator(NativeScript.longPressStart, details.localPosition);
  }

  void _handleLongPressUpdate(LongPressMoveUpdateDetails details) {
    _selectionHandler.onLongPressMove(details);
    _processIndicator(NativeScript.longPressMove, details.localPosition);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _selectionHandler.onLongPressUp();
    _processIndicator(NativeScript.longPressEnd, null);
  }

  void _handleLongPressCancel() {}

  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer> _tapRecognizer() {
    return GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(), (TapGestureRecognizer instance) {
      instance.onTapUp = _handleTapUp;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    // 点击事件，隐藏划选弹窗
    if (_selectionHandler.isSelectionStateEnabled) {
      _selectionHandler.onTagUp(details);
      hideSelectionMenu();
      updateHighlight(null, null);
      updateSelectionState(false);
    } else {
      navigatePageNoAnimation(details.localPosition, null);
    }
  }

  @override
  TickerProvider get vsync => this;

  @override
  AxisDirection get axisDirection => widget.axisDirection;

  @override
  PageMode get pageMode => viewModel!.getConfigData().getPageMode();

  @override
  void invalidateContent([String? tag]) {
    print(
        'flutter内容绘制流程[invalidateContent], tag = $tag, contentKey exist = ${contentKey.currentContext != null}');
    // markNeedsPaint不会调用shouldRepaint
    // onBuildView会调用shouldRepaint
    contentKey.currentContext?.findRenderObject()?.markNeedsPaint();
  }

  /// 初始化翻页渲染坐标[_position]和翻页物理行为[_physics]
  void _updatePosition() {
    print("flutter翻页行为, _updatePosition");
    _physics = widget.physics;
    final BookPagePosition? oldPosition = _position;
    if (oldPosition != null) {
      oldPosition.removeListener(onPagePaintMetaUpdate);
      _effectiveController.detach(oldPosition);
      // It's important that we not dispose the old position until after the
      // viewport has had a chance to unregister its listeners from the old
      // position. So, schedule a microtask to do it.
      scheduleMicrotask(oldPosition.dispose);
    }
    _position = _effectiveController.createBookPagePosition(
        _physics!, this, oldPosition);
    assert(_position != null);
    position.addListener(onPagePaintMetaUpdate);
    _effectiveController.attach(position);
  }

  @override
  void initialize(int width, int height) {
    switch (pageMode) {
      case PageMode.verticalPageScroll:
        position.applyViewportDimension(height.toDouble());
        break;
      case PageMode.horizontalPageTurn:
        position.applyViewportDimension(width.toDouble());
        break;
    }
    // 因为ContentSize更新了, ViewModel变更了, 通知onBuildView重绘
    assert(viewModel != null);
    viewModel!.notify();
    print('flutter翻页行为, 初始化数据完毕: ${position.toString()}');
  }

  void onPagePaintMetaUpdate() {
    print('flutter翻页行为, position更新: $position');
    _contentPainter?.onPagePaintMetaUpdate(PagePaintMetaData(
      position.pixels,
      position.page!,
      position.userScrollDirection,
    ));
    invalidateContent();
  }
}
