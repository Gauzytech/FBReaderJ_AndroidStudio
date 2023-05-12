import 'dart:ui';

import 'package:flutter_lib/interface/debug_info_provider.dart';
import 'package:flutter_lib/reader/model/paint/paint_block.dart';

class HighlightBlock extends PaintBlock with DebugInfoProvider {
  ColorData color;
  List<HighlightCoord> coordinates;

  HighlightBlock(this.color, this.coordinates);

  HighlightBlock.fromJson(Map<String, dynamic> json)
      : color = ColorData.fromJson(json['color']),
        coordinates = (json['coordinates'] as List)
            .map((item) => HighlightCoord.fromJson(item))
            .toList();

  @override
  int get hashCode => color.hashCode + coordinates.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! HighlightBlock) {
      return false;
    }

    if (color != other.color ||
        coordinates.length != other.coordinates.length) {
      return false;
    }
    for (var i = 0; i < coordinates.length; i++) {
      if (coordinates[i] != other.coordinates[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  void debugFillDescription(List<String> description) {
    description.add("color: $color");
    description.add("coordinates: $coordinates");
  }
}

class HighlightCoord with DebugInfoProvider {
  final int type;
  final List<int> xs;
  final List<int> ys;

  HighlightCoord(this.type, this.xs, this.ys);

  @override
  int get hashCode => type.hashCode + xs.hashCode + ys.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! HighlightCoord) return false;

    if (type != other.type ||
        xs.length != other.xs.length ||
        ys.length != other.ys.length) return false;

    for (var i = 0; i < xs.length; i++) {
      if (xs[i] != other.xs[i]) return false;
    }
    for (var i = 0; i < ys.length; i++) {
      if (ys[i] != other.ys[i]) return false;
    }
    return true;
  }

  HighlightCoord.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        xs = List.from(json['xs']),
        ys = List.from(json['ys']);

  @override
  void debugFillDescription(List<String> description) {
    description.add("type: $type");
    description.add("xs: $xs");
    description.add("xs: $ys");
  }
}

class ColorData {
  final int red;
  final int green;
  final int blue;

  ColorData(this.red, this.green, this.blue);

  Color toColor([double opacity = 1.0]) {
    return Color.fromRGBO(red, green, blue, opacity);
  }

  ColorData.fromJson(Map<String, dynamic> json)
      : red = json['Red'],
        green = json['Green'],
        blue = json['Blue'];

  static ColorData? fromJsonNullable(dynamic rawData) {
    return rawData != null ? ColorData.fromJson(rawData) : null;
  }

  @override
  String toString() {
    return "NeatColor: {$red, $green, $blue}";
  }
}
