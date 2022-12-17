import 'package:flutter/rendering.dart';

class PagePaintMetaData {
  double pixels;
  double page;
  ScrollDirection userScrollDirection;

  PagePaintMetaData(this.pixels, this.page, this.userScrollDirection);
}
