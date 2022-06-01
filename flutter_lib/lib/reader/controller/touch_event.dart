import 'dart:ui';

import 'package:flutter/gestures.dart';

import '../../utils/screen_util.dart';

class TouchEvent<T> {
  static const int ACTION_DOWN = 0;
  static const int ACTION_MOVE = 1;
  static const int ACTION_UP = 2;
  static const int ACTION_CANCEL = 3;
  static const int ACTION_FLING_RELEASED = 4;

  int action;
  T? _touchDetail;
  Offset touchPos =
      Offset(ScreenUtil.getScreenWidth(), ScreenUtil.getScreenHeight());

  TouchEvent({required this.action, required this.touchPos});

  DragEndDetails? get touchDetail => _touchDetail is DragEndDetails ? _touchDetail as DragEndDetails : null;

  @override
  bool operator ==(other) {
    if (other is! TouchEvent) {
      return false;
    }

    return (action == other.action) && (touchPos == other.touchPos);
  }

  @override
  int get hashCode => super.hashCode;

  TouchEvent copy() {
    TouchEvent event = TouchEvent(action: action, touchPos: touchPos);
    event._touchDetail = _touchDetail;
    return event;
  }

  void setTouchDetail(T detail) {
    _touchDetail = detail;
  }

  @override
  String toString() {
    String? result;
    switch(action) {
      case ACTION_DOWN:
        result = 'action = down, touchPos = $touchPos';
        break;
      case ACTION_MOVE:
        result = 'action = move, touchPos = $touchPos';
        break;
      case ACTION_UP:
        result = 'action = up, touchPos = $touchPos';
        break;
      case ACTION_CANCEL:
        result = 'action = cancel, touchPos = $touchPos';
    }

    return result ?? 'touchPos = $touchPos';
  }
}
