import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lib/widget/content_painter.dart';

import '../managers/BitmapManagerImpl.dart';
import '../modal/PageIndex.dart';

class ReaderWidget extends StatefulWidget {
  // 放大镜的半径
  static const double radius = 124;
  static const double targetDiameter = 2 * radius * 333 / 293;
  static const double magnifierMargin = 144;

  // 放大倍数
  static const double factor = 1;

  // 画笔
  Paint myPaint = Paint();

  // 页脚的bitmap
  // private Bitmap myFooterBitmap;

  ReaderWidget({Key? key}) : super(key: key);

  @override
  State<ReaderWidget> createState() => ReaderWidgetState();

// ui.Image drawOnBitmap() {
//   ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//   Canvas canvas = Canvas(pictureRecorder);
//
//   canvas.drawImage(image, offset, paint);
//
//
// }
}

class ReaderWidgetState extends State<ReaderWidget> {
  // 图书主内容区域
  final GlobalKey _contentKey = GlobalKey();

  ContentPainter? _contentPainter;
  ui.Image? _contentImage;
  Uint8List? bytes;

  final GlobalKey _footerKey = GlobalKey();

  // 缓存图书内容图片的manager
  late BitmapManagerImpl bitmapManager;

  final _methodChannel = const MethodChannel('com.flutter.book.reader');
  String _batteryLevel = 'Battery level: ';
  String _calledFromNative = '';

  // Flutter调用Native方法
  // 方法通道的方法是异步的
  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final result = await _methodChannel
          .invokeMethod('getBatteryLevel', {'name': 'laomeng', 'age': 18});
      batteryLevel = 'Battery level ${result['battery']}';
    } on PlatformException catch (e) {
      batteryLevel = 'Battery level unknown ${e.message}';
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  // Native调用Flutter方法
  Future<dynamic> _addNativeMethod(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'render_page':
        print("flutter内容绘制流程, render_page start");

        // 渲染第一页
        final image = bitmapManager.getBitmap(PageIndex.current);
        if (image != null) {
          // 如果本地已经缓存了image, 直接更新state进行渲染
          setState(() {
            print("flutter内容绘制流程, image != null, update state");
            _contentImage = image;
          });
        } else {
          // 如果没有找到缓存的Image, 回调native, 通知画一个新的
          int? internalIdx = bitmapManager.findInternalCacheIndex(PageIndex.current);
          if(internalIdx != null) {
              drawOnBitmap(internalIdx, PageIndex.current);
          }
        }

        break;
      case 'timer':
        setState(() {
          var _nativeData = methodCall.arguments['count'];
          _calledFromNative = 'count = $_nativeData';
        });
        break;
    }
  }

  void _addMethodFromNative() {
    _methodChannel.setMethodCallHandler(_addNativeMethod);
  }

  Future<void> drawOnBitmap(int internalCacheIndex, PageIndex pageIndex) async {
    try {
      final mediaQuery = MediaQuery.of(context);
      final ratio = mediaQuery.devicePixelRatio;
      print("flutter内容绘制流程, render_page, "
          "ratio = ${mediaQuery.devicePixelRatio}, "
          "windowSize = ${window.physicalSize},"
          "footerHeight = ${_footerKey.currentContext?.size?.height},");

      // 屏幕宽度
      double widthPx = window.physicalSize.width;
      // 屏幕高度 - footer高度
      double heightPx = window.physicalSize.height -
          _footerKey.currentContext!.size!.height * ratio;

      Uint8List imageBytes = await _methodChannel.invokeMethod(
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

      print(
          "flutter内容绘制流程, 收到了图片[${image.width}, ${image.height}], byte = ${imageBytes.length}");
      // 原生那边绘制完了, 就缓存
      bitmapManager.cacheBitmap(pageIndex, internalCacheIndex, image);

      // 准备
      _prepareAdjacentPage(widthPx, heightPx);

      setState(() => _contentImage = image);
    } on PlatformException catch (e) {
      print("flutter内容绘制流程, $e");
    }
  }

  Future<void> _prepareAdjacentPage(double widthPx, double heightPx) async {
    ui.Image? prevImage = bitmapManager.getBitmap(PageIndex.prev);
    ui.Image? nextImage = bitmapManager.getBitmap(PageIndex.next);

    int? prevIdx;
    int? nextIdx;
    if(prevImage == null) {
      prevIdx = bitmapManager.findInternalCacheIndex(PageIndex.prev);
    }

    if(nextImage == null) {
      nextIdx = bitmapManager.findInternalCacheIndex(PageIndex.next);
    }

    print("flutter内容绘制流程, 准备相邻页面${prevImage == null}, ${nextImage == null}");
    Map<Object?, Object?> result = await _methodChannel.invokeMethod("prepare_page", {
      'width': widthPx,
      'height': heightPx,
      'update_prev_page_cache': prevIdx != null,
      'update_next_page_cache': nextIdx != null,
    });

    final prev = result['prev'];
    if(prevIdx != null && prev != null) {
      prev as Uint8List;
      print("flutter内容绘制流程, 收到prevPage ${prev.length}, 插入$prevIdx");
      ui.Codec codec = await ui.instantiateImageCodec(prev);
      ui.FrameInfo fi = await codec.getNextFrame();
      final image = fi.image;
      bitmapManager.cacheBitmap(PageIndex.prev, prevIdx, image);
    }

    final next = result['prev'];
    if(nextIdx != null && next != null) {
      next as Uint8List;
      print("flutter内容绘制流程, 收到nextPage ${next.length}, 插入$nextIdx");
      ui.Codec codec = await ui.instantiateImageCodec(next);
      ui.FrameInfo fi = await codec.getNextFrame();
      final image = fi.image;
      bitmapManager.cacheBitmap(PageIndex.next, nextIdx, image);
    }

    print("flutter内容绘制流程, 准备完成, 可用cache: ${bitmapManager.debugSlotOccupied()}");
  }

  @override
  void initState() {
    _addMethodFromNative();
    bitmapManager = BitmapManagerImpl(readerWidgetState: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _contentPainter = ContentPainter(_contentImage);

    return Material(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: FittedBox(
                child: SizedBox(
                  key: _contentKey,
                  width: _contentImage == null
                      ? 0
                      : _contentImage!.width.toDouble(),
                  height: _contentImage == null
                      ? 0
                      : _contentImage!.height.toDouble(),
                  child: CustomPaint(
                    painter: _contentPainter,
                  ),
                ),
              ),
            ),
            Container(
              key: _footerKey,
              width: double.infinity,
              color: Colors.green.shade200,
              child: const Text('底部: 显示图书电量和页码'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    bitmapManager.clear();
    super.dispose();
  }
}
