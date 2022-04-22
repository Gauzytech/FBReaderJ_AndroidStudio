import 'dart:ui' as ui;

import 'package:flutter_lib/modal/PageIndex.dart';

class IBitmapManager {

  ui.Image getBitmap(PageIndex index, String from) {
    throw UnimplementedError();
  }

  void drawBitmap(
      ui.Canvas canvas, int x, int y, PageIndex index, ui.Paint paint) {}

  void drawPreviewBitmap(
      ui.Canvas canvas, int x, int y, PageIndex index, ui.Paint paint) {}
}
