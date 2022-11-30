import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_state_delegate.dart';

abstract class ReaderScrollState {
  /// The delegate that this activity will use to actuate the scroll view.
  ReaderScrollStateDelegate get delegate => _delegate;
  ReaderScrollStateDelegate _delegate;

  /// Initializes [delegate] for subclasses.
  ReaderScrollState(this._delegate);

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
