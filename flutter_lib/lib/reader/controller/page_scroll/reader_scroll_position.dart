import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/hold_scroll_phase.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/idle_scroll_phase.dart';
import 'package:flutter_lib/reader/controller/page_scroll/scrollphase/reader_scroll_phase.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_viewport_offset.dart';

import '../page_physics/book_page_physics.dart';

abstract class ReaderScrollPosition extends ReaderViewportOffset {
  /// 阅读图书内容界面View, 就是[ReaderBookContentViewState].
  BookPageScrollContext context;
  BookPagePhysics physics;

  @override
  double get minScrollExtent => _minScrollExtent!;
  double? _minScrollExtent;

  @override
  double get maxScrollExtent => _maxScrollExtent!;
  double? _maxScrollExtent;

  @override
  bool get hasContentDimensions => _minScrollExtent != null && _maxScrollExtent != null;

  @override
  double get pixels => _pixels!;
  double? _pixels;

  @override
  bool get hasPixels => _pixels != null;

  @override
  double get viewportDimension => _viewportDimension!;
  double? _viewportDimension;

  @override
  bool get hasViewportDimension => _viewportDimension != null;

  @override
  double get scrollStartPixels => _scrollStartPixels;
  double _scrollStartPixels = 0;

  /// 终止当前state然后开始一个[HoldScrollPhase].
  ScrollHoldController hold(VoidCallback holdCancelCallback);

  /// 通过[DragStartDetails]开始一个drag stage, [dragCancelCallback]会在drag结束时调用.
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback);

  /// 当前正在执行的[ReaderScrollPhase].
  ///
  /// 没有scroll就是[IdleScrollPhase].
  /// 可以通过[isScrollingNotifier]判断当前是否正在执行任何scroll事件.
  ///
  /// 调用[beginScrollPhase]改变当前的滚动阶段.
  @protected
  @visibleForTesting
  ReaderScrollPhase? get scrollPhase => _scrollPhase;
  ReaderScrollPhase? _scrollPhase;

  /// 通知滚动是否正在执行
  /// true, 正在滚动
  /// false, 没有滚动
  ///
  /// Listeners added by stateful widgets should be removed in the widget's
  /// [State.dispose] method.
  final ValueNotifier<bool> isScrollingNotifier = ValueNotifier<bool>(false);

  ReaderScrollPosition({
    required this.context,
    required this.physics,
    BookPagePosition? oldPosition,
  }) {
    if(oldPosition != null) {
      absorb(oldPosition);
    }
  }

  @protected
  @mustCallSuper
  void absorb(ReaderScrollPosition other) {
    assert(other.context == context);
    assert(_pixels == null);
    if(other.hasContentDimensions) {
      _minScrollExtent = other.minScrollExtent;
      _maxScrollExtent = other.maxScrollExtent;
    }
    if (other.hasPixels) {
      _pixels = other.pixels;
    }
    _scrollStartPixels = other.scrollStartPixels;
    if (other.hasViewportDimension) {
      _viewportDimension = other.viewportDimension;
    }

    assert(scrollPhase == null);
    assert(other.scrollPhase != null);
    _scrollPhase = other.scrollPhase;
    other._scrollPhase = null;
    if (other.runtimeType != runtimeType) {
      scrollPhase!.resetPhase();
    }
    // todo setIgnorePointer用法
    // context.setIgnorePointer(scrollState!.shouldIgnorePointer);
    // todo isScrollingNotifier用法
    isScrollingNotifier.value = scrollPhase!.isScrolling;
  }

  /// 更新[pixels], 并需要通知观察者
  double setPixels(double newPixels) {
    assert(hasPixels);
    assert(
        SchedulerBinding.instance.schedulerPhase !=
            SchedulerPhase.persistentCallbacks,
        "滚动position不能在build, layout, 和paint时改变, 不然图书page页面的渲染会被混淆.");

    // todo 现在暂时忽略了快速连续滑动导致pixels累加 > 1080的情况
    print('flutter翻页行为, setPixels = $newPixels');
    if (newPixels.abs() <= maxScrollExtent && newPixels != pixels) {
      _pixels = newPixels;
      // todo 通知刷新ui
      notifyListeners();
    }
    return 0.0;
  }

  /// 更新[pixels], 并不通知观察者
  void correctPixels(double value) {
    _pixels = value;
  }

  void beginScrollPhase(ReaderScrollPhase? newPhase) {
    if (newPhase == null) return;
    bool wasScrolling, oldIgnorePointer;
    if (_scrollPhase != null) {
      oldIgnorePointer = _scrollPhase!.shouldIgnorePointer;
      wasScrolling = _scrollPhase!.isScrolling;
      if (wasScrolling && !newPhase.isScrolling) {
        // todo 发送一个通知: 之前的scroll停止了
        // didEndScroll();
        _onEndScroll();
      }
      _scrollPhase!.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _scrollPhase = newPhase;
    if (oldIgnorePointer != scrollPhase!.shouldIgnorePointer) {
      // todo 弄清楚这个ignorePointer的实际作用
      // context.setIgnorePointer(scrollState!.shouldIgnorePointer);
    }
    isScrollingNotifier.value = scrollPhase!.isScrolling;
    if (!wasScrolling && _scrollPhase!.isScrolling) {
      // todo 发送一个通知: 新的scroll开始了
      // didStartScroll();
      _onStartScroll();
    }
  }

  /// 在[beginScrollPhase]调用, 表示滚动行为开始了
  void _onStartScroll() {
    print('flutter翻页行为:scroll状态, onStartScroll');
    _scrollStartPixels = pixels;
  }

  /// 在[beginScrollPhase]调用, 表示滚动行为结束了.
  void _onEndScroll() {
    print('flutter翻页行为:scroll状态, _onEndScroll');
    _scrollStartPixels = 0;
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    if(_viewportDimension != viewportDimension) {
      _viewportDimension = viewportDimension;
    }
    return true;
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    assert(minScrollExtent <= maxScrollExtent);
    _minScrollExtent = minScrollExtent;
    _maxScrollExtent = maxScrollExtent;
    return true;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('viewport: ${_viewportDimension?.toStringAsFixed(1)}');
  }

  void dispose() {
    scrollPhase?.dispose();
    _scrollPhase = null;
  }
}
