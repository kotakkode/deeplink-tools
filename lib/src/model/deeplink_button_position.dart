import 'dart:convert';

/// Where the floating button rests: snapped to the left or right edge, at a
/// fraction (0..1) of the available height.
class DeeplinkButtonPosition {
  final bool isLeft;
  final double yFraction;

  const DeeplinkButtonPosition({required this.isLeft, required this.yFraction});

  const DeeplinkButtonPosition.initial() : this(isLeft: false, yFraction: 0.6);

  DeeplinkButtonPosition copyWith({bool? isLeft, double? yFraction}) {
    return DeeplinkButtonPosition(
      isLeft: isLeft ?? this.isLeft,
      yFraction: yFraction ?? this.yFraction,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll({'isLeft': isLeft});
    result.addAll({'yFraction': yFraction});
    return result;
  }

  factory DeeplinkButtonPosition.fromMap(Map<String, dynamic> map) {
    return DeeplinkButtonPosition(
      isLeft: map['isLeft'] ?? false,
      yFraction: (map['yFraction'] ?? 0.6).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory DeeplinkButtonPosition.fromJson(String source) =>
      DeeplinkButtonPosition.fromMap(json.decode(source));

  @override
  String toString() =>
      'DeeplinkButtonPosition(isLeft: $isLeft, yFraction: $yFraction)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeeplinkButtonPosition &&
        other.isLeft == isLeft &&
        other.yFraction == yFraction;
  }

  @override
  int get hashCode => isLeft.hashCode ^ yFraction.hashCode;
}
