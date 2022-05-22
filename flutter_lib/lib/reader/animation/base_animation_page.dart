import 'package:flutter/material.dart';
import 'package:flutter_lib/modal/page_index.dart';
import '../../modal/view_model_reader.dart';
import '../../utils/screen_util.dart';
import '../controller/touch_event.dart';

enum ANIMATION_TYPE { TYPE_CONFIRM, TYPE_CANCEL, TYPE_FILING }

abstract class BaseAnimationPage {
  Offset mTouch = const Offset(0, 0);

  AnimationController animationController;

  Size currentSize =
      Size(ScreenUtil.getScreenWidth(), ScreenUtil.getScreenHeight());

//  @protected
//  ReaderContentViewModel contentModel=ReaderContentViewModel.instance;

  ReaderViewModel readerViewModel;

//  void setData(ReaderChapterPageContentConfig prePageConfig,ReaderChapterPageContentConfig currentPageConfig,ReaderChapterPageContentConfig nextPageConfig){
//    currentPageContentConfig=pageConfig;
//  }

  BaseAnimationPage({required this.readerViewModel, required this.animationController});

  void setSize(Size size) {
    currentSize = size;
//    mTouch=Offset(currentSize.width, currentSize.height);
  }

//   void setContentViewModel(ReaderViewModel viewModel) {
//     readerViewModel = viewModel;
// //    mTouch=Offset(currentSize.width, currentSize.height);
//   }

  void onDraw(Canvas canvas);

  void onTouchEvent(TouchEvent event);

  // void setAnimationController(AnimationController controller) {
  //   animationController = controller;
  // }

  bool isShouldAnimatingInterrupt() {
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
}
