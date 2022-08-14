import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/modal/pair.dart';
import 'package:flutter_lib/reader/controller/bitmap_manager_impl.dart';
import 'package:flutter_lib/reader/reader_book_content_view.dart';

class ReaderContentHandler {
  MethodChannel methodChannel;

  // late MediaQueryData _mediaQueryData;
  ReaderBookContentViewState readerBookContentViewState;

  // 缓存图书内容图片的manager
  final BitmapManagerImpl _bitmapManager = BitmapManagerImpl();

  // PageIndex currentPageIndex = PageIndex.prev_2;

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

  /* ---------------------------------------- Native调用Flutter方法 ----------------------------------------*/
  Future<dynamic> _addNativeMethod(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'init_load':
        // 本地数据全部解析完毕后，会执行init_load方法开始渲染图书第一页
        ImageSrc imageSrc = getPage(PageIndex.current);
        if(imageSrc.img != null) {
          refreshContent();
        } else {
          buildPage(PageIndex.current);
        }
        break;
    }
  }

  /// 通知native创建新内容image
  void buildPage(PageIndex pageIndex) {
    print('flutter内容绘制流程, buildPage $pageIndex');
    // 如果没有找到缓存的Image, 回调native, 通知画一个新的
    int internalIdx = _bitmapManager.findInternalCacheIndex(pageIndex);
    drawOnBitmap(internalIdx, pageIndex, true, true);
  }

  Future<ui.Image?> buildPageOnly(PageIndex pageIndex) async {
    print('flutter内容绘制流程, buildPageOnly, $pageIndex');
    // 如果没有找到缓存的Image, 回调native, 通知画一个新的
    int internalIdx = _bitmapManager.findInternalCacheIndex(pageIndex);
    return await drawOnBitmap(internalIdx, pageIndex, false, false);
  }

  /* ---------------------------------------- Flutter调用Native方法 ----------------------------------------------*/
  // 方法通道的方法是异步的
  /// 通知native绘制当前页img
  Future<ui.Image?> drawOnBitmap(int internalCacheIndex, PageIndex pageIndex, bool notify, bool prepareAdjacent) async {
    try {
      final metrics = _getBitmapDrawAreaMetrics();

      // 调用native方法，将绘制当前page
      Uint8List imageBytes = await methodChannel.invokeMethod(
        'draw_on_bitmap',
        {
          'page_index': pageIndex.index,
          'width': metrics.left,
          'height': metrics.right,
        },
      );

      // 将imageBytes转成img
      ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      ui.FrameInfo fi = await codec.getNextFrame();
      final image = fi.image;

      // _bitmapManager缓存img
      _bitmapManager.setSize(image.width, image.height);
      _bitmapManager.cacheBitmap(internalCacheIndex, image);

      // 刷新custom painter
      if(notify) {
        refreshContent();
      }

      return image;
    } on PlatformException catch (e) {
      print("flutter内容绘制流程, $e");
    }

    return null;
  }

  /// 到达当前页页之后, 事先缓存2页：上一页/下一页
  Future<void> preloadAdjacentPages() async {
    final metrics = _getBitmapDrawAreaMetrics();

    ImageSrc prevImage = getPage(PageIndex.prev);
    ImageSrc nextImage = getPage(PageIndex.next);

    int? prevIdx = prevImage.shouldDrawImage()
        ? _bitmapManager.findInternalCacheIndex(PageIndex.prev)
        : null;
    int? nextIdx = nextImage.shouldDrawImage()
        ? _bitmapManager.findInternalCacheIndex(PageIndex.next)
        : null;

    print("flutter动画流程:preloadAdjacentPage, 需要预加载, 上一页: ${prevIdx != null}, 下一页: ${nextIdx != null} ");
    print("flutter内容绘制流程, 需要预加载, 上一页: ${prevIdx != null}, 下一页: ${nextIdx != null} ");
    if(prevIdx != null || nextIdx != null) {
      Map<Object?, Object?> result =
      await methodChannel.invokeMethod("prepare_page", {
        'width': metrics.left,
        'height': metrics.right,
        'update_prev_page_cache': prevIdx != null,
        'update_next_page_cache': nextIdx != null,
      });

      final prev = result['prev'];
      if (prevIdx != null && prev != null) {
        prev as Uint8List;
        print("flutter内容绘制流程, 收到prevPage ${prev.length}");
        ui.Codec codec = await ui.instantiateImageCodec(prev);
        ui.FrameInfo fi = await codec.getNextFrame();
        final image = fi.image;
        _bitmapManager.cacheBitmap(prevIdx, image);
      }

      final next = result['next'];
      if (nextIdx != null && next != null) {
        next as Uint8List;
        print("flutter内容绘制流程, 收到nextPage ${next.length}");
        ui.Codec codec = await ui.instantiateImageCodec(next);
        ui.FrameInfo fi = await codec.getNextFrame();
        final image = fi.image;
        _bitmapManager.cacheBitmap(nextIdx, image);
      }
    }

    print(
        "flutter内容绘制流程, 预加载完成, 可用cache: ${_bitmapManager.cachedPageIndexes}");
    print(
        "flutter动画流程:preloadAdjacentPage, 预加载完成, 可用cache: ${_bitmapManager.cachedPageIndexes}");
  }

  List<double> getContentSize() {
    return _bitmapManager.getContentSize();
  }

  void shift(bool forward) {
    _bitmapManager.shift(forward);
  }

  PageIndex getPageIndex(bool forward) {
    return PageIndex.current;
  }

  void clear() {
    _bitmapManager.clear();
  }

  /// 判断是否可以滚动到上一页/下一页
  Future<bool> canScroll(PageIndex pageIndex) async {
    return await methodChannel.invokeMethod(
      'can_scroll',
      {'page_index': pageIndex.index},
    );
  }

  void onScrollingFinished(PageIndex pageIndex) {
    methodChannel.invokeMethod(
      'on_scrolling_finished',
      {'page_index': pageIndex.index},
    );
  }

  /// 获得需要绘制图片区域的跨高.
  /// returns [Pair] of [widthPx, heightPx].
  Pair _getBitmapDrawAreaMetrics() {
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
    return Pair(widthPx, heightPx);
  }
}
