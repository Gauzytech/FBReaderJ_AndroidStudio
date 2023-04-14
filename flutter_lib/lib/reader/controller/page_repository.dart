import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_lib/model/page_index.dart';
import 'package:flutter_lib/reader/animation/model/highlight_block.dart';
import 'package:flutter_lib/reader/animation/model/paint/line_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/paint/page_paint_data.dart';
import 'package:flutter_lib/reader/animation/model/paint/style/style_models/nr_text_style_collection.dart';
import 'package:flutter_lib/reader/animation/model/selection_menu_position.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/geometry.dart';
import 'package:flutter_lib/reader/controller/bitmap_manager_impl.dart';
import 'package:flutter_lib/reader/controller/reader_page_view_model.dart';
import 'package:flutter_lib/utils/time_util.dart';
import 'package:path_provider/path_provider.dart';

import '../animation/model/selection_cursor.dart';
import 'native_interface.dart';

extension ImageParsing on Uint8List {
  /// 将[Uint8List]转成[Image]
  Future<ui.Image> toImage() async {
    ui.Codec codec = await ui.instantiateImageCodec(this);
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }
}

mixin PageRepositoryDelegate {
  Future<void> initialize(PageIndex pageIndex);

  void tearDown();

  void refreshContent();
}

class PageRepository with PageRepositoryDelegate {

  // 缓存图书内容图片的manager
  final BitmapManagerImpl _bitmapManager = BitmapManagerImpl();

  // native代码通信interface
  NativeInterface? _nativeInterface;

  NativeInterface get nativeInterface => _nativeInterface!;

  ReaderPageViewModelDelegate? _readerPageViewModelDelegate;

  Directory? _rootDirectory;

  Directory get rootDirectory => _rootDirectory!;

  bool get hasGeometry => _bitmapManager.hasGeometry;

  Geometry get geometry => _bitmapManager.geometry;

  PageRepository({required MethodChannel methodChannel}) {
    _nativeInterface = NativeInterface(
      methodChannel: methodChannel,
      delegate: this,
    );
  }

  ImageSrc getPage(PageIndex index) => _bitmapManager.getBitmap(index);

  PaintDataSrc getPagePaintData(PageIndex pageIndex) =>
      _bitmapManager.getPagePaintData(pageIndex);

  @override
  void refreshContent() {
    // viewState.viewModel?.notify();
    _readerPageViewModelDelegate!.scrollContext.invalidateContent();
  }

  Future<void> fetchRootPath() async {
    // todo 区分安卓和iOS的私有文件夹目录
    _rootDirectory ??= await getExternalStorageDirectory();
  }

