import 'dart:ui';

import '../model/deeplink_button_position.dart';

/// Pure geometry for the floating button: model position <-> screen offset.
class DeeplinkButtonGeometry {
  final Size area;
  final double buttonSize;
  final double padding;

  const DeeplinkButtonGeometry({
    required this.area,
    required this.buttonSize,
    this.padding = 8,
  });

  double get _maxX => area.width - buttonSize - padding;
  double get _maxY => area.height - buttonSize - padding;

  /// Top-left offset for a snapped [position].
  Offset offsetFor(DeeplinkButtonPosition position) {
    final x = position.isLeft ? padding : _maxX;
    final y = padding + (_maxY - padding) * position.yFraction.clamp(0.0, 1.0);
    return Offset(x, _clampY(y));
  }

  /// Keep a free-drag [offset] inside the area.
  Offset clamp(Offset offset) {
    return Offset(
      offset.dx.clamp(padding, _maxX < padding ? padding : _maxX),
      _clampY(offset.dy),
    );
  }

  /// Snap a released [offset] to the nearest edge.
  DeeplinkButtonPosition snap(Offset offset) {
    final centerX = offset.dx + buttonSize / 2;
    final isLeft = centerX < area.width / 2;
    final span = _maxY - padding;
    final yFraction =
        span <= 0 ? 0.0 : ((offset.dy - padding) / span).clamp(0.0, 1.0);
    return DeeplinkButtonPosition(isLeft: isLeft, yFraction: yFraction);
  }

  double _clampY(double y) =>
      y.clamp(padding, _maxY < padding ? padding : _maxY);
}
