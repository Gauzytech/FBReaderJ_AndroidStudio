import 'dart:ui' as ui;

import 'package:flutter_lib/modal/PageIndex.dart';

class IBitmapManager {
  ui.Image? getBitmap(PageIndex index) {
    throw UnimplementedError();
  }

  int? findInternalCacheIndex(PageIndex index) {
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
