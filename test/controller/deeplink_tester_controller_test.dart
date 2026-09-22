import 'dart:io';
import 'dart:math';

import 'package:deeplink_tools/deeplink_tools.dart';
import 'package:deeplink_tools/src/core/deeplink_id_generator.dart';
import 'package:deeplink_tools/src/core/deeplink_profile_transfer.dart';
import 'package:deeplink_tools/src/core/deeplink_tester_prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingDispatcher implements DeeplinkDispatcher {
  final urls = <String>[];
  bool ok = true;

  @override
  Future<DispatchResult> dispatch(String url) async {
    urls.add(url);
    return ok
        ? const DispatchResult.success('ok')
        : const DispatchResult.failure('nope');
  }
}

class FakeTransfer extends DeeplinkProfileTransfer {
  String? nextPick;
  File? shared;

  @override
  Future<String?> pickJsonText() async => nextPick;

  @override
  Future<void> share(File file) async => shared = file;

  String? savePath;
  Uint8List? savedBytes;
  String? savedName;

  @override
  Future<String?> saveToDevice(String fileName, Uint8List bytes) async {
    savedName = fileName;
    savedBytes = bytes;
    return savePath;
  }
}

const bundledJson = '''
{
  "version": 1,
  "iconPreset": "",
  "envs": [],
  "entries": [
    {"id": "dash", "envId": "stg", "name": "Dashboard",
     "url": "https://links.example.com/stg?campaign=dashboard"},
    {"id": "verify", "envId": "stg", "name": "Verify",
     "url": "myapp://stg/verify/abc"},
    {"id": "dev-home", "envId": "dev", "name": "Dev home",
     "url": "myapp://dev/home"}
  ]
}
''';

