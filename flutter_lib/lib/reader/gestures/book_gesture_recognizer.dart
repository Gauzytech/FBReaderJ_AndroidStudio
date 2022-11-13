import 'package:flutter/gestures.dart';

mixin BookGestureRecognizer {

  bool _isReadMenuOpen = false;

  bool _isSelectionMenuOpen = false;

  bool get isMenuOpen => _isReadMenuOpen;

  void setReadMenu(bool open) {
    _isReadMenuOpen = open;
  }

  void setSelectionMenuOpen(bool open) {
    _isSelectionMenuOpen = open;
  }

  String get debugDescription =>
      "_isReadMenuOpen = $_isReadMenuOpen, _isSelectionMenuOpen = $_isSelectionMenuOpen";
}


class BookVerticalDragGestureRecognizer extends VerticalDragGestureRecognizer with BookGestureRecognizer {

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!isMenuOpen) {
      super.addAllowedPointer(event);
    }
  }
}

class BookHorizontalDragGestureRecognizer extends HorizontalDragGestureRecognizer with BookGestureRecognizer {

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!isMenuOpen) {
      super.addAllowedPointer(event);
    }
  }
}
