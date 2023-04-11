
import 'package:flutter/foundation.dart';

/// 对应ZLTextPosition
abstract class ContentPosition implements Comparable<ContentPosition> {
  int get paragraphIndex;

  int get elementIndex;

  int get charIndex;

  bool samePositionAs(ContentPosition other) {
    return paragraphIndex == other.paragraphIndex &&
        elementIndex == other.elementIndex &&
        charIndex == other.charIndex;
  }

  @override
  int compareTo(ContentPosition other) {
    int p0 = paragraphIndex;
    int p1 = other.paragraphIndex;
    if (p0 != p1) {
      return p0 < p1 ? -1 : 1;
    }

    final int e0 = elementIndex;
    final int e1 = other.elementIndex;
    if (e0 != e1) {
      return e0 < e1 ? -1 : 1;
    }

    return charIndex - other.charIndex;
  }

  int compareToIgnoreChar(ContentPosition other) {
    int p0 = paragraphIndex;
    int p1 = other.paragraphIndex;
    if (p0 != p1) {
      return p0 < p1 ? -1 : 1;
    }

    return elementIndex - other.elementIndex;
  }

  @override
  int get hashCode =>
      (paragraphIndex << 16) + (elementIndex << 8) + charIndex;

  @override
  bool operator ==(Object other) {
    if (other is! ContentPosition) {
      return false;
    }
    return paragraphIndex == other.paragraphIndex &&
        elementIndex == other.elementIndex &&
        charIndex == other.charIndex;
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    description.add("$runtimeType");
    description.add("paragraphIndex: $paragraphIndex");
    description.add("elementIndex: $elementIndex");
    description.add("charIndex: $charIndex");
    return '${describeIdentity(this)} (${description.join(", ")})';
  }
}
