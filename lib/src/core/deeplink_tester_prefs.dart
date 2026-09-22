import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/deeplink_button_position.dart';
import '../model/deeplink_history_item.dart';
import '../model/dispatch_mode.dart';

/// Small per-device preferences: button position, selected env, mode, history.
class DeeplinkTesterPrefs {
  static const _prefix = 'deeplink_tester.';
  static const _keyPosition = '${_prefix}button_pos';
  static const _keyEnv = '${_prefix}selected_env';
  static const _keyMode = '${_prefix}dispatch_mode';
  static const _keyHistory = '${_prefix}history';
  static const _keyBundledHash = '${_prefix}bundled_hash';

  final Future<SharedPreferences> Function() provider;

  DeeplinkTesterPrefs({Future<SharedPreferences> Function()? provider})
    : provider = provider ?? SharedPreferences.getInstance;

  Future<DeeplinkButtonPosition?> loadPosition() async {
    final raw = (await provider()).getString(_keyPosition);
    if (raw == null) return null;
    try {
      return DeeplinkButtonPosition.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePosition(DeeplinkButtonPosition position) async {
    await (await provider()).setString(_keyPosition, position.toJson());
  }

  Future<String?> loadSelectedEnv() async =>
      (await provider()).getString(_keyEnv);

  Future<void> saveSelectedEnv(String id) async =>
      (await provider()).setString(_keyEnv, id);

  Future<DispatchMode> loadDispatchMode() async =>
      DispatchMode.fromKey((await provider()).getString(_keyMode));

  Future<void> saveDispatchMode(DispatchMode mode) async =>
      (await provider()).setString(_keyMode, mode.key);

  Future<List<DeeplinkHistoryItem>> loadHistory() async {
    final raw = (await provider()).getString(_keyHistory);
    if (raw == null) return const [];
    try {
      final list = json.decode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => DeeplinkHistoryItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String?> loadBundledHash() async =>
      (await provider()).getString(_keyBundledHash);

  Future<void> saveBundledHash(String hash) async =>
      (await provider()).setString(_keyBundledHash, hash);

  Future<void> saveHistory(List<DeeplinkHistoryItem> items) async {
    await (await provider()).setString(
      _keyHistory,
      json.encode(items.map((e) => e.toMap()).toList()),
    );
  }
}
