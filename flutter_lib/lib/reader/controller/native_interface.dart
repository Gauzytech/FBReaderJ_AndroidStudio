import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_lib/reader/controller/page_repository.dart';
import 'package:flutter_lib/utils/common_util.dart';

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
  canScroll('can_scroll'),
  onScrollingFinished('on_scrolling_finished');

  final String name;

  const NativeScript(this.name);
}

/// 与native代码通讯的管理类, 比如: Android/iOS
class NativeInterface {

  final MethodChannel? _methodChannel;

  MethodChannel get channel => _methodChannel!;

  PageRepositoryDelegate delegate;

  NativeInterface({required MethodChannel methodChannel, required this.delegate})
      : _methodChannel = methodChannel {
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

  Future<dynamic> evaluateNativeFunc(NativeScript script,
      [Map<String, Object?>? params]) async {
    final metrics = ui.window.physicalSize;
    switch (script) {
      case NativeScript.drawOnBitmap:
        return channel.invokeMethod(
          script.name,
          {
            'page_index': requireNotNull(params!['page_index']),
            'width': metrics.width,
            'height': metrics.height,
          },
        );
      case NativeScript.preparePage:
        return channel.invokeMethod(
          script.name,
          {
            'width': metrics.width,
            'height': metrics.height,
            'update_prev_page_cache':
                requireNotNull(params!['update_prev_page_cache']),
            'update_next_page_cache':
                requireNotNull(params['update_next_page_cache']),
          },
        );
      case NativeScript.canScroll:
        return channel.invokeMethod(
          script.name,
          {
            'page_index': requireNotNull(params!['page_index']),
          },
        );
      case NativeScript.onScrollingFinished:
        channel.invokeMethod(
          script.name,
          {'page_index': requireNotNull(params!['page_index'])},
        );
        return null;
      case NativeScript.dragStart:
      case NativeScript.dragMove:
      case NativeScript.dragEnd:
      case NativeScript.longPressStart:
      case NativeScript.longPressMove:
      case NativeScript.longPressEnd:
      case NativeScript.tapUp:
      case NativeScript.selectionClear:
      case NativeScript.selectedText:
        return channel.invokeMethod(script.name, params);
      default:
        throw UnsupportedError('Unhandled script: $script');
    }
  }
}
