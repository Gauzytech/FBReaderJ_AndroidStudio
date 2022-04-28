import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import '../managers/BitmapManagerImpl.dart';

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
  State<ReaderWidget> createState() => _ReaderWidgetState();

  // ui.Image drawOnBitmap() {
  //   ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  //   Canvas canvas = Canvas(pictureRecorder);
  //
  //   canvas.drawImage(image, offset, paint);
  //
  //
  // }
}

class _ReaderWidgetState extends State<ReaderWidget> {
  // 缓存图书内容图片的manager
  late BitmapManagerImpl myBitmapManager;

  static const methodChannel = MethodChannel('com.flutter.guide.MethodChannel');
  String _batteryLevel = 'Battery level: ';
  String _calledFromNative = '';

  // Flutter调用Native方法
  // 方法通道的方法是异步的
  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final result = await methodChannel
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
      case 'flutterMethod':
        setState(() {
          _calledFromNative = methodCall.arguments;
        });
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
    methodChannel.setMethodCallHandler(_addNativeMethod);
  }

  @override
  void initState() {
    _addMethodFromNative();
    myBitmapManager = BitmapManagerImpl(readerWidget: widget);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              color: Colors.red.shade200,
              child: Text(
                '顶部: 显示图书标题, $_calledFromNative',
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                color: Colors.blue.shade300,
                child: Text(
                  '中间: 显示图书内容',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.green.shade200,
              child: Text(
                '底部: 显示图书电量和页码',
              ),
            ),
          ],
        ),
      ),
    );
  }

}
