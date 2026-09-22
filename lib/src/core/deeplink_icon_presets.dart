import 'package:flutter/material.dart';

/// Icons the tester can switch to at runtime. Keys are stored in the profile.
class DeeplinkIconPresets {
  static const Map<String, IconData> icons = {
    'link': Icons.link,
    'bug': Icons.bug_report,
    'rocket': Icons.rocket_launch,
    'science': Icons.science,
    'bolt': Icons.bolt,
    'send': Icons.send,
    'qr': Icons.qr_code,
    'explore': Icons.explore,
    'star': Icons.star,
    'settings': Icons.settings,
    'phone': Icons.phonelink,
    'route': Icons.alt_route,
  };

  static IconData? of(String key) => icons[key];

  static List<String> get keys => icons.keys.toList();
}