  @override
  Future<void> initialize(PageIndex pageIndex) async {
    print('flutter内容绘制流程[initialize], $pageIndex');
    fetchRootPath();
    // 如果没有找到缓存的Image, 回调native, 通知画一个新的
    int internalIdx = _bitmapManager.findInternalCacheIndex(pageIndex);
    try {
      // 调用native方法，获取page的绘制数据
      Map<dynamic, dynamic> result = await nativeInterface.evaluateNativeFunc(
        NativeScript.drawOnBitmap,
        {'page_index': pageIndex.index},
      );

      Map<String, dynamic> pageData = jsonDecode(result['page_data']);
      NRTextStyleCollection styleCollection = NRTextStyleCollection.fromJson(pageData['text_style_collection']);
      List<LinePaintData> lineData =
          LinePaintData.fromJsonList(pageData['line_paint_data_list']);
      int width = ui.window.physicalSize.width.toInt();
      int height = ui.window.physicalSize.height.toInt();

      print('flutter内容绘制流程, 收到了PaintData: ${lineData.length}');
      for (var element in lineData) {
        // print('flutter内容绘制流程, ------- ${element.runtimeType} -------');
        for (var data in element.elementPaintDataList) {
          print('flutter内容绘制流程, data = $data');
        }
      }

      // final image = await imgBytes.toImage();

      // _bitmapManager缓存img
      // _bitmapManager.setSize(image.width, image.height);
      // _bitmapManager.cacheBitmap(internalIdx, image);

      // 初始化page滚动相关的数据并通知页面刷新
      // _readerPageViewModelDelegate!.initialize(image.width, image.height);

      _bitmapManager.setSize(width, height);
      _bitmapManager.setGeometry(Geometry.fromJson(pageData['geometry']));
      _bitmapManager.cachePagePaintData(
        internalIdx,
        PagePaintData(styleCollection, lineData.toList()),
      );
      _readerPageViewModelDelegate!.initialize(width, height);
    } on PlatformException catch (e) {
      print("flutter内容绘制流程, $e");
    }
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

  Future<void> preparePagePaintData(PageIndex pageIndex) async {
    // 找一个缓存slot先占位
    int internalIdx = _bitmapManager.findInternalCacheIndex(pageIndex);
    _preparePagePaintData(internalIdx, pageIndex);
  }

  /* ---------------------------------------- Flutter调用Native方法 ----------------------------------------------*/
  // 方法通道的方法是异步的
  /// 通知native绘制当前页img
  Future<ui.Image?> drawOnBitmap(
    int internalCacheIndex,
    PageIndex pageIndex,
    bool notify,
  ) async {
    try {
      // 调用native方法，将绘制当前page
      Uint8List imgBytes = await nativeInterface.evaluateNativeFunc(
        NativeScript.drawOnBitmap,
        {'page_index': pageIndex.index},
      );

      // 将imageBytes转成img
      var image = await imgBytes.toImage();
      // _bitmapManager缓存img
      _bitmapManager.setSize(image.width, image.height);
      _bitmapManager.cacheBitmap(internalCacheIndex, image);

      // 刷新custom painter
      if (notify) {
        refreshContent();
      }

      return image;
    } on PlatformException catch (e) {
      print("flutter内容绘制流程, $e");
    }

    return null;
  }

  Future<void> _preparePagePaintData(
    int internalCacheIndex,
    PageIndex pageIndex,
  ) async {
    try {
      print('flutter_perf[preparePagePaintData], 请求PaintData ${now()}');
      // 调用native方法，获取page的绘制数据
      Map<dynamic, dynamic> result = await nativeInterface.evaluateNativeFunc(
        NativeScript.buildPagePaintData,
        {'page_index': pageIndex.index},
      );

      print('flutter_perf[preparePagePaintData], 收到了PaintData ${now()}');

      Map<String, dynamic> pageData = jsonDecode(result['page_data']);
      NRTextStyleCollection styleCollection = NRTextStyleCollection.fromJson(pageData['text_style_collection']);
      List<LinePaintData> lineData =
          LinePaintData.fromJsonList(pageData['line_paint_data_list']);
      _bitmapManager.cachePagePaintData(
        internalCacheIndex,
        PagePaintData(styleCollection, lineData.toList()),
      );
      print('flutter_perf[preparePagePaintData], JSON转换完毕 ${now()}');

      print(
          'flutter内容绘制流程[preparePagePaintData], 收到了PaintData: ${lineData.length}');
      refreshContent();
      // for (var item in lineData) {
      //   // print('flutter内容绘制流程, ------- ${element.runtimeType} -------');
      //   for (var lineElement in item.elementPaintDataList) {
      //     if(lineElement is WordElementPaintData) {
      //       for (var element in lineElement.textBlock.data) {
      //         print('flutter内容绘制流程[preparePagePaintData], data = $element');
      //       }
      //     }
      //   }
      // }
    } on PlatformException catch (e) {
      print("flutter内容绘制流程, $e");
    }
  }

  /// 到达当前页之后, 事先缓存2页：上一页/下一页
  Future<void> preloadAdjacentPages() async {
    int? prevIdx = getPage(PageIndex.prev).shouldDrawImage()
        ? _bitmapManager.findInternalCacheIndex(PageIndex.prev)
        : null;
    int? nextIdx = getPage(PageIndex.next).shouldDrawImage()
        ? _bitmapManager.findInternalCacheIndex(PageIndex.next)
        : null;

    if (prevIdx != null || nextIdx != null) {
      if (prevIdx != null) print("flutter内容绘制流程, 预加载上一页");
      if (nextIdx != null) print("flutter内容绘制流程, 预加载下一页");

      Map<Object?, Object?> result = await nativeInterface.evaluateNativeFunc(
        NativeScript.preparePage,
        {
          'update_prev_page_cache': prevIdx != null,
          'update_next_page_cache': nextIdx != null,
        },
      );

      final prev = result['prev'];
      if (prevIdx != null && prev != null) {
        prev as Uint8List;
        var image = await prev.toImage();
        print(
            "flutter内容绘制流程, 收到prevPage ${prev.length} ${image.width}, ${image.height}");
        _bitmapManager.cacheBitmap(prevIdx, image);
      }

      final next = result['next'];
      if (nextIdx != null && next != null) {
        next as Uint8List;
        var image = await next.toImage();
        print(
            "flutter内容绘制流程, 收到prevPage ${next.length} ${image.width}, ${image.height}");
        _bitmapManager.cacheBitmap(nextIdx, image);
      }
    }
  }

  Size getContentSize() => _bitmapManager.contentSize;

  void shift(bool forward) {
    _bitmapManager.shift(forward);
  }

  /// debug use
  PageIndex getPageIndex(bool forward) {
    return PageIndex.current;
  }

  @override
  void tearDown() {
    detach();
    _bitmapManager.clear();
  }

  /// 判断是否可以滚动到上一页/下一页
  Future<bool> canScroll(PageIndex pageIndex) async {
    return await nativeInterface.evaluateNativeFunc(
      NativeScript.canScroll,
      {'page_index': pageIndex.index},
    );
  }

  void onScrollingFinished(PageIndex pageIndex) {
    nativeInterface.evaluateNativeFunc(
      NativeScript.onScrollingFinished,
      {'page_index': pageIndex.index},
    );
  }

  int time = 0;

  Future<void> callNativeMethod(NativeScript script, int x, int y) async {
    Size imageSize = getContentSize();
    time = now();
    print('时间测试, call $script $time');
    switch (script) {
      case NativeScript.dragStart:
      case NativeScript.dragMove:
      case NativeScript.dragEnd:
      case NativeScript.longPressStart:
      case NativeScript.longPressMove:
      case NativeScript.longPressEnd:
      case NativeScript.tapUp:
      case NativeScript.selectionClear:
        Map<dynamic, dynamic> result = await nativeInterface.evaluateNativeFunc(
          script,
          {
            'touch_x': x,
            'touch_y': y,
            'width': imageSize.width,
            'height': imageSize.height,
            'time_stamp': time,
          },
        );
        print('时间测试, $script 获得结果, ${now()}');

        // 书页内容
        Uint8List? imageBytes = result['page'];
        if (imageBytes != null) {
          print('时间测试, $script handleImage');
          _handleImage(imageBytes);
        }

        // 高亮
        String? highlightsData = result['highlights_data'];
        if (highlightsData != null) {
          print('时间测试, $script _handleHighlight');
          _handleHighlight(highlightsData);
        }

        // 选择弹窗
        String? selectionMenuData = result['selection_menu_data'];
        if (selectionMenuData != null) {
          _handleSelectionMenu(selectionMenuData);
        } else {
          if (script == NativeScript.longPressEnd && highlightsData == null) {
            print('时间测试, 取消长按状态');
            _readerPageViewModelDelegate!.selectionDelegate.updateSelectionState(false);
          }
        }
        break;
      case NativeScript.selectedText:
        Map<dynamic, dynamic> result =
            await nativeInterface.evaluateNativeFunc(script);
        String text = result['text'];
        print('选中文字, $text');
        _readerPageViewModelDelegate!.selectionDelegate.showText(text);
        break;
      default:
    }
  }

  Future<void> _handleImage(Uint8List imgBytes) async {
    var image = await imgBytes.toImage();
    // _bitmapManager缓存img
    _bitmapManager.replaceBitmapCache(PageIndex.current, image);
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
    _readerPageViewModelDelegate!.selectionDelegate.updateHighlight(blocks, cursors.isNotEmpty ? cursors : null);
  }

  void _handleSelectionMenu(String selectionMenuData) {
    Map<String, dynamic> data = jsonDecode(selectionMenuData);
    SelectionMenuPosition position = SelectionMenuPosition.fromJson(data);
    Offset showPosition = position.toShowPosition(getContentSize());
    _readerPageViewModelDelegate!.selectionDelegate.showSelectionMenu(
      showPosition,
    );
  }

  bool isCacheEmpty() {
    return _bitmapManager.isEmpty();
  }

  void attach(ReaderPageViewModelDelegate pageManagerDelegate) {
    _readerPageViewModelDelegate = pageManagerDelegate;
  }

  void detach() {
    _readerPageViewModelDelegate = null;
  }
}
