import 'package:flutter/rendering.dart';

class PagePaintMetaData {
  double pixels;
  double page;
  ScrollDirection userScrollDirection;
  VoidCallback? onPageCentered;

  PagePaintMetaData({
    this.pixels = 0,
    this.page = 0,
    this.userScrollDirection = ScrollDirection.idle,
    this.onPageCentered,
  });

  void apply(PagePaintMetaData other) {
    pixels = other.pixels;
    page = other.page;
    userScrollDirection = other.userScrollDirection;
    onPageCentered = other.onPageCentered;
  }

  @override
  String toString() {
    return 'MetaData{pixels: $pixels, page: $page, $userScrollDirection}';
  }
}
