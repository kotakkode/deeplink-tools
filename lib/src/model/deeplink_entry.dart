import 'dart:convert';

/// A saved deeplink: which env it belongs to, a display name, and the exact
/// URL that is sent when executed.
class DeeplinkEntry {
  final String id;
  final String envId;
  final String name;
  final String url;

  const DeeplinkEntry({
    required this.id,
    required this.envId,
    required this.name,
    required this.url,
  });

  DeeplinkEntry copyWith({
    String? id,
    String? envId,
    String? name,
    String? url,
  }) {
    return DeeplinkEntry(
      id: id ?? this.id,
      envId: envId ?? this.envId,
      name: name ?? this.name,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll({'id': id});
    result.addAll({'envId': envId});
    result.addAll({'name': name});
    result.addAll({'url': url});
    return result;
  }

  factory DeeplinkEntry.fromMap(Map<String, dynamic> map) {
    return DeeplinkEntry(
      id: map['id'] ?? '',
      envId: map['envId'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? map['template'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DeeplinkEntry.fromJson(String source) =>
      DeeplinkEntry.fromMap(json.decode(source));

  @override
  String toString() =>
      'DeeplinkEntry(id: $id, envId: $envId, name: $name, url: $url)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeeplinkEntry &&
        other.id == id &&
        other.envId == envId &&
        other.name == name &&
        other.url == url;
  }

  @override
  int get hashCode =>
      id.hashCode ^ envId.hashCode ^ name.hashCode ^ url.hashCode;
}
