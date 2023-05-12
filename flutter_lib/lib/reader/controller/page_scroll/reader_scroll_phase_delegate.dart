
import 'package:flutter/widgets.dart';
import 'package:flutter_lib/reader/controller/page_scroll/book_page_position.dart';
import 'package:flutter_lib/reader/model/user_settings/page_mode.dart';
import 'package:flutter_lib/reader/reader_content_view.dart';

/// 书页滚动行为控制器
///
/// [ReaderScrollPhase] 的子类使用它来操作它们正在作用的[ReaderContentView]。
abstract class ReaderScrollPhaseDelegate {

  /// 当前坐标系的方向
  /// right/down, [0, 0]在左上角
  /// left/up, [0, 0]在右下角
  AxisDirection get axisDirection;

  /// 当前书页滚动模式
  /// 翻页模式/垂直滚动模式
  PageMode get pageMode;

  /// 更新[BookPagePosition]的坐标值.
  double setPixels(double pixels);

  /// 当用户触摸划动屏幕时，更新滚动position.
  void applyUserOffset(double delta);

  /// 立即终止当任何滚动行为并开始一个idle行为.
  void goIdle();

  /// 立即终止当任何滚动阶段并以[velocity]开始一个ballistic阶段
  void goBallistic(double velocity);
}