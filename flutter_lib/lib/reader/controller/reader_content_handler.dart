import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/reader/controller/bitmap_manager_impl.dart';
import 'package:flutter_lib/reader/reader_book_content_view.dart';

class ReaderContentHandler {
  MethodChannel methodChannel;

  // late MediaQueryData _mediaQueryData;
  ReaderBookContentViewState readerBookContentViewState;

  // 缓存图书内容图片的manager
  final BitmapManagerImpl _bitmapManager = BitmapManagerImpl();

  PageIndex currentPageIndex = PageIndex.prev_2;

  ReaderContentHandler(
      {required this.methodChannel, required this.readerBookContentViewState}) {
    methodChannel.setMethodCallHandler(_addNativeMethod);
  }

  ImageSrc getPage(PageIndex index) {
    return _bitmapManager.getBitmap(index);
  }

  void refreshContent() {
    readerBookContentViewState.viewModel?.notify();
    readerBookContentViewState.contentKey.currentContext
        ?.findRenderObject()
        ?.markNeedsPaint();
  }

  // Native调用Flutter方法
  Future<dynamic> _addNativeMethod(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'init_render':
        // 渲染第一页
        currentPageIndex = PageIndex.current;
        ImageSrc imageSrc = getPage(currentPageIndex);
        if(imageSrc.img != null) {
          refreshContent();
        } else {
          buildPage(currentPageIndex);
        }
        break;
    }
  }

  /// 通知native创建新内容image
  void buildPage(PageIndex pageIndex) {
    // 如果没有找到缓存的Image, 回调native, 通知画一个新的
    int internalIdx = _bitmapManager.findInternalCacheIndex(pageIndex);
    drawOnBitmap(internalIdx, pageIndex, true, true);
  }

  Future<ui.Image?> buildPageOnly(PageIndex pageIndex) async {
    // 如果没有找到缓存的Image, 回调native, 通知画一个新的
    int internalIdx = _bitmapManager.findInternalCacheIndex(pageIndex);
    return await drawOnBitmap(internalIdx, pageIndex, false, false);
  }

  // Flutter调用Native方法
  // 方法通道的方法是异步的
  Future<ui.Image?> drawOnBitmap(int internalCacheIndex, PageIndex pageIndex, bool notify, bool prepareAdjacent) async {
    try {
      final ratio = MediaQuery.of(readerBookContentViewState.context).devicePixelRatio;

      print("flutter内容绘制流程, render_page, "
          "ratio = ${MediaQuery.of(readerBookContentViewState.context).devicePixelRatio}, "
          "windowSize = ${ui.window.physicalSize},"
          "footerHeight = ${readerBookContentViewState.footerKey.currentContext?.size?.height},");

      // 屏幕宽度
      double widthPx = ui.window.physicalSize.width;
      // 屏幕高度 - footer高度
      double heightPx = ui.window.physicalSize.height -
          readerBookContentViewState.footerKey.currentContext!.size!.height *
              ratio;
      Uint8List imageBytes = await methodChannel.invokeMethod(
        'draw_on_bitmap',
        {
          'page_index': pageIndex.index,
          'width': widthPx,
          'height': heightPx,
        },
      );

      ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      ui.FrameInfo fi = await codec.getNextFrame();
      final image = fi.image;

      // 原生那边绘制完了, 就缓存
      _bitmapManager.cacheBitmap(internalCacheIndex, image);

      if(notify) {
        refreshContent();
      }

      if(prepareAdjacent) {
        // 准备相邻的前, 后页面
        _prepareAdjacentPage(widthPx, heightPx);
      }

      return image;
    } on PlatformException catch (e) {
      print("flutter内容绘制流程, $e");
    }

    return null;
  }

  // Flutter调用Native方法
  // 方法通道的方法是异步的
  Future<void> _prepareAdjacentPage(double widthPx, double heightPx) async {
    ImageSrc prevImage = getPage(PageIndex.prev);
    ImageSrc nextImage = getPage(PageIndex.next);

    int? prevIdx = prevImage.img == null ? _bitmapManager.findInternalCacheIndex(PageIndex.prev) : null;
    int? nextIdx = nextImage.img == null ? _bitmapManager.findInternalCacheIndex(PageIndex.next) : null;

    print("flutter内容绘制流程, 准备相邻页面${prevImage == null}, ${nextImage == null}");
    Map<Object?, Object?> result =
        await methodChannel.invokeMethod("prepare_page", {
      'width': widthPx,
      'height': heightPx,
      'update_prev_page_cache': prevIdx != null,
      'update_next_page_cache': nextIdx != null,
    });

    final prev = result['prev'];
    if (prevIdx != null && prev != null) {
      prev as Uint8List;
      print("flutter内容绘制流程, 收到prevPage ${prev.length}, 插入$prevIdx");
      ui.Codec codec = await ui.instantiateImageCodec(prev);
      ui.FrameInfo fi = await codec.getNextFrame();
      final image = fi.image;
      _bitmapManager.cacheBitmap(prevIdx, image);
    }

    final next = result['next'];
    if (nextIdx != null && next != null) {
      next as Uint8List;
      print("flutter内容绘制流程, 收到nextPage ${next.length}, 插入$nextIdx");
      ui.Codec codec = await ui.instantiateImageCodec(next);
      ui.FrameInfo fi = await codec.getNextFrame();
      final image = fi.image;
      _bitmapManager.cacheBitmap(nextIdx, image);
    }

    print(
        "flutter内容绘制流程, 准备完成, 可用cache: ${_bitmapManager.cachedPageIndexes}");
  }

  List<double> getContentSize() {
    final pageImage = getPage(currentPageIndex).img;
    if (pageImage == null) {
      return [0, 0];
    }

    return [pageImage.width.toDouble(), pageImage.height.toDouble()];
  }

  void clear() {
    _bitmapManager.clear();
  }
}
