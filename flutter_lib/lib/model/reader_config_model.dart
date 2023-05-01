import 'dart:ui';

import 'package:flutter_lib/model/view_model_reader.dart';
import 'package:flutter_lib/reader/animation/model/user_settings/page_mode.dart';
import 'package:flutter_lib/reader/controller/page_physics/page_flip_physics.dart';
import 'package:flutter_lib/reader/controller/reader_page_view_model.dart';

class ReaderConfigModel {
  ReaderViewModel? viewModel;

  // BookChapter catalog;
  bool isMenuOpen = false;

  late ReaderConfigEntity configEntity;

  ReaderConfigModel({required this.viewModel});

  void tearDown() {
    viewModel = null;
    // catalog = null;
    // configEntity = null;
    isMenuOpen = false;
  }
}

class ReaderConfigEntity {
  /// 翻页动画类型
  int currentAnimationMode;

  /// 背景色
  Color currentCanvasBgColor;

  int currentPageIndex;
  int currentChapterIndex;
  String id;

  int fontSize;
  int lineHeight;
  int paragraphSpacing;

  Offset pageSize;

  int contentPadding = 10;
  int titleHeight = 25;
  int bottomTipHeight = 20;

  int titleFontSize = 20;
  int bottomTipFontSize = 20;

  ReaderConfigEntity({
    this.currentAnimationMode = ReaderPageViewModel.TYPE_ANIMATION_COVER_TURN,
    this.currentCanvasBgColor = const Color(0xfffff2cc),
    this.currentPageIndex = 0,
    this.currentChapterIndex = 0,
    required this.id,
    this.fontSize = 20,
    this.lineHeight = 30,
    this.paragraphSpacing = 10,
    this.pageSize = Offset.zero,
  });

  PageMode getPageMode() {
    switch (currentAnimationMode) {
      case ReaderPageViewModel.TYPE_ANIMATION_PAGE_TURN:
        return PageMode.horizontalPageTurn;
      default:
        return PageMode.verticalPageScroll;
    }
  }

  ReaderConfigEntity copy() {
    return ReaderConfigEntity(
      currentAnimationMode: currentAnimationMode,
      currentCanvasBgColor: currentCanvasBgColor,
      currentPageIndex: currentPageIndex,
      currentChapterIndex: currentChapterIndex,
      id: id,
      fontSize: fontSize,
      lineHeight: lineHeight,
      paragraphSpacing: paragraphSpacing,
      pageSize: pageSize,
    );
  }
}
