import 'dart:io';

import 'package:deeplink_tools/deeplink_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late DeeplinkProfileStorage storage;

  const profile = DeeplinkProfile(
    iconPreset: 'bug',
    envs: [DeeplinkEnv(id: 'dev', label: 'DEV')],
    entries: [
      DeeplinkEntry(id: 'e1', envId: 'dev', name: 'One', url: 'a://1'),
      DeeplinkEntry(id: 'e2', envId: 'dev', name: 'Two', url: 'a://2'),
    ],
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('deeplink_tester_');
    storage = DeeplinkProfileStorage(directoryProvider: () async => dir);
  });

  tearDown(() => dir.delete(recursive: true));

  test('load returns null when no file', () async {
    expect(await storage.load(), isNull);
  });

  test('save then load round-trips', () async {
    await storage.save(profile);
    expect(await storage.load(), profile);
  });

  test('parse returns null on malformed json', () {
    expect(DeeplinkProfileStorage.parse('{not json'), isNull);
  });

  test('writeExportCopy creates a separate timestamped file', () async {
    final f = await storage.writeExportCopy(profile);
    expect(f.path, contains('deeplink_profiles_'));
    expect(DeeplinkProfileStorage.parse(await f.readAsString()), profile);
  });

  test('mergeWith replaces by id and appends new', () {
    const incoming = DeeplinkProfile(
      entries: [
        DeeplinkEntry(id: 'e1', envId: 'dev', name: 'One updated', url: 'x'),
        DeeplinkEntry(id: 'e3', envId: 'dev', name: 'Three', url: 'y'),
      ],
    );
    final merged = profile.mergeWith(incoming);
    expect(merged.entries.map((e) => e.id), ['e1', 'e2', 'e3']);
    expect(merged.entries.first.name, 'One updated');
    expect(merged.iconPreset, 'bug');
    expect(merged.envs, profile.envs);
  });
}
