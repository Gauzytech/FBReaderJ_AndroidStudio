import 'package:flutter/services.dart';
import 'package:flutter_lib/reader/controller/page_content_provider.dart';
import 'package:flutter_lib/utils/common_util.dart';
import 'dart:ui' as ui;

import '../../modal/page_index.dart';

enum NativeScript {
  dragStart('on_selection_drag_start'),
  dragMove('on_selection_drag_move'),
  dragEnd('on_selection_drag_end'),
  longPressStart('long_press_start'),
  longPressMove('long_press_move'),
  longPressEnd('long_press_end'),
  tapUp('on_tap_up'),
  selectionClear('selection_clear'),
  selectedText('selected_text'),
  drawOnBitmap('draw_on_bitmap'),
  preparePage('prepare_page'),
  canScroll('can_scroll');

  final String name;

  const NativeScript(this.name);
}

/// 与native代码通讯的管理类, 比如: Android/iOS
class NativeInterface {

  final MethodChannel? _methodChannel;
  MethodChannel get channel => _methodChannel!;

  PageContentProviderDelegate delegate;

  NativeInterface({MethodChannel? methodChannel, required this.delegate})
      : assert(methodChannel != null),
        _methodChannel = methodChannel {
    channel.setMethodCallHandler(_addNativeMethod);
  }

  /* ---------------------------------------- Native调用Flutter方法 ----------------------------------------*/
  Future<dynamic> _addNativeMethod(MethodCall methodCall) async {
    print('flutter内容绘制流程, 收到native通讯, ${methodCall.method}');
    switch (methodCall.method) {
      case 'init_load':
        // 本地数据全部解析完毕后，会执行init_load方法开始通知渲染图书页面
        delegate.initialize(PageIndex.current);
        break;
      case 'tear_down':
        delegate.tearDown();
        delegate.refreshContent();
        break;
    }
  }

  Future<dynamic> evaluateNativeFunc(NativeScript script, Map<String, Object?> params) async {
    final metrics = ui.window.physicalSize;
    switch(script) {
      case NativeScript.drawOnBitmap:
        return channel.invokeMethod(
          script.name,
          {
            'page_index': requireNotNull(params['page_index'], 'page_index is null'),
            'width': metrics.width,
            'height': metrics.height,
          },
        );
      default:
        throw UnsupportedError('Unhandled script: $script');
    }
  }
}
