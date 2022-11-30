import 'dart:math' as math;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter_lib/reader/controller/page_scroll/reader_scroll_position_with_single_context.dart';

class BookPagePosition extends ReaderScrollPositionWithSingleContext {
  /// 每页page所占比例
  ///
  /// Used to compute [page] from the current [pixels].
  double get viewportFraction => _viewportFraction;
  double _viewportFraction = -1;

  set viewportFraction(double value) {
    if (_viewportFraction == value) {
      return;
    }
    _viewportFraction = value;
  }

  BookPagePosition({
    required super.context,
    required super.physics,
    double viewportFraction = 1.0,
  })  : assert(viewportFraction > 0.0),
        _viewportFraction = viewportFraction,
        super(initialPixels: null);

  double get _initialPageOffset =>
      math.max(0, viewportDimension * (viewportFraction - 1) / 2);

  double getPageFromPixels(double pixels, double viewportDimension) {
    assert(viewportDimension > 0.0);
    final double actual = math.max(0.0, pixels - _initialPageOffset) /
        (viewportDimension * viewportFraction);
    final double round = actual.roundToDouble();
    if ((actual - round).abs() < precisionErrorTolerance) {
      return round;
    }
    return actual;
  }

  double getPixelsFromPage(double page) {
    return page * viewportDimension * viewportFraction + _initialPageOffset;
  }

  double? get page {
    assert(
      !hasPixels || hasViewportDimension,
      'Page value is only available after content dimensions are established.',
    );
    return getPageFromPixels(pixels, viewportDimension);
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double? oldViewportDimensions =
        hasViewportDimension ? this.viewportDimension : null;
    if (viewportDimension == oldViewportDimensions) {
      return true;
    }

    // todo 根据自己的书页渲染逻辑改造, 两种情况: 垂直滚动/横向翻页
    // 设置一页内容的宽度
    super.applyViewportDimension(viewportDimension);
    // todo 初始化书页渲染的坐标, 暂时写个0
    correctPixels(0);
    return false;
  }
}
