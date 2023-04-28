import 'package:flutter/gestures.dart';

enum EventAction {
  dragStart,
  move,
  dragEnd,
  cancel,
  flingReleased,
  noAnimationForward,
  noAnimationBackward,
}

class TouchEvent<T> {
  EventAction action;
  T? _touchDetail;
  Offset touchPosition;

  double pixels;

  TouchEvent(
      {required this.action,
      required this.touchPosition,
      required this.pixels});

  TouchEvent.fromOnDown(this.action, this.touchPosition, this.pixels);

  TouchEvent.fromOnUpdate(this.action, this.touchPosition, this.pixels);

  TouchEvent.fromOnEnd(
      this.action, this.touchPosition, DragEndDetails details, this.pixels) {
    _touchDetail = details as T;
  }

  DragEndDetails? get touchDetail =>
      _touchDetail is DragEndDetails ? _touchDetail as DragEndDetails : null;

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
    TouchEvent event = TouchEvent(action: action, touchPosition: touchPosition, pixels: pixels);
    event._touchDetail = _touchDetail;
    return event;
  }

  void setTouchDetail(T detail) {
    _touchDetail = detail;
  }

  @override
  String toString() {
    String? result;
    switch (action) {
      case EventAction.dragStart:
        result = 'action = down, touchPosition = $touchPosition';
        break;
      case EventAction.move:
        result = 'action = move, touchPosition = $touchPosition';
        break;
      case EventAction.dragEnd:
        result =
            'action = up, touchPosition = $touchPosition, detail: $_touchDetail';
        break;
      case EventAction.cancel:
        result = 'action = cancel, touchPosition = $touchPosition';
        break;
      default:
    }

    return result ?? 'touchPosition = $touchPosition';
  }

  String get actionName {
    switch (action) {
      case EventAction.dragStart:
        return 'ACTION_DOWN';
      case EventAction.move:
        return 'ACTION_MOVE';
      case EventAction.dragEnd:
        return 'ACTION_UP';
      case EventAction.cancel:
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
