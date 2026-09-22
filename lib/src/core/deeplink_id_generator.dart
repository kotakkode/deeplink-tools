import 'dart:math';

/// Generates stable, human-readable ids: `<slug>-<4 random chars>`.
class DeeplinkIdGenerator {
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final Random _random;

  DeeplinkIdGenerator({Random? random}) : _random = random ?? Random();

  String generate(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final suffix =
        List.generate(
          4,
          (_) => _alphabet[_random.nextInt(_alphabet.length)],
        ).join();
    return '${slug.isEmpty ? 'entry' : slug}-$suffix';
  }
}
