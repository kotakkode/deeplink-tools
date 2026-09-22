import 'package:flutter/material.dart';

import '../core/deeplink_icon_presets.dart';

/// Picks the runtime preset icon when set, else the host icon, else a link.
class DeeplinkButtonIcon extends StatelessWidget {
  final String presetKey;
  final Widget? fallback;
  final Color color;

  const DeeplinkButtonIcon({
    super.key,
    required this.presetKey,
    required this.color,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final preset = DeeplinkIconPresets.of(presetKey);
    if (preset != null) return Icon(preset, color: color);
    return IconTheme(
      data: IconThemeData(color: color),
      child: fallback ?? Icon(Icons.link, color: color),
    );
  }
}
