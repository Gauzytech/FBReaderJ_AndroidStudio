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
  MediaQueryData mediaQueryData;

  ScreenUtil._internal()
      : mediaQueryData = MediaQueryData.fromWindow(ui.window);

  factory ScreenUtil() => _instance;

  static late final ScreenUtil _instance = ScreenUtil._internal();

  double get screenWidth =>
      mediaQueryData.size.width * mediaQueryData.devicePixelRatio;

  double get screenHeight =>
      mediaQueryData.size.height * mediaQueryData.devicePixelRatio;

  static double get displayDpi =>
      ui.window.devicePixelRatio * PixelDensity.mdpi.value;
}
