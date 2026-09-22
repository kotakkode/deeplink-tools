import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'deeplink_entry.dart';
import 'deeplink_env.dart';

/// The shareable file content: envs + entries + chosen icon.
class DeeplinkProfile {
  static const int currentVersion = 1;

  final int version;
  final String iconPreset;
  final List<DeeplinkEnv> envs;
  final List<DeeplinkEntry> entries;

  const DeeplinkProfile({
    this.version = currentVersion,
    this.iconPreset = '',
    this.envs = const [],
    this.entries = const [],
  });

  const DeeplinkProfile.empty() : this();

  DeeplinkProfile copyWith({
    int? version,
    String? iconPreset,
    List<DeeplinkEnv>? envs,
    List<DeeplinkEntry>? entries,
  }) {
    return DeeplinkProfile(
      version: version ?? this.version,
      iconPreset: iconPreset ?? this.iconPreset,
      envs: envs ?? this.envs,
      entries: entries ?? this.entries,
    );
  }

  /// Merge [other] into this profile. Items with the same id are replaced by
  /// [other]'s version; new items are appended. Icon preset from [other] wins
  /// when non-empty.
  DeeplinkProfile mergeWith(DeeplinkProfile other) {
    return DeeplinkProfile(
      version: currentVersion,
      iconPreset: other.iconPreset.isNotEmpty ? other.iconPreset : iconPreset,
      envs: _mergeById(envs, other.envs, (e) => e.id),
      entries: _mergeById(entries, other.entries, (e) => e.id),
    );
  }

  static List<T> _mergeById<T>(
    List<T> base,
    List<T> incoming,
    String Function(T) idOf,
  ) {
    final result = List<T>.of(base);
    for (final item in incoming) {
      final index = result.indexWhere((e) => idOf(e) == idOf(item));
      if (index >= 0) {
        result[index] = item;
      } else {
        result.add(item);
      }
    }
    return result;
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll({'version': version});
    result.addAll({'iconPreset': iconPreset});
    result.addAll({'envs': envs.map((e) => e.toMap()).toList()});
    result.addAll({'entries': entries.map((e) => e.toMap()).toList()});
    return result;
  }

  factory DeeplinkProfile.fromMap(Map<String, dynamic> map) {
    final rawEnvs = map['envs'];
    final rawEntries = map['entries'];
    return DeeplinkProfile(
      version: map['version']?.toInt() ?? currentVersion,
      iconPreset: map['iconPreset'] ?? '',
      envs:
          rawEnvs is List
              ? rawEnvs
                  .whereType<Map>()
                  .map((e) => DeeplinkEnv.fromMap(Map<String, dynamic>.from(e)))
                  .toList()
              : const [],
      entries:
          rawEntries is List
              ? rawEntries
                  .whereType<Map>()
                  .map(
                    (e) => DeeplinkEntry.fromMap(Map<String, dynamic>.from(e)),
                  )
                  .toList()
              : const [],
    );
  }

  String toJson() => json.encode(toMap());

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toMap());

  factory DeeplinkProfile.fromJson(String source) =>
      DeeplinkProfile.fromMap(json.decode(source));

  @override
  String toString() =>
      'DeeplinkProfile(version: $version, iconPreset: $iconPreset, envs: $envs, entries: $entries)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeeplinkProfile &&
        other.version == version &&
        other.iconPreset == iconPreset &&
        listEquals(other.envs, envs) &&
        listEquals(other.entries, entries);
  }

  @override
  int get hashCode =>
      version.hashCode ^
      iconPreset.hashCode ^
      envs.length.hashCode ^
      entries.length.hashCode;
}
