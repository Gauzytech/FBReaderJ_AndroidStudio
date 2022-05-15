import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_lib/modal/base_view_model.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/modal/reader_book_info.dart';
import 'package:flutter_lib/modal/reader_config_model.dart';
import 'package:flutter_lib/modal/reader_progress_manager.dart';
import 'package:flutter_lib/reader/controller/reader_content_handler.dart';

class ReaderViewModel extends BaseViewModel {
  ReaderBookInfo bookInfo;

  ReaderContentHandler? _readerContentHandler;
  late ReaderConfigModel _configModel;

  late ReaderProgressManager _progressManager;

  ReaderViewModel({required this.bookInfo}) {
    _configModel = ReaderConfigModel(viewModel: this);
    _progressManager = ReaderProgressManager(viewModel: this);
  }

  ReaderConfigEntity getConfigData() {
    return _configModel.configEntity;
  }

  void setConfigData(ReaderConfigEntity configData) {
    _configModel.configEntity = configData.copy();

    // if (_configModel.configEntity.currentCanvasBgColor != null) {
    //   bgPaint = Paint()
    //     ..isAntiAlias = true
    //     ..style = PaintingStyle.fill //填充
    //     ..color = _configModel.configEntity.currentCanvasBgColor; //背景为纸黄色
    //
    //   textPainter = TextPainter(textDirection: TextDirection.ltr);
    // }
  }

  void setContentHandler(ReaderContentHandler handler) {
    _readerContentHandler = handler;
  }

  PageIndex getIdx() {
    return ArgumentError.checkNotNull(
            _readerContentHandler, '_readerContentHandler')
        .currentPageIndex;
  }

  List<double> getContentSize() {
    final size = ArgumentError.checkNotNull(
            _readerContentHandler, '_readerContentHandler')
        .getContentSize();
    print('flutter内容绘制流程, size = $size');
    return size;
  }

  ui.Image? getCurrentPage() {
    print('flutter内容绘制流程, getCurrentPage');
    final handler = ArgumentError.checkNotNull(
        _readerContentHandler, '_readerContentHandler');
    // 从缓存中获得page image
    ui.Image? page = handler.getPage(handler.currentPageIndex);
    // 如果没有找到缓存的image, 回调native, 通知画一个新的
    if (page == null) {
      handler.buildPage(PageIndex.current);
    }
    return page;
  }

  void nextPage() {}

  void prePage() {}

  bool isCanGoNext() {
    return false;
  }

  bool isCanGoPre() {
    return false;
  }

  void registerContentOperateCallback(Null Function(dynamic operate) param0) {}

  getPrePage() {}

  getNextPage() {}

  @override
  Widget? getProviderContainer() {
    return null;
  }

  @override
  void dispose() {
    super.dispose();
    _readerContentHandler?.clear();
    _configModel.clear();
    _progressManager.clear();
  }

  void requestCatalog(String bookId) {}

  void notify() {
    notifyListeners();
  }
}
