class SpringAnimationRange {
  double startPageMoveDx;
  double endPageMoveDx;
  SpringDirection direction;

  SpringAnimationRange({
    required this.startPageMoveDx,
    required this.endPageMoveDx,
    required this.direction,
  });

  @override
  String toString() {
    if (direction == SpringDirection.leftToRightPrev) {
      return "[$startPageMoveDx -> $endPageMoveDx], 从左到右, 上一页";
    } else if (direction == SpringDirection.rightToLeftNext) {
      return "[$startPageMoveDx -> $endPageMoveDx], 从右到左, 下一页";
    } else {
      return "[$startPageMoveDx -> $endPageMoveDx], 回弹";
    }
  }

  bool isWithinRange(double targetCurrentMoveDx) {
    switch (direction) {
      case SpringDirection.leftToRightPrev:
        return targetCurrentMoveDx >= startPageMoveDx && targetCurrentMoveDx <= endPageMoveDx;
      case SpringDirection.rightToLeftNext:
        return targetCurrentMoveDx >= endPageMoveDx && targetCurrentMoveDx <= startPageMoveDx;
      case SpringDirection.none:
        return true;
    }
  }
}

enum SpringDirection {
  leftToRightPrev, // 上一页
  rightToLeftNext, // 下一页
  none
}
