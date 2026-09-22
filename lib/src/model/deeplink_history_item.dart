import 'dart:convert';

/// One sent deeplink, kept for quick resend.
class DeeplinkHistoryItem {
  final String entryId;
  final String name;
  final String envLabel;
  final String url;
  final DateTime sentAt;

  const DeeplinkHistoryItem({
    required this.entryId,
    required this.name,
    required this.envLabel,
    required this.url,
    required this.sentAt,
  });

  DeeplinkHistoryItem copyWith({
    String? entryId,
    String? name,
    String? envLabel,
    String? url,
    DateTime? sentAt,
  }) {
    return DeeplinkHistoryItem(
      entryId: entryId ?? this.entryId,
      name: name ?? this.name,
      envLabel: envLabel ?? this.envLabel,
      url: url ?? this.url,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll({'entryId': entryId});
    result.addAll({'name': name});
    result.addAll({'envLabel': envLabel});
    result.addAll({'url': url});
    result.addAll({'sentAt': sentAt.toIso8601String()});
    return result;
  }

  factory DeeplinkHistoryItem.fromMap(Map<String, dynamic> map) {
    return DeeplinkHistoryItem(
      entryId: map['entryId'] ?? '',
      name: map['name'] ?? '',
      envLabel: map['envLabel'] ?? '',
      url: map['url'] ?? '',
      sentAt:
          DateTime.tryParse(map['sentAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String toJson() => json.encode(toMap());

  factory DeeplinkHistoryItem.fromJson(String source) =>
      DeeplinkHistoryItem.fromMap(json.decode(source));

  @override
  String toString() =>
      'DeeplinkHistoryItem(entryId: $entryId, name: $name, envLabel: $envLabel, url: $url, sentAt: $sentAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeeplinkHistoryItem &&
        other.entryId == entryId &&
        other.name == name &&
        other.envLabel == envLabel &&
        other.url == url &&
        other.sentAt == sentAt;
  }

  @override
  int get hashCode =>
      entryId.hashCode ^
      name.hashCode ^
      envLabel.hashCode ^
      url.hashCode ^
      sentAt.hashCode;
}
