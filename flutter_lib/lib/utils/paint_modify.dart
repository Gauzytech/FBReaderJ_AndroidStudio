import 'dart:ui';

extension PaintModify on Paint {
  Paint copyWith({
    Color? color,
    bool? isAntiAlias,
    double? strokeWidth,
    BlendMode? blendMode,
  }) {
    return Paint()
      ..color = color ?? this.color
      ..isAntiAlias = isAntiAlias ?? this.isAntiAlias
      ..blendMode = blendMode ?? this.blendMode
      ..strokeWidth = strokeWidth ?? this.strokeWidth;
  }
}
