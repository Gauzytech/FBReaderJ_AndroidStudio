import 'package:flutter/gestures.dart';

/// Recognizes movement both horizontally and vertically.
class PagePanDragRecognizer extends PanGestureRecognizer {
  bool isMenuOpen = false;
  bool _selectionMenuShown = false;

  PagePanDragRecognizer();

  void setMenuOpen(bool isOpen) {
    isMenuOpen = isOpen;
  }

  void setSelectionMenuState(bool isShow) {
    _selectionMenuShown = isShow;
  }

  bool isSelectionMenuShown() {
    return _selectionMenuShown;
  }

  @override
  String get debugDescription => "page pan gesture recognizer";

  @override
  void addPointer(PointerDownEvent event) {
    if (!isMenuOpen) {
      super.addPointer(event);
    }
  }
}