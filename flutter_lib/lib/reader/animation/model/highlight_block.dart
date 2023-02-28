import 'dart:ui';

class HighlightBlock {
  ColorData color;
  List<BlockCoordinate> coordinates;

  HighlightBlock(this.color, this.coordinates);

  HighlightBlock.fromJson(Map<String, dynamic> json)
      : color = ColorData.fromJson(json['color']),
        coordinates = (json['coordinates'] as List)
            .map((item) => BlockCoordinate.fromJson(item))
            .toList();

  bool equals(HighlightBlock other) {
    if (color != other.color || coordinates.length != other.coordinates.length) {
      return false;
    }
    for(var i = 0; i < coordinates.length; i++) {
      if(!coordinates[i].equals(other.coordinates[i])) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    return "HighlightBlock: {color= $color, coordinates= $coordinates}";
  }
}

class BlockCoordinate {
  final int type;
  final List<int> xs;
  final List<int> ys;

  BlockCoordinate(this.type, this.xs, this.ys);

  bool equals(BlockCoordinate other) {
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

  BlockCoordinate.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        xs = List.from(json['xs']),
        ys = List.from(json['ys']);

  @override
  String toString() {
    return "{"
        "\n\"type\":$type,"
        "\n\"xs\":$xs,"
        "\n\"ys\":$ys"
        "\n}";
  }
}

class ColorData {
  final int red;
  final int green;
  final int blue;

  ColorData(this.red, this.green, this.blue);

  Color toColor() {
    return Color.fromRGBO(red, green, blue, 1.0);
  }

  ColorData.fromJson(Map<String, dynamic> json)
      : red = json['Red'],
        green = json['Green'],
        blue = json['Blue'];

  @override
  String toString() {
    return "NeatColor: {$red, $green, $blue}";
  }
}
