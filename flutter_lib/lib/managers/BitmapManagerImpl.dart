import 'dart:ui';

import 'package:flutter_lib/interface/i_bitmap_manager.dart';
import 'package:flutter_lib/modal/PageIndex.dart';

class BitmapManagerImpl extends IBitmapManager {
  /// 缓存Bitmap大小
  static const int cacheSize = 4;
  List<Image?> myBitmaps = List.filled(cacheSize, null, growable: false);

  // 缓存4个pageIndex
  // pageIndex: PREV_2, PREV, CURRENT, NEXT, NEXT_2;
  List<PageIndex?> cachedPageIndexes =
      List.filled(cacheSize, null, growable: false);
  int myWidth;
  int myHeight;

  BitmapManagerImpl({required this.myWidth, required this.myHeight});

  /// 设置绘制Bitmap的宽高（即阅读器内容区域）
  ///
  /// @param w 宽
  /// @param h 高
  void setSize(int width, int height) {
    if (myWidth != width || myHeight != height) {
      myWidth = width;
      myHeight = height;
      for (int i = 0; i < cacheSize; ++i) {
        myBitmaps[i] = null;
        cachedPageIndexes[i] = null;
      }
      // System.gc();
      // System.gc();
      // System.gc();
    }
  }

  @override
  void drawBitmap(Canvas canvas, int x, int y, PageIndex index, Paint paint) {}

  @override
  void drawPreviewBitmap(
      Canvas canvas, int x, int y, PageIndex index, Paint paint) {
    // TODO: implement drawPreviewBitmap
  }

  @override
  Image getBitmap(PageIndex index, String from) {
    // TODO: implement getBitmap
    throw UnimplementedError();
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
}
