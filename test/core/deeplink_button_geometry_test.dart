import 'dart:ui';

import 'package:deeplink_tools/deeplink_tools.dart';
import 'package:deeplink_tools/src/core/deeplink_button_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const g = DeeplinkButtonGeometry(
    area: Size(400, 800),
    buttonSize: 48,
    padding: 8,
  );

  test('offsetFor snaps to right edge by default', () {
    final o = g.offsetFor(const DeeplinkButtonPosition.initial());
    expect(o.dx, 400 - 48 - 8);
    expect(o.dy, closeTo(8 + (800 - 48 - 8 - 8) * 0.6, 0.001));
  });

  test('snap picks the nearest edge and keeps the y fraction', () {
    final left = g.snap(const Offset(20, 8));
    expect(left.isLeft, isTrue);
    expect(left.yFraction, 0);

    final right = g.snap(const Offset(300, 744));
    expect(right.isLeft, isFalse);
    expect(right.yFraction, 1);
  });

  test('clamp keeps the button inside the area', () {
    expect(g.clamp(const Offset(-50, -50)), const Offset(8, 8));
    expect(g.clamp(const Offset(999, 999)), const Offset(344, 744));
  });
}
