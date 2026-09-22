import 'dart:async';

import '../model/deeplink_entry.dart';

/// An entry removed from the list but still restorable until [timer] fires.
class PendingRemoval {
  final DeeplinkEntry entry;
  final int index;
  final Timer timer;

  const PendingRemoval({
    required this.entry,
    required this.index,
    required this.timer,
  });
}
