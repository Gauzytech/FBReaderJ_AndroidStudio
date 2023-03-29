import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_lib/interface/bitmap_manager.dart';
import 'package:flutter_lib/model/page_index.dart';
import 'package:flutter_lib/reader/animation/model/paint/line_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/paint/page_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/geometry.dart';

/// Bitmap管理（绘制后的图）的实现
class BitmapManagerImpl with BitmapManager {
  final List<ui.Image?> _imageCache =
      List.filled(BitmapManager.cacheSize, null, growable: false);

  // 缓存4个pageIndex
  // pageIndex: PREV_2, PREV, CURRENT, NEXT, NEXT_2;
  final List<PageIndex?> _pageIndexCache =
      List.filled(BitmapManager.cacheSize, null, growable: false);
  int _contentWidth = 0;
  int _contentHeight = 0;

  final List<PagePaintData?> _pageDataCache =
      List.filled(BitmapManager.cacheSize, null, growable: false);

  bool get hasGeometry => _geometry != null;

  Geometry get geometry => _geometry!;
  Geometry? _geometry;

  @override
  Size get contentSize =>
      Size(_contentWidth.toDouble(), _contentHeight.toDouble());

  /// 设置绘制Bitmap的宽高（即阅读器内容区域）
  ///
  /// @param width 宽
  /// @param height 高
  void setSize(int width, int height) {
    if (_contentWidth != width || _contentHeight != height) {
      _contentWidth = width;
      _contentHeight = height;
      // clear();
    }
  }

  void setGeometry(Geometry geometry) {
    _geometry = geometry;
  }

  @override
  void clear() {
    for (int i = 0; i < BitmapManager.cacheSize; ++i) {
      _imageCache[i]?.dispose();
      _imageCache[i] = null;
      _pageDataCache[i]?.dispose();
      _pageIndexCache[i] = null;
    }
  }

  /// 获取阅读器内容Bitmap
  ///
  /// @param index 页索引
  /// @return 阅读器内容Bitmap
  @override
  ImageSrc getBitmap(PageIndex index) {
    for (int i = 0; i < BitmapManager.cacheSize; ++i) {
      if (_pageIndexCache[i] == index) {
        ui.Image? image = _imageCache[i];
        return ImageSrc(img: image, processing: image == null);
      }
    }
    return ImageSrc(img: null, processing: false);
  }

  /// 调用方法会先在cachedPageIndexes将缓存page index占住，
  /// 但是_imageCache中的image可能还是null
  @override
  int findInternalCacheIndex(PageIndex pageIndex) {
    print(
        "flutter内容绘制流程[findInternalCacheIndex], $pageIndex, $indexCacheDebugDescription}");
    final int internalCacheIndex = _findInternalIndex(pageIndex);
    // 找到内部index先把位置占住
    _pageIndexCache[internalCacheIndex] = pageIndex;

    // if (_imageCache[internalCacheIndex] == null) {
    //   return internalCacheIndex;
    // } else {
    //   // 如果已经存在一个image, 直接清掉
    //   _imageCache[internalCacheIndex]!.dispose();
    //   _imageCache[internalCacheIndex] = null;
    //   return internalCacheIndex;
    // }

    if (_pageDataCache[internalCacheIndex] == null) {
      return internalCacheIndex;
    } else {
      // 如果已经存在一个image, 直接清掉
      _pageDataCache[internalCacheIndex]!.dispose();
      _pageDataCache[internalCacheIndex] = null;
      return internalCacheIndex;
    }
  }

  @override
  void cacheBitmap(int internalCacheIndex, ui.Image image) {
    print(
        "flutter内容绘制流程, 收到了图片并缓存[${image.width}, ${image.height}], idx = $internalCacheIndex");
    _imageCache[internalCacheIndex] = image;
  }

  void replaceBitmapCache(PageIndex index, ui.Image image) {
    print(
        "flutter内容绘制流程, replaceBitmapCache [${image.width}, ${image.height}], PageIndex = $index");
    for (int i = 0; i < _pageIndexCache.length; i++) {
      if (_pageIndexCache[i] == index) {
        // dispose old image
        _imageCache[i]?.dispose();
        _imageCache[i] = image;
        break;
      }
    }
  }

  @override
  void drawBitmap(Canvas canvas, int x, int y, PageIndex index, Paint paint) {
    // TODO: implement drawBitmap
  }

  @override
  void drawPreviewBitmap(
      Canvas canvas, int x, int y, PageIndex index, Paint paint) {
    // TODO: implement drawPreviewBitmap
  }

  /// 获取一个内部索引位置，用于存储Bitmap（原则是：先寻找空的，再寻找非当前使用的）
  ///
  /// @return 索引位置
  int _findInternalIndex(PageIndex index) {
    // 寻找没有存储内容的位置
    for (int i = 0; i < BitmapManager.cacheSize; ++i) {
      if (_pageIndexCache[i] == null) {
        return i;
      }
    }
    // 如果没有，找一个不是当前的位置
    for (int i = 0; i < BitmapManager.cacheSize; ++i) {
      if (_pageIndexCache[i] != PageIndex.current &&
          _pageIndexCache[i] != PageIndex.prev &&
          _pageIndexCache[i] != PageIndex.next) {
        return i;
      }
    }
    throw UnsupportedError("That's impossible");
  }

  /// 重置索引缓存
  /// TODO: 需要精确rest（避免不必要的缓存失效）
  void reset() {
    for (int i = 0; i < BitmapManager.cacheSize; ++i) {
      _pageIndexCache[i] = null;
    }
  }

  /// 位移操作（所有索引位移至下一状态）
  ///
  /// @param forward 是否向前
  /// 
  /// current, prev, next, null
  ///
  /// shift forward
  /// prev, prev2, current, null
  ///
  /// shift backward
  /// next, current, next2, null
  void shift(bool forward) {
    for (int i = 0; i < BitmapManager.cacheSize; ++i) {
      if (_pageIndexCache[i] == null) continue;
      if (forward) {
        _pageIndexCache[i] = _pageIndexCache[i]!.getPrevious();
      } else {
        _pageIndexCache[i] = _pageIndexCache[i]!.getNext();
      }
    }
  }

  String get indexCacheDebugDescription => '$_pageIndexCache';

  bool isEmpty() {
    for (int i = 0; i < BitmapManager.cacheSize; ++i) {
      if (_pageIndexCache[i] != null) return false;
      // if (_imageCache[i] != null) return false;
      if (_pageDataCache[i] != null) return false;
    }
    return true;
  }

  @override
  void cachePagePaintData(
    int internalCacheIndex,
    List<LinePaintData> linePaintDataList,
  ) {
    print('flutter内容绘制流程[cachePagePaintData], $internalCacheIndex -> length = ${linePaintDataList.length}');
    _pageDataCache[internalCacheIndex] =
        PagePaintData(linePaintDataList.toList());
  }

  @override
  PagePaintData? getPagePaintData(PageIndex pageIndex) {
    print('flutter内容绘制流程[getPagePaintData], $_pageIndexCache, pageIndex = $pageIndex');
    for (int i = 0; i < BitmapManager.cacheSize; i++) {
      if (_pageIndexCache[i] == pageIndex) {
        return _pageDataCache[i];
      }
    }
    return null;
  }
}

class ImageSrc {
  ui.Image? img;
  bool processing;

  ImageSrc({required this.img, required this.processing});

  bool shouldDrawImage() {
    return img == null && !processing;
  }

  @override
  String toString() {
    return 'img = ${img != null}, processing = $processing';
  }
}
