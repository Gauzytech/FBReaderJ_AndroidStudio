import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/reader/animation/model/highlight_block.dart';
import 'package:flutter_lib/reader/animation/model/selection_menu_position.dart';
import 'package:flutter_lib/reader/controller/bitmap_manager_impl.dart';
import 'package:flutter_lib/reader/reader_book_content_view.dart';
import 'package:flutter_lib/utils/time_util.dart';

import '../animation/model/selection_cursor.dart';
import '../handler/selection_handler.dart';

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

    int? prevIdx = getPage(PageIndex.prev).shouldDrawImage()
        ? _bitmapManager.findInternalCacheIndex(PageIndex.prev)
        : null;
    int? nextIdx = getPage(PageIndex.next).shouldDrawImage()
        ? _bitmapManager.findInternalCacheIndex(PageIndex.next)
        : null;

    if (prevIdx != null || nextIdx != null) {
      if (prevIdx != null) {
        print("flutter内容绘制流程, 预加载上一页");
      }
      if (nextIdx != null) {
        print("flutter内容绘制流程, 预加载下一页");
      }
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

  Future<void> callNativeMethod(NativeCmd nativeCmd, int x, int y) async {
    Size imageSize = getContentSize();
    time = now();
    print('时间测试, call $nativeCmd $time');
    switch (nativeCmd) {
      case NativeCmd.dragStart:
      case NativeCmd.dragMove:
      case NativeCmd.dragEnd:
      case NativeCmd.longPressStart:
      case NativeCmd.longPressUpdate:
      case NativeCmd.longPressEnd:
      case NativeCmd.tapUp:
      case NativeCmd.selectionClear:
      Map<dynamic, dynamic> result = await methodChannel.invokeMethod(
          nativeCmd.cmdName,
          {
            'touch_x': x,
            'touch_y': y,
            'width': imageSize.width,
            'height': imageSize.height,
            'time_stamp': time,
          },
        );
        print('时间测试, $nativeCmd 获得结果, ${now()}');

        Uint8List? imageBytes = result['page'];
        if (imageBytes != null) {
          print('时间测试, $nativeCmd handleImage');
          await _handleImage(imageBytes);
        }

        // 高亮
        String? highlightsData = result['highlights_data'];
        if (highlightsData != null) {
          print('时间测试, $nativeCmd _handleHighlight');
          _handleHighlight(highlightsData);
        }

        // 显示选择弹窗
        String? selectionMenuData = result['selection_menu_data'];
        if (selectionMenuData != null) {
          _handleSelectionMenu(selectionMenuData);
        } else {
          if (nativeCmd == NativeCmd.longPressEnd && highlightsData == null) {
            print('时间测试, 取消长按状态');
            viewState.updateSelectionState(false);
          }
        }
        break;
      case NativeCmd.selectedText:
        Map<dynamic, dynamic> result = await methodChannel.invokeMethod(nativeCmd.cmdName);
        String text = result['text'];
        print('选中文字, $text');
        viewState.showText(text);
        break;
    }
  }

  Future<void> _handleImage(Uint8List imageBytes) async {
    // 将imageBytes转成img
    ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    ui.FrameInfo fi = await codec.getNextFrame();
    // _bitmapManager缓存img
    _bitmapManager.replaceBitmapCache(PageIndex.current, fi.image);
    // 刷新custom painter
    refreshContent();
  }

  void _handleHighlight(String highlightDrawData) {
    Map<String, dynamic> data = jsonDecode(highlightDrawData);
    List<HighlightBlock> blocks = (data['blocks'] as List)
        .map((item) => HighlightBlock.fromJson(item))
        .toList();

    Map<String, dynamic>? leftCursor = data['leftSelectionCursor'];
    Map<String, dynamic>? rightCursor = data['rightSelectionCursor'];
    List<SelectionCursor> cursors = [];
    if (leftCursor != null) {
      cursors.add(SelectionCursor.fromJson(CursorDirection.left, leftCursor));
    }
    if (rightCursor != null) {
      cursors.add(SelectionCursor.fromJson(CursorDirection.right, rightCursor));
    }
    viewState.updateHighlight(blocks, cursors.isNotEmpty ? cursors : null);
  }

  void _handleSelectionMenu(String selectionMenuData) {
    Map<String, dynamic> data = jsonDecode(selectionMenuData);
    SelectionMenuPosition position = SelectionMenuPosition.fromJson(data);
    Offset showPosition = position.toShowPosition(getContentSize());
    viewState.showSelectionMenu(
      showPosition,
    );
  }
}
