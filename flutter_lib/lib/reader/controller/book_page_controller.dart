
import 'package:flutter_lib/interface/book_page_scroll_context.dart';
import 'package:flutter_lib/reader/controller/page_physics/book_page_physics.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';

import 'page_physics/book_page_turn_physics.dart';

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

  BookPagePosition createBookPagePosition(BookPagePhysics bookPagePhysics, BookPageScrollContext context);

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
  BookPagePosition createBookPagePosition(BookPagePhysics bookPagePhysics, BookPageScrollContext context) {
    return BookPagePosition(context: context, physics: bookPagePhysics);
  }

  @override
  void attach(BookPagePosition position) {
    _bookPagePosition = position;
  }

  @override
  void detach(BookPagePosition oldPosition) {
    _bookPagePosition = null;
  }
}