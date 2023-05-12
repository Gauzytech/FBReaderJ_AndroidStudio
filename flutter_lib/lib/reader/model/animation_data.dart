import 'package:flutter_lib/reader/model/spring_animation_range.dart';

class AnimationData {
  double start;
  double end;
  double velocity;
  SpringAnimationRange springRange;

  AnimationData(
      {required this.start,
      required this.end,
      required this.velocity,
      required this.springRange});

  double? applyRoundIfClose(double pageMoveDx) {
    if (pageMoveDx.roundToDouble() == springRange.startPageMoveDx) {
      return springRange.startPageMoveDx;
    } else if (pageMoveDx.roundToDouble() == springRange.endPageMoveDx) {
      return springRange.endPageMoveDx;
    }

    return null;
  }

  bool closeToEnd(double currentMoveDx) {
    return currentMoveDx == springRange.startPageMoveDx || currentMoveDx == springRange.endPageMoveDx;
  }

  AnimationData copy(double start, double end) {
    AnimationData data = AnimationData(
      start: start,
      end: end,
      velocity: velocity,
      springRange: springRange,
    );
    return data;
  }
}
