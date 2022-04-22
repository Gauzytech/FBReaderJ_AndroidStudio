import 'package:flutter/material.dart';

class ReaderWidget extends StatefulWidget {
  // 放大镜的半径
  static const double radius = 124;
  static const double targetDiameter = 2 * radius * 333 / 293;
  static const double magnifierMargin = 144;
  // 放大倍数
  static const double factor = 1;
  // 预加载线程: 暂时不实现
  // public final ExecutorService prepareService = Executors.newSingleThreadExecutor();
  // 画笔
  Paint myPaint = Paint();
  // 缓存图书内容图片的manager
  // BitmapManagerImpl myBitmapManager = new BitmapManagerImpl(this);
  // 系统信息
  // SystemInfo mySystemInfo;
  // 页脚的bitmap
  // private Bitmap myFooterBitmap;


  ReaderWidget({Key? key}) : super(key: key);

  @override
  State<ReaderWidget> createState() => _ReaderWidgetState();
}

class _ReaderWidgetState extends State<ReaderWidget> {

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              color: Colors.red.shade200,
              child: const Text(
                '顶部: 显示图书标题',
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
