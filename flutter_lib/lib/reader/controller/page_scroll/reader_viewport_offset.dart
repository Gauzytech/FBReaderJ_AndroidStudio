import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// see [ViewportOffset]
abstract class ReaderViewportOffset extends ChangeNotifier {

  ReaderViewportOffset();

  /// [pixels]滚动范围的最小值.
  ///
  /// 实际[pixels]值可能会超出范围.
  ///
  /// 该值必须非空以及小于[maxScrollExtent], 它可以是负无穷，如果用户视窗滚动范围没有边界.
  double get minScrollExtent;

  /// [pixels]滚动范围的最小值.
  ///
  /// 实际[pixels]值可能会超出范围.
  ///
  /// 该值必须非空以及大于[minScrollExtent], 它可以是正无穷，如果用户视窗滚动范围没有边界.
  double get maxScrollExtent;

  /// 本次drag事件累计的滚动距离. 单位: pixels
  /// drag事件流程:
  /// onDown -> onStart -> onUpdate -> onEnd 或者 onDown -> onCancel
  ///
  /// This object notifies its listeners when this value changes (except when
  /// the value changes due to [correctBy]).
  double get pixels;

  /// [pixels] 是否存在.
  bool get hasPixels;

  /// [minScrollExtent]和[maxScrollExtent]是否可用.
  bool get hasContentDimensions;

  /// 图书每一页内容的显示范围in pixel
  /// 横向翻页: 屏幕宽度
  /// 竖直滚动翻页: 屏幕高度
  double get viewportDimension;

  /// [viewportDimension] 是否存在.
  bool get hasViewportDimension;

  /// 在视窗被建立时调用.
  ///
  /// 在[applyContentDimensions]之前调用.
  bool applyViewportDimension(double viewportDimension);

  /// 在视窗被建立时调用.
  ///
  /// 如果[applyViewportDimension]被调用了，本方法也要被再次调用.
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent);

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

  /// [pixels]的滚动方向
  ///
  /// 1. [ScrollDirection.idle], 表示pixel = 0
  /// 2. [ScrollDirection.forward], 移动距离(primaryDelta) = 正数
  ///  a. 垂直滚动(从上往下): 书页内容显示上边部分，上一页
  ///  b. 翻页滚动(从左往右): 书页内容显示左边部分，上一页
  /// 3. [ScrollDirection.reverse], 移动距离(primaryDelta) = 负数
  ///  a. 垂直滚动(从下往上划): 书页内容显示下边部分，下一页
  ///  b. 翻页滚动(从右往左划): 书页内容显示右边部分，下一页
  ScrollDirection get pixelsDirection;

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
