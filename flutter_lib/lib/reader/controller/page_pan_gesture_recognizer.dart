import 'package:flutter/gestures.dart';

class PagePanGestureRecognizer extends PanGestureRecognizer {
  bool isMenuOpen;

  PagePanGestureRecognizer(this.isMenuOpen);

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