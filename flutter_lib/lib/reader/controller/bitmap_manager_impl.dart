import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_lib/interface/i_bitmap_manager.dart';
import 'package:flutter_lib/modal/page_index.dart';

class BitmapManagerImpl extends IBitmapManager {
  /// 缓存Bitmap大小
  static const int cacheSize = 4;
  final List<ui.Image?> _imageCache = List.filled(cacheSize, null, growable: false);

  // 缓存4个pageIndex
  // pageIndex: PREV_2, PREV, CURRENT, NEXT, NEXT_2;
  List<PageIndex?> cachedPageIndexes =
      List.filled(cacheSize, null, growable: false);
  late int myWidth;
  late int myHeight;

  /// 设置绘制Bitmap的宽高（即阅读器内容区域）
  ///
  /// @param w 宽
  /// @param h 高
  void setSize(int width, int height) {
    if (myWidth != width || myHeight != height) {
      myWidth = width;
      myHeight = height;
      clear();
    }
  }

  @override
  void clear() {
    for (int i = 0; i < cacheSize; ++i) {
      _imageCache[i]?.dispose();
      _imageCache[i] = null;
      cachedPageIndexes[i] = null;
    }
  }

  /// 获取阅读器内容Bitmap
  ///
  /// @param index 页索引
  /// @return 阅读器内容Bitmap
  @override
  ui.Image? getBitmap(PageIndex index) {
    for (int i = 0; i < cacheSize; ++i) {
      if (index == cachedPageIndexes[i]) {
        return _imageCache[i]!;
      }
    }
    return null;
  }

  @override
  int? findInternalCacheIndex(PageIndex pageIndex) {
    final int internalCacheIndex = getInternalIndex(pageIndex);
    // 找到内部index先把位置占住
    cachedPageIndexes[internalCacheIndex] = pageIndex;

    if(_imageCache[internalCacheIndex] == null) {
      print("flutter内容绘制流程, 没有找到缓存的image, 请求原生绘制, 缓存idx = $internalCacheIndex");
      return internalCacheIndex;
    }
    return null;
  }

  void cacheBitmap(int internalCacheIndex, ui.Image image) {
    _imageCache[internalCacheIndex] = image;
    print("flutter内容绘制流程, 收到了图片并缓存[${image.width}, ${image.height}]");
  }

  @override
  void drawBitmap(Canvas canvas, int x, int y, PageIndex index, Paint paint) {

  }

  @override
  void drawPreviewBitmap(
      Canvas canvas, int x, int y, PageIndex index, Paint paint) {
    // TODO: implement drawPreviewBitmap
  }

  /// 获取一个内部索引位置，用于存储Bitmap（原则是：先寻找空的，再寻找非当前使用的）
  ///
  /// @return 索引位置
  int getInternalIndex(PageIndex index) {
    // 寻找没有存储内容的位置
    for (int i = 0; i < cacheSize; ++i) {
      if (cachedPageIndexes[i] == null) {
        return i;
      }
    }
    // 如果没有，找一个不是当前的位置
    for (int i = 0; i < cacheSize; ++i) {
      if (cachedPageIndexes[i] != PageIndex.current &&
          cachedPageIndexes[i] != PageIndex.prev &&
          cachedPageIndexes[i] != PageIndex.next) {
        return i;
      }
    }
    throw UnsupportedError("That's impossible");
  }

  /// 重置索引缓存
  /// TODO: 需要精确rest（避免不必要的缓存失效）
  void reset() {
    for (int i = 0; i < cacheSize; ++i) {
      cachedPageIndexes[i] = null;
    }
  }

  /// 位移操作（所有索引位移至下一状态）
  ///
  /// @param forward 是否向前
  void shift(bool forward) {
    for (int i = 0; i < cacheSize; ++i) {
      if (cachedPageIndexes[i] != null) {
        continue;
      }
      cachedPageIndexes[i] = forward
          ? cachedPageIndexes[i]!.getPrevious()
          : cachedPageIndexes[i]!.getNext();
    }
  }

  int debugSlotOccupied() {
    int space = 0;
    for (var element in _imageCache) {
      if(element != null) {
        space++;
      }
    }

    return space;
  }
}
