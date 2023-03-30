import 'dart:ui' as ui;

import 'package:flutter_lib/model/page_index.dart';
import 'package:flutter_lib/reader/animation/model/paint/line_paint_data.dart';
import 'package:flutter_lib/reader/controller/bitmap_manager_impl.dart';

import '../reader/animation/model/paint/page_paint_data.dart';

mixin BitmapManager {
  /// 缓存Bitmap大小
  static const int cacheSize = 4;

  ui.Size get contentSize;

  ImageSrc getBitmap(PageIndex index);

  int findInternalCacheIndex(PageIndex pageIndex);

  void cacheBitmap(int internalCacheIndex, ui.Image image);

  void cachePagePaintData(
    int internalCacheIndex,
    List<LinePaintData> linePaintDataList,
  );

  PaintDataSrc getPagePaintData(PageIndex pageIndex);

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
