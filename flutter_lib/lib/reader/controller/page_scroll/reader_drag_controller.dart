import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_stage_delegate.dart';

/// 当用户在屏幕上拖动手指， 开始产生阅读界面当滚动效果
class ReaderDragController implements Drag {
  ReaderDragController({
    required ReaderScrollStageDelegate delegate,
    required DragStartDetails details,
    this.onDragCanceled,
  })
      : _delegate = delegate,
        _lastDetails = details;

  /// 通过委托与对阅读界面交互.
  ReaderScrollStageDelegate get delegate => _delegate;
  ReaderScrollStageDelegate _delegate;

  /// 在[dispose]调用.
  final VoidCallback? onDragCanceled;

  /// 最近的一次滚动事件: [DragStartDetails], [DragUpdateDetails], 或
  /// [DragEndDetails].
  dynamic get lastDetails => _lastDetails;
  dynamic _lastDetails;

  bool get _reversed => axisDirectionIsReversed(delegate.axisDirection);

  void updateDelegate(ReaderScrollStageDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  @override
  void update(DragUpdateDetails details) {
    assert(details.primaryDelta != null);
    _lastDetails = details;
    double offset = details.primaryDelta!;

    if(_reversed) {
      offset = -offset;
    }
    delegate.applyUserOffset(offset);
  }

  @override
  void end(DragEndDetails details) {
    assert(details.primaryVelocity != null);
    double velocity = -details.primaryVelocity!;
    if (_reversed) {
      velocity = -velocity;
    }
    delegate.goBallistic(velocity);
  }

  @override
  void cancel() {
    delegate.goBallistic(0.0);
  }

  /// 当滚动事件终止, 会被委托调用
  @mustCallSuper
  void dispose() {
    _lastDetails = null;
    onDragCanceled?.call();
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    description.add('lastDetails: $lastDetails');
    return '${describeIdentity(this)}(${description.join(", ")})';
  }
}
