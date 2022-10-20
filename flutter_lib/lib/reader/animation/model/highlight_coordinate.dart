import 'dart:ui';

class HighlightCoordinate {
  final int drawMode;
  final List<int> xs;
  final List<int> ys;

  HighlightCoordinate(this.drawMode, this.xs, this.ys);

  bool equals(HighlightCoordinate other) {
    if (drawMode != other.drawMode ||
        xs.length != other.xs.length ||
        ys.length != other.ys.length) return false;

    for(var i = 0; i < xs.length; i++) {
      if(xs[i] != other.xs[i]) return false;
    }
    for(var i = 0; i < ys.length; i++) {
      if(ys[i] != other.ys[i]) return false;
    }
    return true;
  }

  HighlightCoordinate.fromJson(Map<String, dynamic> json)
      : drawMode = json['drawMode'],
        xs = List.from(json['xs']),
        ys = List.from(json['ys']);

  @override
  String toString() {
    return "{"
        "\n\"drawMode\":$drawMode,"
        "\n\"xs\":$xs,"
        "\n\"ys\":$ys"
        "\n}";
  }
}

class NeatColor {
  final int red;
  final int green;
  final int blue;

  NeatColor(this.red, this.green, this.blue);

  Color toColor() {
    return Color.fromRGBO(red, green, blue, 1.0);
  }

  NeatColor.fromJson(Map<String, dynamic> json)
      : red = json['Red'],
        green = json['Green'],
        blue = json['Blue'];

  @override
  String toString() {
    return "color = [$red, $green, $blue]";
  }
}
