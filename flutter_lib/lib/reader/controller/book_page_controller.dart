
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/reader/controller/page_physics/book_page_physics.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';
import 'package:flutter_lib/reader/reader_content_view.dart';

mixin BookPageController {

  /// Animates the controlled [PageView] from the current page to the given page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// The `duration` and `curve` arguments must not be null.
  Future<void> animateToPage(int page);

  /// Changes which page is displayed in the controlled [PageView].
  ///
  /// Jumps the page position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  void jumpToPage(int page);

  /// Animates the controlled [PageView] to the next page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// The `duration` and `curve` arguments must not be null.
  Future<void> nextPage();

  /// Animates the controlled [PageView] to the previous page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// The `duration` and `curve` arguments must not be null.
  Future<void> previousPage();

  /// todo 翻译
  /// 初始化[BookPagePosition]
  /// Creates a [BookPagePosition] for use by [ReaderContentView].
  ///
  /// Subclasses can override this function to customize the [ScrollPosition]
  /// used by the scrollable widgets they control. For example, [PageController]
  /// overrides this function to return a page-oriented scroll position
  /// subclass that keeps the same page visible when the scrollable widget
  /// resizes.
  ///
  /// By default, returns a [ScrollPositionWithSingleContext].
  ///
  /// The arguments are generally passed to the [ScrollPosition] being created:
  ///
  ///  * `physics`: An instance of [ScrollPhysics] that determines how the
  ///    [ScrollPosition] should react to user interactions, how it should
  ///    simulate scrolling when released or flung, etc. The value will not be
  ///    null. It typically comes from the [ScrollView] or other widget that
  ///    creates the [Scrollable], or, if none was provided, from the ambient
  ///    [ScrollConfiguration].
  ///  * `context`: A [ScrollContext] used for communicating with the object
  ///    that is to own the [ScrollPosition] (typically, this is the
  ///    [Scrollable] itself).
  ///  * `oldPosition`: If this is not the first time a [ScrollPosition] has
  ///    been created for this [Scrollable], this will be the previous instance.
  ///    This is used when the environment has changed and the [Scrollable]
  ///    needs to recreate the [ScrollPosition] object. It is null the first
  ///    time the [ScrollPosition] is created.
  BookPagePosition createBookPagePosition(
    BookPagePhysics bookPagePhysics,
    BookPageScrollContext context,
    BookPagePosition? oldPosition,
  );

  /// Register the given position with this controller.
  ///
  /// After this function returns, the [animateTo] and [jumpTo] methods on this
  /// controller will manipulate the given position.
  void attach(BookPagePosition position);

  void detach(BookPagePosition oldPosition);
}

class BookPageControllerImpl with BookPageController {

  BookPagePosition? _bookPagePosition;
  BookPagePosition get pagePosition {
    assert(_bookPagePosition != null, 'BookPageController not attached yet');
    return _bookPagePosition!;
  }

  BookPageControllerImpl();

  @override
  Future<void> animateToPage(int page) {
    return Future<void>.value();
  }

  @override
  void jumpToPage(int page) {
  }

  @override
  Future<void> nextPage() {
    return Future<void>.value();
  }

  @override
  Future<void> previousPage() {
    return Future<void>.value();
  }

  @override
  BookPagePosition createBookPagePosition(
    BookPagePhysics bookPagePhysics,
    BookPageScrollContext context,
    BookPagePosition? oldPosition,
  ) =>
      BookPagePosition(
        context: context,
        physics: bookPagePhysics,
        oldPosition: oldPosition,
      );

  @override
  void attach(BookPagePosition position) {
    _bookPagePosition = position;
  }

  @override
  void detach(BookPagePosition oldPosition) {
    _bookPagePosition = null;
  }
}