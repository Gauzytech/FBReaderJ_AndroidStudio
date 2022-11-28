import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/modal/base_view_model.dart';
import 'package:flutter_lib/modal/page_index.dart';
import 'package:flutter_lib/modal/reader_book_info.dart';
import 'package:flutter_lib/modal/reader_config_model.dart';
import 'package:flutter_lib/modal/reader_progress_manager.dart';
import 'package:flutter_lib/reader/controller/bitmap_manager_impl.dart';
import 'package:flutter_lib/reader/controller/book_page_controller.dart';
import 'package:flutter_lib/reader/controller/page_physics/book_page_turn_physics.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';
import 'package:flutter_lib/reader/controller/page_repository.dart';
import 'package:flutter_lib/utils/common_util.dart';

/// 提供所有图书数据, 用于阅读界面menu联动
class ReaderViewModel extends BaseViewModel {
  ReaderBookInfo bookInfo;

  PageRepository? _readerContentHandler;


  late ReaderConfigModel _configModel;

  late ReaderProgressManager _progressManager;

  Size get contentSize => _readerContentHandler!.getContentSize();

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

  void setContentHandler(
    PageRepository handler,
  ) {
    _readerContentHandler = handler;
  }

  ui.Image? getOrBuildPage(PageIndex index) {
    final handler = ArgumentError.checkNotNull(
        _readerContentHandler, '_readerContentHandler');
    // 从缓存中获得page image
    ImageSrc page = handler.getPage(index);
    // 如果没有找到缓存的image, 回调native, 通知画一个新的
    if (page.img == null) {
      handler.buildPage(PageIndex.current);
    }
    return page.img;
  }

  /// ------------------------- 进度相关部分 -----------------------------------
  bool isCanGoNext() {
    return _progressManager.isCanGoNext();
  }

  // bool isHasNextChapter() {
  //   return _progressManager.isHasNextChapter();
  // }

  bool isCanGoPre() {
    return _progressManager.isCanGoPre();
  }

  // bool isHasPrePage() {
  //   return _progressManager.isHasPrePage();
  // }

  // bool isHasPreChapter() {
  //   return _progressManager.isHasPreChapter();
  // }

  void nextPage() {
    _progressManager.nextPage();
  }

  void prePage() {
    _progressManager.prePage();
  }

  void shiftPage(PageIndex pageIndex) {
    _progressManager.navigatePage(pageIndex);
  }

  /// --------------------------- 展示相关部分 ---------------------------------
  Future<ui.Image?> getPrevPageAsync() async {
    // 查看上一页image是否存在
    final handler = ArgumentError.checkNotNull(_readerContentHandler, '_readerContentHandler');
    ImageSrc prevPageImage = handler.getPage(PageIndex.prev);
    if(prevPageImage.img == null && !prevPageImage.processing) {
      if(!prevPageImage.processing) {
        print('flutter动画, ----------------未找到prev pageImage, 通知native进行绘制');
        return await handler.buildPageOnly(PageIndex.prev);
      } else {
        print('flutter动画, ----------------已经通知了native, 不用重新绘制');
      }
    }
    return prevPageImage.img;
  }

  ui.Image? getPrePage() {
    // var result;
    // if (_progressManager.isHasPrePage()) {
    //   var prePageInfo = _contentModel.dataValue
    //       .chapterCanvasDataMap[_contentModel.dataValue.currentPageIndex - 1];
    //   result = ReaderContentCanvasDataValue()
    //     ..pagePicture = prePageInfo?.pagePicture
    //     ..pageImage = prePageInfo?.pageImage;
    // } else if (_progressManager.isHasPreChapter()) {
    //   var prePageInfo = _contentModel.preDataValue.chapterCanvasDataMap[
    //   _contentModel.preDataValue.chapterContentConfigs.length - 1];
    //   result = ReaderContentCanvasDataValue()
    //     ..pagePicture = prePageInfo?.pagePicture
    //     ..pageImage = prePageInfo?.pageImage;
    // } else {
    //   result = null;
    // }
    //
    // return result;

    // 查看上一页image是否存在
    final handler = ArgumentError.checkNotNull(_readerContentHandler, '_readerContentHandler');
    ImageSrc prevPageImage = handler.getPage(PageIndex.prev);
    return prevPageImage.img;
  }

