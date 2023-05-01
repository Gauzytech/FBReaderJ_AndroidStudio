import 'package:flutter/foundation.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_phase_delegate.dart';

abstract class ReaderScrollPhase {

  /// 使用委托提供[ReaderScrollPhase]与阅读界面的交互
  ReaderScrollPhaseDelegate get delegate => _delegate;
  ReaderScrollPhaseDelegate _delegate;

  /// Initializes [delegate] for subclasses.
  ReaderScrollPhase(this._delegate);

  /// 更新stage的[ReaderScrollPhaseDelegate].
  ///
  /// 当[ReaderScrollPhase]将要被弃用时调用本方法把[ReaderScrollPhaseDelegate]对象更新.
  void updateDelegate(ReaderScrollPhaseDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  void applyNewDimensions() {}

  void resetPhase() { }

  /// 在执行当前state的时候是否需要忽略其他pointer
  bool get shouldIgnorePointer;

  /// 当前行为是否为滚动行为
  bool get isScrolling;

  /// If applicable, the velocity at which the scroll offset is currently
  /// independently changing (i.e. without external stimuli such as a dragging
  /// gestures) in logical pixels per second for this activity.
  double get velocity;

  /// Called when the scroll view stops performing this activity.
  @mustCallSuper
  void dispose() { }

  @override
  String toString() => describeIdentity(this);
}
