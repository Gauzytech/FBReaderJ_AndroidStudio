import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state/hold_scroll_state.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state/idle_scroll_state.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state/reader_scroll_state.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_viewport_offset.dart';

import '../page_physics/book_page_physics.dart';

abstract class ReaderScrollPosition extends ReaderViewportOffset {
  /// Where the scrolling is taking place.
  ///
  /// Typically implemented by [ReaderBookContentViewState].
  BookPageScrollContext context;
  BookPagePhysics physics;

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

  /// 终止当前state然后开始一个[HoldScrollState].
  ScrollHoldController hold(VoidCallback holdCancelCallback);

  /// 当前正在执行的[ReaderScrollState].
  ///
  /// 没有scroll就是[IdleScrollState].
  /// 可以通过[isScrollingNotifier]判断当前是否正在执行任何scroll事件.
  ///
  /// Call [beginState] to change the current activity.
  @protected
  @visibleForTesting
  ReaderScrollState? get scrollState => _scrollState;
  ReaderScrollState? _scrollState;

  /// This notifier's value is true if a scroll is underway and false if the scroll
  /// position is idle.
  ///
  /// Listeners added by stateful widgets should be removed in the widget's
  /// [State.dispose] method.
  final ValueNotifier<bool> isScrollingNotifier = ValueNotifier<bool>(false);

  ReaderScrollPosition({required this.context, required this.physics});

  /// 更新[pixels], 并需要通知观察者
  double setPixels(double newPixels) {
    assert(hasPixels);
    assert(
        SchedulerBinding.instance.schedulerPhase !=
            SchedulerPhase.persistentCallbacks,
        "A scrollable's position should not change during the build, layout, and paint phases, otherwise the rendering will be confused.");
    if (newPixels != pixels) {
      _pixels = newPixels;
      // todo 通知刷新ui
    }
    return 0.0;
  }

  /// 更新[pixels], 并不通知观察者
  void correctPixels(double value) {
    _pixels = value;
  }

  void beginScrollState(ReaderScrollState? newState) {
    if(newState == null) return;
    bool wasScrolling, oldIgnorePointer;
    if(_scrollState != null) {
      oldIgnorePointer = _scrollState!.shouldIgnorePointer;
      wasScrolling = _scrollState!.isScrolling;
      if (wasScrolling && !newState.isScrolling) {
        // todo 发送一个通知: 之前的scroll停止了
        // didEndScroll();
      }
      _scrollState!.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _scrollState = newState;
    if (oldIgnorePointer != scrollState!.shouldIgnorePointer) {
      // todo 弄清楚这个ignorePointer的实际作用
      // context.setIgnorePointer(scrollState!.shouldIgnorePointer);
    }
    isScrollingNotifier.value = scrollState!.isScrolling;
    if (!wasScrolling && _scrollState!.isScrolling) {
      // todo 发送一个通知: 新的scroll开始了
      // didStartScroll();
    }
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    if(_viewportDimension != viewportDimension) {
      _viewportDimension = viewportDimension;
    }
    return true;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('viewport: ${_viewportDimension?.toStringAsFixed(1)}');
  }

  void dispose() {
    scrollState?.dispose();
    _scrollState = null;
  }
}
