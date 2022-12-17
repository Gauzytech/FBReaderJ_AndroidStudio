import 'package:flutter/foundation.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_stage_delegate.dart';

abstract class ReaderScrollStage {

  /// 使用委托提供[ReaderScrollStage]与阅读界面的交互
  ReaderScrollStageDelegate get delegate => _delegate;
  ReaderScrollStageDelegate _delegate;

  /// Initializes [delegate] for subclasses.
  ReaderScrollStage(this._delegate);

  /// 更新stage的[ReaderScrollStageDelegate].
  ///
  /// 当[ReaderScrollStage]将要被弃用时调用本方法把[ReaderScrollStageDelegate]对象更新.
  void updateDelegate(ReaderScrollStageDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  void applyNewDimensions() {}

  void resetActivity() { }

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
