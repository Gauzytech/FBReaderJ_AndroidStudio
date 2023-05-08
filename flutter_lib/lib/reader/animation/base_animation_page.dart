import 'package:flutter/material.dart';
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/reader/animation/model/page_paint_metadata.dart';

import '../../model/view_model_reader.dart';
import '../controller/touch_event.dart';

enum ANIMATION_TYPE { TYPE_CONFIRM, TYPE_CANCEL, TYPE_FILING }

abstract class BaseAnimationPage {
  Offset _mTouch = const Offset(0, 0);

  AnimationController animationController;

  Size get currentSize => _currentSize!;
  Size? _currentSize;

//  @protected
//  ReaderContentViewModel contentModel=ReaderContentViewModel.instance;

  ReaderViewModel readerViewModel;

  BookPageScrollContext get scrollContext => _scrollContext;
  final BookPageScrollContext _scrollContext;

  PagePaintMetaData get metaData => _metaData;
  final PagePaintMetaData _metaData;

//  void setData(ReaderChapterPageContentConfig prePageConfig,ReaderChapterPageContentConfig currentPageConfig,ReaderChapterPageContentConfig nextPageConfig){
//    currentPageContentConfig=pageConfig;
//  }

  BaseAnimationPage({
    required this.readerViewModel,
    required this.animationController,
    required BookPageScrollContext scrollContext,
  })  : _scrollContext = scrollContext,
        _metaData = PagePaintMetaData();

  void setSize(Size size) {
    _currentSize = size;
    // mTouch = Offset(currentSize.width, currentSize.height);
  }

//   void setContentViewModel(ReaderViewModel viewModel) {
//     readerViewModel = viewModel;
// //    mTouch=Offset(currentSize.width, currentSize.height);
//   }

  void onDraw(Canvas canvas);

  void onTouchEvent(TouchEvent event);

  void onPagePreDraw(PagePaintMetaData metaData) {
    _metaData.apply(metaData);
  }

  void onPageDraw(Canvas canvas) {}

  // void setAnimationController(AnimationController controller) {
  //   animationController = controller;
  // }

  bool shouldCancelAnimation() {
    return false;
  }

  bool isCanGoNext() {
    return readerViewModel.isCanGoNext();
  }

  bool isCanGoPre() {
    return readerViewModel.isCanGoPre();
  }

  bool isCancelArea();

  bool isConfirmArea();

  Animation<Offset>? getCancelAnimation(
      AnimationController controller, GlobalKey canvasKey);

  Animation<Offset>? getConfirmAnimation(
      AnimationController controller, GlobalKey canvasKey);

  Simulation? getFlingAnimationSimulation(
      AnimationController controller, DragEndDetails details);

  bool isForward(TouchEvent event);

  void cacheCurrentTouchData(Offset touchData) {
    print('flutter动画流程:cacheCurrentTouchData, $touchData');
    _mTouch = Offset(touchData.dx, touchData.dy);
  }

  Offset getCachedTouchData() {
    return _mTouch;
  }
}
