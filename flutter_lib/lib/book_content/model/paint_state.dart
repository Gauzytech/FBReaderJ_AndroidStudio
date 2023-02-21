/// 对应PaintStateEnum
enum PaintState {
  nothingToPaint,
  ready,
  startIsKnown,
  endIsKnown,
  toScrollForward,
  toScrollBackWard;

  static PaintState create(int value) {
    if (nothingToPaint.index == value) {
      return nothingToPaint;
    } else if (ready.index == value) {
      return ready;
    } else if (startIsKnown.index == value) {
      return startIsKnown;
    } else if (endIsKnown.index == value) {
      return endIsKnown;
    } else if (toScrollForward.index == value) {
      return toScrollForward;
    } else if (toScrollBackWard.index == value) {
      return toScrollBackWard;
    }

    throw Exception('Unknown paint state value: $value');
  }
}
