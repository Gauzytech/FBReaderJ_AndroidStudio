import 'dart:ui' as ui;

import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/reader/controller/bitmap_manager_impl.dart';

class IBitmapManager {
  ImageSrc getBitmap(PageIndex index) {
    throw UnimplementedError();
  }

  int findInternalCacheIndex(PageIndex pageIndex) {
    throw UnimplementedError();
  }

  void drawBitmap(
      ui.Canvas canvas, int x, int y, PageIndex index, ui.Paint paint) {
    throw UnimplementedError();
  }

  void drawPreviewBitmap(
      ui.Canvas canvas, int x, int y, PageIndex index, ui.Paint paint) {
    throw UnimplementedError();
  }

  void clear() {
    throw UnimplementedError();
  }
}