const config = DeeplinkTesterConfig(
  eventChannelName: 'test/events',
  initialEnvId: 'stg',
  bundledProfileAsset: 'assets/seed.json',
  undoWindow: Duration(milliseconds: 50),
  activeFlashDuration: Duration(milliseconds: 20),
  historyLimit: 3,
  envs: [
    DeeplinkEnv(id: 'dev', label: 'DEV'),
    DeeplinkEnv(id: 'stg', label: 'STG'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late DeeplinkProfileStorage storage;
  late RecordingDispatcher inject;
  late RecordingDispatcher os;
  late FakeTransfer transfer;
  late DeeplinkTesterController c;

  DeeplinkTesterController build({
    TargetPlatform platform = TargetPlatform.android,
  }) {
    return DeeplinkTesterController(
      config: config,
      storage: storage,
      prefs: DeeplinkTesterPrefs(),
      transfer: transfer,
      idGenerator: DeeplinkIdGenerator(random: Random(1)),
      dispatchers: {DispatchMode.inject: inject, DispatchMode.osLaunch: os},
      assetLoader: (_) async => bundledJson,
      platform: platform,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('deeplink_ctrl_');
    storage = DeeplinkProfileStorage(directoryProvider: () async => dir);
    inject = RecordingDispatcher();
    os = RecordingDispatcher();
    transfer = FakeTransfer();
    c = build();
    await c.init();
  });

  tearDown(() async {
    await c.flush();
    c.dispose();
    await dir.delete(recursive: true);
  });

  test('init seeds from bundled asset and selects initial env', () {
    expect(c.entries.map((e) => e.id), ['dash', 'verify', 'dev-home']);
    expect(c.selectedEnvId, 'stg');
    expect(c.envs.map((e) => e.id), ['dev', 'stg']);
    expect(c.hasBundledDefaults, isTrue);
  });

  test(
    'filteredEntries shows only the selected env and matches query',
    () async {
      expect(c.filteredEntries('').map((e) => e.id), ['dash', 'verify']);
      expect(c.filteredEntries('verify').map((e) => e.id), ['verify']);
      expect(c.filteredEntries('zzz'), isEmpty);
      await c.selectEnv('dev');
      expect(c.filteredEntries('').map((e) => e.id), ['dev-home']);
      expect(c.entryCountFor('stg'), 2);
    },
  );

  test('send dispatches the saved url as-is and records history', () async {
    final outcome = await c.send(c.entryById('dash')!);
    expect(outcome.sent, isTrue);
    expect(inject.urls, [
      'https://links.example.com/stg?campaign=dashboard',
    ]);
    expect(c.history.single.envLabel, 'STG');
    expect(c.isActive, isTrue);
    expect(c.buttonOpacity, config.activeOpacity);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(c.buttonOpacity, config.idleOpacity);
  });

  test('sendById works for entries of any env', () async {
    final outcome = await c.sendById('dev-home');
    expect(outcome.sent, isTrue);
    expect(inject.urls, ['myapp://dev/home']);
    expect(c.history.single.envLabel, 'DEV');
    expect((await c.sendById('nope')).sent, isFalse);
  });

  test('global dispatch mode is honoured', () async {
    await c.setDispatchMode(DispatchMode.osLaunch);
    await c.send(c.entryById('dash')!);
    expect(os.urls, hasLength(1));
    expect(inject.urls, isEmpty);
  });

  test('iOS https via OS launch falls back to inject', () async {
    await c.flush();
    c.dispose();
    c = build(platform: TargetPlatform.iOS);
    await c.init();
    await c.setDispatchMode(DispatchMode.osLaunch);
    final outcome = await c.send(c.entryById('dash')!);
    expect(outcome.sent, isTrue);
    expect(os.urls, isEmpty);
    expect(inject.urls, hasLength(1));
    expect(outcome.message, contains('used In-app inject'));
  });

  test('empty url and failed dispatch are reported, not recorded', () async {
    expect((await c.sendUrl('   ')).sent, isFalse);
    inject.ok = false;
    final outcome = await c.send(c.entryById('dash')!);
    expect(outcome.sent, isFalse);
    expect(c.history, isEmpty);
    expect(c.toastMessage, 'nope');
  });

  test('history is capped and resendLast replays the newest', () async {
    for (var i = 0; i < 5; i++) {
      await c.sendUrl('myapp://x/$i');
    }
    expect(c.history, hasLength(3));
    expect(c.history.first.url, 'myapp://x/4');
    await c.resendLast();
    expect(inject.urls.last, 'myapp://x/4');
  });

  test('addEntry generates unique id, trims, persists after flush', () async {
    final added = await c.addEntry(
      envId: 'stg',
      name: ' My Link ',
      url: ' myapp://stg/a ',
    );
    expect(added.id, startsWith('my-link-'));
    expect(added.name, 'My Link');
    expect(added.url, 'myapp://stg/a');
    await c.flush();
    final stored = await storage.load();
    expect(stored!.entries.map((e) => e.id), contains(added.id));
  });

  test('updateEntry can move an entry to another env', () async {
    await c.updateEntry(c.entryById('dash')!.copyWith(envId: 'dev'));
    expect(c.filteredEntries('').map((e) => e.id), ['verify']);
    expect(c.entryCountFor('dev'), 2);
  });

  test('removeEntry is undoable inside the window', () async {
    await c.removeEntry('dash');
    expect(c.entryById('dash'), isNull);
    expect(c.hasPendingRemoval, isTrue);
    c.undoRemove();
    expect(c.entries.map((e) => e.id), ['dash', 'verify', 'dev-home']);
    expect(c.hasPendingRemoval, isFalse);
  });

  test('removeEntry commits after the window and persists', () async {
    await c.removeEntry('dash');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(c.hasPendingRemoval, isFalse);
    await c.flush();
    final stored = await storage.load();
    expect(stored!.entries.map((e) => e.id), ['verify', 'dev-home']);
  });

  test('duplicateEntry inserts a copy right after the source', () async {
    final copy = await c.duplicateEntry('dash');
    expect(c.entries.map((e) => e.id), [
      'dash',
      copy!.id,
      'verify',
      'dev-home',
    ]);
    expect(copy.name, 'Dashboard (copy)');
    expect(copy.url, c.entryById('dash')!.url);
    expect(copy.envId, 'stg');
  });

  test('saveEnv overrides a config env label; removeEnv reverts it', () async {
    await c.saveEnv(const DeeplinkEnv(id: 'stg', label: 'STAGING'));
    expect(c.selectedEnv!.label, 'STAGING');
    await c.removeEnv('stg');
    expect(c.selectedEnv!.label, 'STG');
  });

  test('custom env with deeplinks cannot be removed; empty one can', () async {
    await c.saveEnv(const DeeplinkEnv(id: 'uct', label: 'UCT'));
    await c.addEntry(envId: 'uct', name: 'u', url: 'myapp://uct');
    expect(c.removeEnvBlocker('uct'), contains('1 deeplink'));
    await c.removeEnv('uct');
    expect(c.envById('uct'), isNotNull);

    await c.removeEntry(
      c.filteredEntries('').isEmpty
          ? c.entries.firstWhere((e) => e.envId == 'uct').id
          : c.entries.firstWhere((e) => e.envId == 'uct').id,
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await c.selectEnv('uct');
    await c.removeEnv('uct');
    expect(c.envById('uct'), isNull);
    expect(c.selectedEnvId, 'dev');
  });

  test('validateEntry and validateEnv reject bad input', () {
    expect(c.validateEntry(envId: '', name: 'n', url: 'u://x'), isNotNull);
    expect(c.validateEntry(envId: 'dev', name: ' ', url: 'u://x'), isNotNull);
    expect(c.validateEntry(envId: 'dev', name: 'n', url: ''), isNotNull);
    expect(
      c.validateEntry(envId: 'dev', name: 'n', url: 'myapp://x?a=1'),
      isNull,
    );
    expect(c.validateEnv(id: 'bad id', label: 'l'), isNotNull);
    expect(c.validateEnv(id: 'ok-1', label: ''), isNotNull);
    expect(c.validateEnv(id: 'ok-1', label: 'L'), isNull);
  });

  test('importFromFile merges by id and persists immediately', () async {
    transfer.nextPick = '''
{"entries":[{"id":"dash","envId":"stg","name":"Dash v2","url":"t"},
            {"id":"new","envId":"uct","name":"New","url":"n"}],
 "envs":[{"id":"uct","label":"UCT"}]}''';
    final msg = await c.importFromFile();
    expect(msg, contains('2 deeplinks'));
    expect(c.entryById('dash')!.name, 'Dash v2');
    expect(c.entryById('new'), isNotNull);
    expect(c.envs.map((e) => e.id), ['dev', 'stg', 'uct']);
    final stored = await storage.load();
    expect(stored!.entries, hasLength(4));
  });

  test('import accepts legacy "template" field as url', () async {
    await c.importFromJson(
      '{"entries":[{"id":"old","envId":"dev","name":"Old","template":"myapp://old"}]}',
    );
    expect(c.entryById('old')!.url, 'myapp://old');
  });

  test('importFromJson rejects malformed content', () async {
    expect(await c.importFromJson('nope'), 'Invalid profile file');
  });

  test('exportToShare writes a copy and shares it', () async {
    await c.addEntry(envId: 'stg', name: 'x', url: 'myapp://y');
    await c.exportToShare();
    expect(transfer.shared, isNotNull);
    final exported = DeeplinkProfileStorage.parse(
      await transfer.shared!.readAsString(),
    );
    expect(exported!.entries.map((e) => e.name), contains('x'));
  });

  test('exportToDevice hands the profile json to the save dialog', () async {
    transfer.savePath = '/sdcard/Download/deeplink_profiles.json';
    await c.addEntry(envId: 'stg', name: 'x', url: 'myapp://y');
    final msg = await c.exportToDevice();
    expect(msg, 'Saved to /sdcard/Download/deeplink_profiles.json');
    expect(transfer.savedName, endsWith('.json'));
    final saved = DeeplinkProfileStorage.parse(
      String.fromCharCodes(transfer.savedBytes!),
    );
    expect(saved!.entries.map((e) => e.name), contains('x'));

    transfer.savePath = null;
    expect(await c.exportToDevice(), 'Save cancelled');
  });

  test('resetToDefaults restores the bundled profile', () async {
    await c.addEntry(envId: 'stg', name: 'x', url: 'myapp://y');
    await c.resetToDefaults();
    expect(c.entries.map((e) => e.id), ['dash', 'verify', 'dev-home']);
  });

  test('callback mode is available only when onDeeplink is wired', () async {
    final delivered = <String>[];
    final withCallback = DeeplinkTesterController(
      config: DeeplinkTesterConfig(
        envs: config.envs,
        onDeeplink: (url) async => delivered.add(url),
      ),
      storage: storage,
      prefs: DeeplinkTesterPrefs(),
      transfer: transfer,
      assetLoader: (_) async => bundledJson,
    );
    await withCallback.init();
    expect(withCallback.availableModes, [
      DispatchMode.osLaunch,
      DispatchMode.callback,
    ]);
    expect(withCallback.dispatchMode, DispatchMode.callback);
    await withCallback.sendUrl('myapp://cb');
    expect(delivered, ['myapp://cb']);
    expect(c.availableModes, [DispatchMode.inject, DispatchMode.osLaunch]);
    await withCallback.flush();
    withCallback.dispose();
  });

  test(
    'changed bundled seed is merged on startup, user entries kept',
    () async {
      await c.addEntry(envId: 'stg', name: 'mine', url: 'myapp://mine');
      await c.updateEntry(c.entryById('dash')!.copyWith(name: 'Dash edited'));
      await c.removeEntry('verify');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await c.flush();
      c.dispose();

      // Same seed: nothing re-added, edits kept.
      c = build();
      await c.init();
      expect(c.entryById('verify'), isNull);
      expect(c.entryById('dash')!.name, 'Dash edited');
      expect(c.entries.map((e) => e.name), contains('mine'));
      await c.flush();
      c.dispose();

      // Seed changed in code: seed ids follow the seed, additions stay.
      const seedV2 = '''
{"entries":[
  {"id":"dash","envId":"stg","name":"Dashboard v2","url":"myapp://v2"},
  {"id":"verify","envId":"stg","name":"Verify","url":"myapp://stg/verify/abc"},
  {"id":"brand-new","envId":"dev","name":"Brand new","url":"myapp://new"}]}''';
      c = DeeplinkTesterController(
        config: config,
        storage: storage,
        prefs: DeeplinkTesterPrefs(),
        transfer: transfer,
        dispatchers: {DispatchMode.inject: inject, DispatchMode.osLaunch: os},
        assetLoader: (_) async => seedV2,
      );
      await c.init();
      expect(c.entryById('dash')!.name, 'Dashboard v2');
      expect(c.entryById('verify'), isNotNull);
      expect(c.entryById('brand-new'), isNotNull);
      expect(c.entries.map((e) => e.name), contains('mine'));
      expect(
        (await storage.load())!.entries.map((e) => e.id),
        contains('brand-new'),
      );
    },
  );

  test('syncBundledOnChange=false keeps the stored profile', () async {
    await c.flush();
    c.dispose();
    c = DeeplinkTesterController(
      config: const DeeplinkTesterConfig(
        eventChannelName: 'test/events',
        bundledProfileAsset: 'assets/seed.json',
        syncBundledOnChange: false,
        envs: [DeeplinkEnv(id: 'stg', label: 'STG')],
      ),
      storage: storage,
      prefs: DeeplinkTesterPrefs(),
      transfer: transfer,
      dispatchers: {DispatchMode.inject: inject, DispatchMode.osLaunch: os},
      assetLoader:
          (_) async =>
              '{"entries":[{"id":"x","envId":"stg","name":"X","url":"myapp://x"}]}',
    );
    await c.init();
    expect(c.entryById('x'), isNull);
    expect(c.entryById('dash'), isNotNull);
  });

  test('state survives a restart via storage and prefs', () async {
    await c.addEntry(envId: 'dev', name: 'persist', url: 'myapp://p');
    await c.setIconPreset('bug');
    await c.selectEnv('dev');
    await c.setButtonPosition(
      const DeeplinkButtonPosition(isLeft: true, yFraction: 0.25),
    );
    await c.flush();
    c.dispose();

    c = build();
    await c.init();
    expect(c.entries.map((e) => e.name), contains('persist'));
    expect(c.iconPreset, 'bug');
    expect(c.selectedEnvId, 'dev');
    expect(c.buttonPosition.isLeft, isTrue);
  });
}
