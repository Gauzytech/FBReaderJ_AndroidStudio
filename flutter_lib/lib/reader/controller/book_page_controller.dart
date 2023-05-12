import 'package:flutter/rendering.dart';
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/model/page_index.dart';
import 'package:flutter_lib/reader/animation/base_animation_page.dart';
import 'package:flutter_lib/reader/controller/page_physics/book_page_physics.dart';
import 'package:flutter_lib/reader/controller/page_repository.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';
import 'package:flutter_lib/reader/model/page_paint_metadata.dart';
import 'package:flutter_lib/reader/reader_content_view.dart';
import 'package:flutter_lib/utils/screen_util.dart';

mixin BookPageController {

  /// 将受控的 [ReaderContentView]根据 [BookPagePosition]从当前页面滚动到上一页或者下一页 - 有滚动动画.
  Future<void> animateToPage(
    BaseAnimationPage animationPage,
    VoidCallback onPageCentered,
  );

  /// 将受控的 [ReaderContentView]根据 [page]从当前页面滚动到上一页或者下一页 - 没有滚动动画.
  void jumpToPage(int page);

  /// 将受控的 [ReaderContentView]从当前页面滚动到下一页 - 没有滚动动画.
  Future<void> nextPage(
    BaseAnimationPage animationPage,
    VoidCallback onPageCentered,
  );

  /// 将受控的 [ReaderContentView]从当前页面滚动到上一页 - 没有滚动动画.
  Future<void> previousPage(
    BaseAnimationPage animationPage,
    VoidCallback onPageCentered,
  );

  /// todo 翻译
  /// 创建供 [ReaderContentView] 使用的 [BookPagePosition]
  ///
  ///  * `physics`:  [ScrollPhysics] 的一个实例, 它决定了[ScrollPosition]如何对用户交互做出反应.
  ///    如何在用户手指松开或甩出的时，进行模拟滚动.
  ///  * `context`: A [ScrollContext] used for communicating with the object
  ///    that is to own the [ScrollPosition] (typically, this is the
  ///    [Scrollable] itself).
  ///  * `oldPosition`: If this is not the first time a [ScrollPosition] has
  ///    been created for this [Scrollable], this will be the previous instance.
  ///    This is used when the environment has changed and the [Scrollable]
  ///    needs to recreate the [ScrollPosition] object. It is null the first
  ///    time the [ScrollPosition] is created.
  BookPagePosition createBookPagePosition(
    BookPagePhysics physics,
    BookPageScrollContext context,
    BookPagePosition? oldPosition,
  );

  /// 使用此控制器注册[position]。
  ///
  /// 此函数返回后，此函数上的 [animateTo] 和 [jumpTo] 方法
  /// 控制器将操纵[position]。
  void attach(BookPagePosition position, PageRepository pageRepository);

  void detach();

  /// 判断是否可以滚动到上一页/下一页
  Future<bool> canScrollPage({ScrollDirection? direction});
}

class BookPageControllerImpl with BookPageController {

  BookPagePosition? _bookPagePosition;

  BookPagePosition get pagePosition {
    assert(_bookPagePosition != null, 'BookPageController not attached yet');
    return _bookPagePosition!;
  }

  PageRepository? _pageRepository;

  BookPageControllerImpl();

  @override
  Future<void> animateToPage(
    BaseAnimationPage animationPage,
    VoidCallback onPageCentered,
  ) async {
    if (await canScrollPage()) {
      animationPage.onPagePreDraw(PagePaintMetaData(
        pixels: pagePosition.pixels,
        page: pagePosition.page!,
        onPageCentered: onPageCentered,
      ));
    } else {
      print('flutter翻页行为[_onPagePaintMetaUpdate], 重置坐标');
      onPageCentered();
    }
  }

  @override
  void jumpToPage(int page) {}

  @override
  Future<void> nextPage(
    BaseAnimationPage animationPage,
    VoidCallback onPageCentered,
  ) async {
    if (await canScrollPage(direction: ScrollDirection.reverse)) {
      animationPage.onPagePreDraw(PagePaintMetaData(
        pixels: ScreenUtil().screenWidth,
        page: 1,
        onPageCentered: onPageCentered,
      ));
    }
  }

  @override
  Future<void> previousPage(
    BaseAnimationPage animationPage,
    VoidCallback onPageCentered,
  ) async {
    if (await canScrollPage(direction: ScrollDirection.reverse)) {
      animationPage.onPagePreDraw(PagePaintMetaData(
        pixels: ScreenUtil().screenWidth,
        page: -1,
        onPageCentered: onPageCentered,
      ));
    }
  }

  @override
  BookPagePosition createBookPagePosition(
    BookPagePhysics physics,
    BookPageScrollContext context,
    BookPagePosition? oldPosition,
  ) =>
      BookPagePosition(
        context: context,
        physics: physics,
        oldPosition: oldPosition,
      );

  @override
  void attach(BookPagePosition position, PageRepository pageRepository) {
    print('flutter生命周期, attach');
    _bookPagePosition = position;
    _pageRepository = pageRepository;
  }

  @override
  void detach() {
    print('flutter生命周期, detach');
    _bookPagePosition = null;
    _pageRepository = null;
  }

  @override
  Future<bool> canScrollPage({ScrollDirection? direction}) async {
    if (pagePosition.scrollStartPixels != 0) return true;
    var scrollDirection = direction ?? pagePosition.userScrollDirection;
    assert(_pageRepository != null, "BookPageController not attached yet");

    switch (scrollDirection) {
      case ScrollDirection.idle:
        return false;
      case ScrollDirection.forward:
        return _pageRepository!.canScroll(PageIndex.prev);
      case ScrollDirection.reverse:
        return _pageRepository!.canScroll(PageIndex.next);
    }
  }
}