import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum PixelDensity {
  ldpi(120),
  mdpi(160),
  hdpi(240),
  xhdpi(320),
  xxhdpi(480),
  xxxhdpi(640);

  final int value;

  const PixelDensity(this.value);
}

class ScreenUtil {
  static double getScreenHeight() {
    return MediaQueryData.fromWindow(ui.window).size.height;
  }

  static double getScreenWidth() {
    return MediaQueryData.fromWindow(ui.window).size.width;
  }

  static double get displayDpi =>
      ui.window.devicePixelRatio * PixelDensity.mdpi.value;
}
