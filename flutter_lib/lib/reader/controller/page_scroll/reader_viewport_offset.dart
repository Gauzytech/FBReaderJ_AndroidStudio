import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// see [ViewportOffset]
abstract class ReaderViewportOffset extends ChangeNotifier {

  ReaderViewportOffset();

  /// todo 写注释
  /// 图书每一页内容渲染的偏移值，从左上角开始计算, 比如: 左上角[0, 0]
  /// The number of pixels to offset the children in the opposite of the axis direction.
  ///
  /// For example, if the axis direction is down, then the pixel value
  /// represents the number of logical pixels to move the children _up_ the
  /// screen. Similarly, if the axis direction is left, then the pixels value
  /// represents the number of logical pixels to move the children to _right_.
  ///
  /// This object notifies its listeners when this value changes (except when
  /// the value changes due to [correctBy]).
  double get pixels;

  /// [pixels] 是否存在.
  bool get hasPixels;

  /// 图书每一页内容的显示范围in pixel
  /// 横向翻页: 屏幕宽度
  /// 竖直滚动翻页: 屏幕高度
  double get viewportDimension;

  /// [viewportDimension] 是否存在.
  bool get hasViewportDimension;

  /// todo 写注释
  /// Called when the viewport's extents are established.
  ///
  /// The argument is the dimension of the [RenderViewport] in the main axis
  /// (e.g. the height, for a vertical viewport).
  ///
  /// This may be called redundantly, with the same value, each frame. This is
  /// called during layout for the [RenderViewport]. If the viewport is
  /// configured to shrink-wrap its contents, it may be called several times,
  /// since the layout is repeated each time the scroll offset is corrected.
  ///
  /// If this is called, it is called before [applyContentDimensions]. If this
  /// is called, [applyContentDimensions] will be called soon afterwards in the
  /// same layout phase. If the viewport is not configured to shrink-wrap its
  /// contents, then this will only be called when the viewport recomputes its
  /// size (i.e. when its parent lays out), and not during normal scrolling.
  ///
  /// If applying the viewport dimensions changes the scroll offset, return
  /// false. Otherwise, return true. If you return false, the [RenderViewport]
  /// will be laid out again with the new scroll offset. This is expensive. (The
  /// return value is answering the question "did you accept these viewport
  /// dimensions unconditionally?"; if the new dimensions change the
  /// [ViewportOffset]'s actual [pixels] value, then the viewport will need to
  /// be laid out again.)
  bool applyViewportDimension(double viewportDimension);

  /// 用户当前滚动的方向, [pixels], 与viewport's [RenderViewportBase.axisDirection]有关.
  ///
  /// 代表当前用户触摸操作的滚动方向, 有三种情况:
  /// 1. [ScrollDirection.idle], 表示没有scroll
  /// 2. [ScrollDirection.forward], 移动距离(primaryDelta) = 正数
  ///  a. 垂直滚动(从上往下): 书页内容显示上边部分，上一页
  ///  b. 翻页滚动(从左往右): 书页内容显示左边部分，上一页
  /// 3. [ScrollDirection.reverse], 移动距离(primaryDelta) = 负数
  ///  a. 垂直滚动(从下往上划): 书页内容显示下边部分，下一页
  ///  b. 翻页滚动(从右往左划): 书页内容显示右边部分，下一页
  ScrollDirection get userScrollDirection;

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '${describeIdentity(this)} (${description.join(", ")})';
  }

  @mustCallSuper
  void debugFillDescription(List<String> description) {
    if (hasPixels) {
      description.add('offset: ${pixels.toStringAsFixed(1)}');
    }
  }
}
