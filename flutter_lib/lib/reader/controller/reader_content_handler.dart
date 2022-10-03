import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/modal/pair.dart';
import 'package:flutter_lib/reader/controller/bitmap_manager_impl.dart';
import 'package:flutter_lib/reader/reader_book_content_view.dart';

import '../handler/selelction_handler.dart';

class ReaderContentHandler {
  MethodChannel methodChannel;

  // late MediaQueryData _mediaQueryData;
  ReaderBookContentViewState viewState;

  // 缓存图书内容图片的manager
  final BitmapManagerImpl _bitmapManager = BitmapManagerImpl();

  // PageIndex currentPageIndex = PageIndex.prev_2;
  StreamSubscription? _streamSubscription;

  ReaderContentHandler({
    required this.methodChannel,
    required this.viewState,
  }) {
    methodChannel.setMethodCallHandler(_addNativeMethod);
  }

  ImageSrc getPage(PageIndex index) {
    return _bitmapManager.getBitmap(index);
  }

  void refreshContent() {
    viewState.viewModel?.notify();
    viewState.refreshContentPainter();
  }

  /* ---------------------------------------- Native调用Flutter方法 ----------------------------------------*/
  Future<dynamic> _addNativeMethod(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'init_load':
        // 本地数据全部解析完毕后，会执行init_load方法开始渲染图书第一页
        ImageSrc imageSrc = getPage(PageIndex.current);
        if (imageSrc.img != null) {
          refreshContent();
        } else {
          buildPage(PageIndex.current);
        }
        break;
      case "show_selection_menu":
        Uint8List imgBytes = methodCall.arguments['page'];
        int selectionStartY = methodCall.arguments['selectionStartY'];
        int selectionEndY = methodCall.arguments['selectionEndY'];
        print(
            '时间测试 selectionStartY, ${imgBytes.length}, $selectionStartY, $selectionEndY');
        break;
    }
  }

  Future<void> updatePage(PageIndex pageIndex, Uint8List imgBytes) async {
    // 将imageBytes转成img
    ui.Codec codec = await ui.instantiateImageCodec(imgBytes);
    ui.FrameInfo fi = await codec.getNextFrame();
    final image = fi.image;

    // _bitmapManager缓存img
    _bitmapManager.replaceBitmapCache(PageIndex.current, image);

    // 刷新custom painter
    refreshContent();
  }

  /// 通知native创建新内容image
  void buildPage(PageIndex pageIndex) {
    print('flutter内容绘制流程, buildPage $pageIndex');
    // 如果没有找到缓存的Image, 回调native, 通知画一个新的
    int internalIdx = _bitmapManager.findInternalCacheIndex(pageIndex);
    drawOnBitmap(internalIdx, pageIndex, true);
  }

  Future<ui.Image?> buildPageOnly(PageIndex pageIndex) async {
    print('flutter内容绘制流程, buildPageOnly, $pageIndex');
    // 如果没有找到缓存的Image, 回调native, 通知画一个新的
    int internalIdx = _bitmapManager.findInternalCacheIndex(pageIndex);
    return await drawOnBitmap(internalIdx, pageIndex, false);
  }

  /* ---------------------------------------- Flutter调用Native方法 ----------------------------------------------*/
  // 方法通道的方法是异步的
  /// 通知native绘制当前页img
  Future<ui.Image?> drawOnBitmap(
      int internalCacheIndex, PageIndex pageIndex, bool notify) async {
    try {
      final metrics = ui.window.physicalSize;

      // 调用native方法，将绘制当前page
      Uint8List imageBytes = await methodChannel.invokeMethod(
        'draw_on_bitmap',
        {
          'page_index': pageIndex.index,
          'width': metrics.width,
          'height': metrics.height,
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
    final metrics = ui.window.physicalSize;

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
        'width': metrics.width,
        'height': metrics.height,
        'update_prev_page_cache': prevIdx != null,
        'update_next_page_cache': nextIdx != null,
      });

      final prev = result['prev'];
      if (prevIdx != null && prev != null) {
        prev as Uint8List;
        ui.Codec codec = await ui.instantiateImageCodec(prev);
        ui.FrameInfo fi = await codec.getNextFrame();
        final image = fi.image;
        print(
            "flutter内容绘制流程, 收到prevPage ${prev.length} ${image.width}, ${image.height}");
        _bitmapManager.cacheBitmap(prevIdx, image);
      }

      final next = result['next'];
      if (nextIdx != null && next != null) {
        next as Uint8List;
        ui.Codec codec = await ui.instantiateImageCodec(next);
        ui.FrameInfo fi = await codec.getNextFrame();
        final image = fi.image;
        print(
            "flutter内容绘制流程, 收到prevPage ${next.length} ${image.width}, ${image.height}");
        _bitmapManager.cacheBitmap(nextIdx, image);
      }
    }

    print(
        "flutter内容绘制流程, 预加载完成, 可用cache: ${_bitmapManager.pageIndexCache}");
    print(
        "flutter动画流程:preloadAdjacentPage, 预加载完成, 可用cache: ${_bitmapManager.pageIndexCache}");
  }

  Size getContentSize() {
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
    _streamSubscription?.cancel();
    _streamSubscription = null;
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

  int time = 0;

  Future<void> callNativeMethod(String name, int x, int y) async {
    Size imageSize = getContentSize();
    time = DateTime.now().millisecondsSinceEpoch;
    print('时间测试, call $name $time');
    Map<dynamic, dynamic> result = await methodChannel.invokeMethod(
      name,
      {
        'touch_x': x,
        'touch_y': y,
        'width': imageSize.width,
        'height': imageSize.height,
        'time_stamp': time,
      },
    );
    print('时间测试, $name 获得结果, ${DateTime.now().millisecondsSinceEpoch}');

    Uint8List? imageBytes = result['page'];
    int? selectionStartY = result['selectionStartY'];
    int? selectionEndY = result['selectionEndY'];

    if(imageBytes != null) {
      // 将imageBytes转成img
      ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      ui.FrameInfo fi = await codec.getNextFrame();

      // _bitmapManager缓存img
      _bitmapManager.replaceBitmapCache(PageIndex.current, fi.image);

      // 刷新custom painter
      refreshContent();
    }

    // 显示选择弹窗
    if (selectionStartY != null && selectionEndY != null) {
      viewState.showSelectionMenu(
        getSelectionMenuPosition(selectionStartY, selectionEndY),
      );
    } else {
      if(name == longPressEnd || name == dragEnd) {
        viewState.updateSelectionState(false);
      }
    }
  }

  Offset getSelectionMenuPosition(int selectionStartY, int selectionEndY) {
    double margin = 25;
    double selectionMenuHeight = SelectionHandler.selectionMenuSize.height;
    double ratio = ui.window.devicePixelRatio;
    double startYMargin = selectionStartY - margin;
    double endYMargin = selectionEndY + margin;
    double startY = startYMargin - selectionMenuHeight * ratio;
    double startX = (getContentSize().width / ratio - SelectionHandler.selectionMenuSize.width) / 2 ;
    Offset selectionMenuPosition;
    if (startY > 0) {
      print("选择弹窗, 上方");
      // 显示在选中高亮上方
      selectionMenuPosition = Offset(startX, startY);
    } else if (endYMargin + selectionMenuHeight < getContentSize().height) {
      print("选择弹窗, 下方");
      // 显示在选中高亮下方
      selectionMenuPosition = Offset(startX, endYMargin);
    } else {
      print("选择弹窗, 居中");
      // 居中显示
      selectionMenuPosition = Offset.infinite;
    }
    return selectionMenuPosition;
  }
}
