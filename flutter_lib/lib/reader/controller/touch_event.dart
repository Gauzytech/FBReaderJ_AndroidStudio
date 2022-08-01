import 'dart:ui';

import 'package:flutter/gestures.dart';

import '../../utils/screen_util.dart';

class TouchEvent<T> {
  static const int ACTION_DRAG_START = 0;
  static const int ACTION_MOVE = 1;
  static const int ACTION_DRAG_END = 2;
  static const int ACTION_CANCEL = 3;
  static const int ACTION_FLING_RELEASED = 4;
  static const int ACTION_ANIMATION_DONE = 5;

  int action;
  T? _touchDetail;
  Offset touchPosition =
      Offset(ScreenUtil.getScreenWidth(), ScreenUtil.getScreenHeight());

  TouchEvent({required this.action, required this.touchPosition});

  TouchEvent.fromOnDown(this.action, this.touchPosition);

  TouchEvent.fromOnUpdate(this.action, this.touchPosition);

  TouchEvent.fromOnEnd(this.action, this.touchPosition, DragEndDetails details) {
    _touchDetail = details as T;
  }

  DragEndDetails? get touchDetail => _touchDetail is DragEndDetails ? _touchDetail as DragEndDetails : null;

  @override
  bool operator ==(other) {
    if (other is! TouchEvent) {
      return false;
    }

    return (action == other.action) && (touchPosition == other.touchPosition);
  }

  @override
  int get hashCode => super.hashCode;

  TouchEvent copy() {
    TouchEvent event = TouchEvent(action: action, touchPosition: touchPosition);
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
      case ACTION_DRAG_START:
        result = 'action = down, touchPosition = $touchPosition';
        break;
      case ACTION_MOVE:
        result = 'action = move, touchPosition = $touchPosition';
        break;
      case ACTION_DRAG_END:
        result =
            'action = up, touchPosition = $touchPosition, detail: $_touchDetail';
        break;
      case ACTION_CANCEL:
        result = 'action = cancel, touchPosition = $touchPosition';
    }

    return result ?? 'touchPosition = $touchPosition';
  }

  String get actionName {
    switch (action) {
      case ACTION_DRAG_START:
        return 'ACTION_DOWN';
      case ACTION_MOVE:
        return 'ACTION_MOVE';
      case ACTION_DRAG_END:
        return 'ACTION_UP';
      case ACTION_CANCEL:
        return 'ACTION_CANCEL';
      default:
        return "ACTION_FLING_RELEASED";
    }
  }

  List<String> get touchPoint {
    return [
      touchPosition.dx.toStringAsFixed(1),
      touchPosition.dy.toStringAsFixed(1)
    ];
  }
}
