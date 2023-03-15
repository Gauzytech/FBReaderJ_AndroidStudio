import 'dart:ui';

extension PaintModify on Paint {
  Paint withColor(Color color) {
    return Paint()
      ..color = color
      ..isAntiAlias = isAntiAlias
      ..style = style
      ..blendMode = blendMode
      ..strokeWidth = strokeWidth
      ..strokeJoin = strokeJoin;
  }

  Paint withAntiAlias(bool isAntiAlias) {
    return Paint()
      ..color = color
      ..isAntiAlias = isAntiAlias
      ..style = style
      ..blendMode = blendMode
      ..strokeWidth = strokeWidth
      ..strokeJoin = strokeJoin;
  }

  Paint withStrokeWidth(double strokeWidth) {
    return Paint()
      ..color = color
      ..isAntiAlias = isAntiAlias
      ..style = style
      ..blendMode = blendMode
      ..strokeWidth = strokeWidth
      ..strokeJoin = strokeJoin;
  }

  Paint withBlendMode(BlendMode blendMode) {
    return Paint()
      ..color = color
      ..isAntiAlias = isAntiAlias
      ..style = style
      ..blendMode = blendMode
      ..strokeWidth = strokeWidth
      ..strokeJoin = strokeJoin;
  }
}
