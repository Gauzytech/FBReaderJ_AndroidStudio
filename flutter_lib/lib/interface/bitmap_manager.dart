import 'dart:ui' as ui;

import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/reader/controller/bitmap_manager_impl.dart';

mixin BitmapManager {
  /// 缓存Bitmap大小
   static const int cacheSize = 4;

  ImageSrc getBitmap(PageIndex index);

  int findInternalCacheIndex(PageIndex pageIndex);

  void drawBitmap(
    ui.Canvas canvas,
    int x,
    int y,
    PageIndex index,
    ui.Paint paint,
  );

  void drawPreviewBitmap(
    ui.Canvas canvas,
    int x,
    int y,
    PageIndex index,
    ui.Paint paint,
  );

  void clear();
}
