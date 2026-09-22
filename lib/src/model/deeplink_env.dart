import 'dart:convert';

/// One environment (dev, staging, ...). Deeplinks are grouped under an env.
class DeeplinkEnv {
  final String id;
  final String label;

  const DeeplinkEnv({required this.id, required this.label});

  DeeplinkEnv copyWith({String? id, String? label}) {
    return DeeplinkEnv(id: id ?? this.id, label: label ?? this.label);
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll({'id': id});
    result.addAll({'label': label});
    return result;
  }

  factory DeeplinkEnv.fromMap(Map<String, dynamic> map) {
    return DeeplinkEnv(id: map['id'] ?? '', label: map['label'] ?? '');
  }

  String toJson() => json.encode(toMap());

  factory DeeplinkEnv.fromJson(String source) =>
      DeeplinkEnv.fromMap(json.decode(source));

  @override
  String toString() => 'DeeplinkEnv(id: $id, label: $label)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeeplinkEnv && other.id == id && other.label == label;
  }

  @override
  int get hashCode => id.hashCode ^ label.hashCode;
}