  void buildPageAsync(PageIndex index) {
    // 创建上一页/下一页image
    final handler = ArgumentError.checkNotNull(_readerContentHandler, '_readerContentHandler');
    ImageSrc? imageSrc = handler.getPage(index);
    if (imageSrc.img == null) {
      // 如果没有通知过native绘制
      if (!imageSrc.processing) {
        print('flutter动画, ----------------未找到next pageImage, 通知native进行绘制');
        handler.buildPageOnly(index);
      } else {
        print('flutter动画, ----------------已经通知了native, 不用重新绘制');
      }
    }
  }

  Future<ui.Image?> getNextPageAsync() async {
    // 查看下一页image是否存在
    final handler = ArgumentError.checkNotNull(_readerContentHandler, '_readerContentHandler');
    ImageSrc? nextPageImage = handler.getPage(PageIndex.next);
    if(nextPageImage.img == null) {
      if(!nextPageImage.processing) {
        print('flutter动画, ----------------未找到next pageImage, 通知native进行绘制');
        return await handler.buildPageOnly(PageIndex.next);
      } else {
        print('flutter动画, ----------------已经通知了native, 不用重新绘制');
      }
    }
    return nextPageImage.img;
  }

  ui.Image? getNextPage() {
    // 查看下一页image是否存在
    final handler = ArgumentError.checkNotNull(_readerContentHandler, '_readerContentHandler');
    ImageSrc? nextPageImage = handler.getPage(PageIndex.next);
    return nextPageImage.img;
  }

  ui.Image? getNextOrPrevPageDebug(bool forward) {
    // 查看下一页image是否存在
    final handler = ArgumentError.checkNotNull(_readerContentHandler, '_readerContentHandler');
    ImageSrc? nextPageImage = handler.getPage(handler.getPageIndex(forward));
    return nextPageImage.img;
  }

  ui.Image? getPage(PageIndex pageIndex) {
    final handler = ArgumentError.checkNotNull(_readerContentHandler, '_readerContentHandler');
    ImageSrc imageSrc = handler.getPage(pageIndex);
    return imageSrc.img;
  }

  bool pageExist(PageIndex pageIndex) {
    final handler = ArgumentError.checkNotNull(_readerContentHandler, '_readerContentHandler');
    ImageSrc imageSrc = handler.getPage(pageIndex);
    return imageSrc.img != null;
  }

  /// 菜单栏相关
  void setMenuOpenState(bool isOpen) {
    _configModel.isMenuOpen = isOpen;
//    notifyRefresh();
  }

  bool getMenuOpenState() {
    return _configModel.isMenuOpen;
  }

  @override
  Widget? getProviderContainer() {
    return null;
  }

  void registerContentOperateCallback(Null Function(dynamic operate) param0) {

  }

  void requestCatalog(String bookId) {

  }

  void notify() {
    notifyListeners();
  }

  /* ------------------------------------------ 翻页时, 需要进行的操作 --------------------------------------------------- */
  /// forward 'true' goNext, 'false' goPrev
  void shift(bool forward) {
    _readerContentHandler?.shift(forward);
  }

  /// 判断是否可以进入上一页/下一页
  Future<bool> canScroll(PageIndex pageIndex) async {
    final handler = requireNotNull(
        _readerContentHandler, '_readerContentHandler');
    return await handler.canScroll(pageIndex);
  }

  void onScrollingFinished(PageIndex pageIndex) {
    _readerContentHandler?.onScrollingFinished(pageIndex);
  }

  /// 预加载相邻页面
  void preloadAdjacentPage() {
    _readerContentHandler?.preloadAdjacentPages();
  }

  bool isPageDataEmpty() {
    return _readerContentHandler?.isCacheEmpty() ?? true;
  }

  @override
  void dispose() {
    _readerContentHandler?.tearDown();
    _configModel.tearDown();
    _progressManager.tearDown();
    super.dispose();
  }
}
