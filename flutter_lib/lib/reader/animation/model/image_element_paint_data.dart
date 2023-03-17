import 'dart:async';
import 'dart:core';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_lib/interface/disposable_paint_data.dart';
import 'package:image/image.dart' as lib;

import 'element_paint_data.dart';

class ImageElementPaintData extends ElementPaintData with DisposablePaintData {
  ImageSourceType sourceType;
  double left;
  double top;
  String imageSrc;
  Size maxSize;
  ScalingType scalingType;
  ColorAdjustingMode adjustingModeForImages;

  ui.Image? get image => _image;
  ui.Image? _image;

  bool get hasImage => _image != null;
  VoidCallback? _onImageLoaded;

  ImageElementPaintData.fromJson(Map<String, dynamic> json)
      : sourceType = ImageSourceType.fromOrdinal(json['sourceType']),
        left = json['left'],
        top = json['top'],
        imageSrc = json['imageSrc'],
        maxSize = Size(
          json['maxSize']['Width'] + .0,
          json['maxSize']['Height'] + .0,
        ),
        scalingType = ScalingType.fromOrdinal(json['scalingType']),
        adjustingModeForImages =
            ColorAdjustingMode.fromOrdinal(json['adjustingModeForImages']);

  ImageStreamListener? _listener;
  ImageStream? _stream;

  Future<void> fetchImage(String rootPath, {VoidCallback? callback}) async {
    _onImageLoaded = callback;
    switch (sourceType) {
      case ImageSourceType.file:
        var path = "$rootPath/$imageSrc";
        print('flutter内容绘制流程, 获取图片文件 path = $path');
        final cmd = lib.Command()..decodeImageFile(path);
        lib.Command result = await cmd.executeThread();
        lib.Image? baseSizeImage = result.outputImage;

        _image = baseSizeImage != null
            ? await _resizeImage(baseSizeImage, maxSize, scalingType)
            : null;
        _onImageLoaded?.call();
        break;
      case ImageSourceType.network:
        throw Exception('not implemented');
    }
  }

  Future<ui.Image> _resizeImage(
    lib.Image baseSizeImage,
    Size maxSize,
    ScalingType scaling,
  ) {
    double baseWidth = baseSizeImage.width.toDouble();
    double baseHeight = baseSizeImage.height.toDouble();
    print('flutter内容绘制流程, baseSizeImage: [$baseWidth, $baseHeight]');
    if (maxSize == Size(baseWidth, baseHeight)) {
      return _loadImage(MemoryImage(lib.encodeBmp(baseSizeImage)));
    }
    switch (scaling) {
      case ScalingType.originalSize:
        return _loadImage(MemoryImage(lib.encodeBmp(baseSizeImage)));
      case ScalingType.integerCoefficient:
        final double w, h;
        if (baseWidth * maxSize.height > baseHeight * maxSize.width) {
          w = maxSize.width;
          h = max(1, baseHeight * w / baseWidth);
        } else {
          h = maxSize.height;
          w = max(1, baseWidth * h / baseHeight);
        }
        return _loadImage(
          MemoryImage(lib.encodeBmp(baseSizeImage)),
          config: ImageConfiguration(size: Size(w, h)),
        );
      case ScalingType.fitMaximum:
        final double w, h;
        if (baseWidth * maxSize.height > baseHeight * maxSize.width) {
          w = maxSize.width;
          h = max(1, baseHeight * w / baseWidth);
        } else {
          h = maxSize.height;
          w = max(1, baseWidth * h / baseHeight);
        }
        return _loadImage(
          MemoryImage(lib.encodeBmp(baseSizeImage)),
          config: ImageConfiguration(size: Size(w, h)),
        );
    }
  }

  Future<ui.Image> _loadImage(
    ImageProvider provider, {
    ImageConfiguration config = ImageConfiguration.empty,
  }) async {
    Completer<ui.Image> completer = Completer<ui.Image>();
    _stream = provider.resolve(config);
    _listener = ImageStreamListener(
      (ImageInfo frame, bool sync) {
        final ui.Image baseSizeImage = frame.image;
        completer.complete(baseSizeImage);
        _stream?.removeListener(_listener!);
      },
    );
    _stream?.addListener(_listener!);
    return completer.future;
  }

  @override
  void tearDown() {
    if (_listener != null) {
      _stream?.removeListener(_listener!);
    }
    _onImageLoaded = null;
    _image?.dispose();
    _image = null;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add("$runtimeType");
    description.add("sourceType: $sourceType");
    description.add("left: $left");
    description.add("top: $top");
    description.add("imageSrc: $imageSrc");
    description.add("maxSize: $maxSize");
    description.add("scalingType: $scalingType");
    description.add("adjustingModeForImages: $adjustingModeForImages");
  }
}

enum ImageSourceType {
  file,
  network;

  static ImageSourceType fromOrdinal(int index) {
    if (index == ImageSourceType.network.index) {
      return ImageSourceType.network;
    } else if (index == ImageSourceType.file.index) {
      return ImageSourceType.file;
    } else {
      throw Exception('Unknown index: $index');
    }
  }
}

enum ScalingType {
  originalSize,
  integerCoefficient,
  fitMaximum;

  static ScalingType fromOrdinal(int index) {
    if (index == ScalingType.originalSize.index) {
      return ScalingType.originalSize;
    } else if (index == ScalingType.integerCoefficient.index) {
      return ScalingType.integerCoefficient;
    } else if (index == ScalingType.fitMaximum.index) {
      return ScalingType.fitMaximum;
    } else {
      throw Exception('Unknown index: $index');
    }
  }
}

enum ColorAdjustingMode {
  none,
  darkenToBackground,
  lightenToBackground;

  static ColorAdjustingMode fromOrdinal(int index) {
    if (index == ColorAdjustingMode.none.index) {
      return ColorAdjustingMode.none;
    } else if (index == ColorAdjustingMode.darkenToBackground.index) {
      return ColorAdjustingMode.darkenToBackground;
    } else if (index == ColorAdjustingMode.lightenToBackground.index) {
      return ColorAdjustingMode.lightenToBackground;
    } else {
      throw Exception('Unknown index: $index');
    }
  }
}
