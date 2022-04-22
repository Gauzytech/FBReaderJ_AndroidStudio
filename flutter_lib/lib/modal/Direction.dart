/// 翻页方向
enum Direction {
  leftToRight,
  rightToLeft,
  up,
  down
}

extension DirectionExtension on Direction {

  bool get value {
    switch(this) {
      case Direction.leftToRight:
      case Direction.rightToLeft:
        return true;
      case Direction.up:
      case Direction.down:
        return false;
    }
  }
}
