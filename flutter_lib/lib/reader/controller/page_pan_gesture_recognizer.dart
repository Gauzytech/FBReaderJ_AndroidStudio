import 'package:flutter/gestures.dart';

/// Recognizes movement both horizontally and vertically.
class PagePanDragRecognizer extends PanGestureRecognizer {
  bool isMenuOpen = false;

  PagePanDragRecognizer();

  void setMenuOpen(bool isOpen) {
    isMenuOpen = isOpen;
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