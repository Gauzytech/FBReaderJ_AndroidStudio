import 'package:flutter/rendering.dart';
import 'package:flutter_lib/interface/debug_info_provider.dart';

class PagePaintMetaData with DebugInfoProvider{
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
  void debugFillDescription(List<String> description) {
    description.add("pixels: ${pixels.toStringAsFixed(2)}");
    description.add("page: ${page.toStringAsFixed(2)}");
    description.add("userScrollDirection: ${userScrollDirection.name}");
  }
}
