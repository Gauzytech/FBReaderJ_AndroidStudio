import 'package:flutter_lib/reader/model/selection/highlight_block.dart';

class SelectionCursor {
  final ColorData color;
  final CursorPoint point;
  int dpi;
  CursorDirection direction;

  SelectionCursor(this.color, this.point, this.dpi, this.direction);

  SelectionCursor.fromJson(this.direction, Map<String, dynamic> json)
      : color = ColorData.fromJson(json['color']),
        point = CursorPoint.fromJson(json['point']),
        dpi = json['dpi'];

  @override
  String toString() {
    return "SelectionCursor {color= $color, point= $point}";
  }
}

class CursorPoint {
  final int x;
  final int y;

  CursorPoint(this.x, this.y);

  CursorPoint.fromJson(Map<String, dynamic> json)
      : x = json['X'],
        y = json['Y'];

  @override
  String toString() {
    return "[$x, $y]";
  }
}

enum CursorDirection { left, right }
