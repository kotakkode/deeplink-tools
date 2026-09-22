import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/deeplink_tester_config.dart';
import '../core/callback_dispatcher.dart';
import '../core/channel_inject_dispatcher.dart';
import '../core/deeplink_dispatcher.dart';
import '../core/deeplink_id_generator.dart';
import '../core/deeplink_profile_storage.dart';
import '../core/deeplink_profile_transfer.dart';
import '../core/deeplink_tester_prefs.dart';
import '../core/os_launch_dispatcher.dart';
import '../model/deeplink_button_position.dart';
import '../model/deeplink_entry.dart';
import '../model/deeplink_env.dart';
import '../model/deeplink_history_item.dart';
import '../model/deeplink_profile.dart';
import '../model/dispatch_mode.dart';
import 'pending_removal.dart';
import 'send_outcome.dart';

/// All tester state and decisions. Widgets only render getters and call
/// methods; they never decide anything themselves.
class DeeplinkTesterController extends ChangeNotifier {
  final DeeplinkTesterConfig config;
  final DeeplinkProfileStorage _storage;
  final DeeplinkTesterPrefs _prefs;
  final DeeplinkProfileTransfer _transfer;
  final DeeplinkIdGenerator _ids;
  final Map<DispatchMode, DeeplinkDispatcher> _dispatchers;
  final Future<String> Function(String key)? _assetLoader;
  final TargetPlatform _platform;

  DeeplinkTesterController({
    required this.config,
    DeeplinkProfileStorage? storage,
    DeeplinkTesterPrefs? prefs,
    DeeplinkProfileTransfer? transfer,
    DeeplinkIdGenerator? idGenerator,
    Map<DispatchMode, DeeplinkDispatcher>? dispatchers,
    Future<String> Function(String key)? assetLoader,
    TargetPlatform? platform,
  }) : _storage = storage ?? DeeplinkProfileStorage(),
       _prefs = prefs ?? DeeplinkTesterPrefs(),
       _transfer = transfer ?? const DeeplinkProfileTransfer(),
       _ids = idGenerator ?? DeeplinkIdGenerator(),
       _dispatchers = dispatchers ?? _defaultDispatchers(config),
       _assetLoader = assetLoader ?? _defaultAssetLoader,
       _platform = platform ?? defaultTargetPlatform;

  static Map<DispatchMode, DeeplinkDispatcher> _defaultDispatchers(
    DeeplinkTesterConfig config,
  ) {
    final channel = config.eventChannelName;
    final callback = config.onDeeplink;
    return {
      if (channel != null)
        DispatchMode.inject: ChannelInjectDispatcher(channelName: channel),
      if (callback != null) DispatchMode.callback: CallbackDispatcher(callback),
      DispatchMode.osLaunch: OsLaunchDispatcher(),
    };
  }

  static Future<String> _defaultAssetLoader(String key) =>
      rootBundle.loadString(key);

  // ---------------------------------------------------------------- state
  DeeplinkProfile _profile = const DeeplinkProfile.empty();
  DeeplinkProfile _bundled = const DeeplinkProfile.empty();
  String? _selectedEnvId;
  DispatchMode _dispatchMode = DispatchMode.inject;
  bool _panelOpen = false;
  bool _dragging = false;
  bool _flash = false;
  bool _initialized = false;
  DeeplinkButtonPosition _buttonPosition =
      const DeeplinkButtonPosition.initial();
  List<DeeplinkHistoryItem> _history = const [];
  String? _toast;
  PendingRemoval? _pendingRemoval;
  Timer? _toastTimer;
  Timer? _flashTimer;
  Timer? _saveTimer;

  // -------------------------------------------------------------- getters
  bool get isInitialized => _initialized;
  bool get isPanelOpen => _panelOpen;
  bool get isDragging => _dragging;
  bool get isActive => _panelOpen || _dragging || _flash;
  double get buttonOpacity =>
      isActive ? config.activeOpacity : config.idleOpacity;
  DeeplinkButtonPosition get buttonPosition => _buttonPosition;
  DispatchMode get dispatchMode => _dispatchMode;
  String get iconPreset => _profile.iconPreset;
  List<DeeplinkHistoryItem> get history => _history;
  String? get toastMessage => _toast;
  bool get hasPendingRemoval => _pendingRemoval != null;
  String get pendingRemovalName => _pendingRemoval?.entry.name ?? '';
  DeeplinkProfile get profile => _profile;
  bool get hasBundledDefaults =>
      _bundled.entries.isNotEmpty || _bundled.envs.isNotEmpty;

  /// Modes the host wired up (inject needs a channel, callback needs a
  /// handler; OS launch is always there).
  List<DispatchMode> get availableModes =>
      DispatchMode.values.where(_dispatchers.containsKey).toList();

  /// Preferred in-process mode for fallbacks: inject, else callback.
  DispatchMode? get _inProcessMode {
    if (_dispatchers.containsKey(DispatchMode.inject)) {
      return DispatchMode.inject;
    }
    if (_dispatchers.containsKey(DispatchMode.callback)) {
      return DispatchMode.callback;
    }
    return null;
  }

  /// Whether the panel shows any env UI: the env chips, the "Envs" manager and
  /// the env dropdown in the add/edit form.
  ///
  /// False when the host turned it off, and false while there is nothing to
  /// choose between anyway (0 or 1 env) - the panel title already names the
  /// active env. Either way the tester stays locked to the selected env.
  bool get showEnvSelector => config.showEnvSelector && envs.length > 1;

  /// Config envs overridden/extended by profile envs, config order first.
  List<DeeplinkEnv> get envs {
    final result = List<DeeplinkEnv>.of(config.envs);
    for (final env in _profile.envs) {
      final index = result.indexWhere((e) => e.id == env.id);
      if (index >= 0) {
        result[index] = env;
      } else {
        result.add(env);
      }
    }
    return result;
  }

  DeeplinkEnv? get selectedEnv {
    final all = envs;
    if (all.isEmpty) return null;
    return all.firstWhere(
      (e) => e.id == _selectedEnvId,
      orElse: () => all.first,
    );
  }

  String get selectedEnvId => selectedEnv?.id ?? '';

  /// Every saved deeplink, all envs.
  List<DeeplinkEntry> get entries => _profile.entries;

  /// Deeplinks of the selected env, filtered by [query] on name or url.
  List<DeeplinkEntry> filteredEntries(String query) {
    final q = query.trim().toLowerCase();
    final envId = selectedEnvId;
    return entries.where((e) {
      if (e.envId != envId) return false;
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) ||
          e.url.toLowerCase().contains(q);
    }).toList();
  }

  int entryCountFor(String envId) =>
      entries.where((e) => e.envId == envId).length;

  DeeplinkEntry? entryById(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  DeeplinkEnv? envById(String id) {
    for (final e in envs) {
      if (e.id == id) return e;
    }
    return null;
  }

  String envLabel(String id) => envById(id)?.label ?? id;

  /// Whether [id] comes from the host config (cannot be fully deleted, only
  /// reverted to the config version).
  bool isConfigEnv(String id) => config.envs.any((e) => e.id == id);

  // ----------------------------------------------------------------- init
  Future<void> init() async {
    if (_initialized) return;
    final asset = config.bundledProfileAsset;
    String? bundledHash;
    if (asset != null && _assetLoader != null) {
      try {
        final text = await _assetLoader(asset);
        _bundled =
            DeeplinkProfileStorage.parse(text) ?? const DeeplinkProfile.empty();
        bundledHash = _fnv1a(text);
      } catch (_) {
        _bundled = const DeeplinkProfile.empty();
      }
    }
    final stored = await _storage.load();
    if (stored == null) {
      _profile = _bundled;
      if (hasBundledDefaults) await _storage.save(_profile);
    } else if (config.syncBundledOnChange &&
        bundledHash != null &&
        bundledHash != await _prefs.loadBundledHash()) {
      // Seed changed in code: seed wins for its own ids, tester additions stay.
      _profile = stored.mergeWith(_bundled);
      await _storage.save(_profile);
    } else {
      _profile = stored;
    }
    if (bundledHash != null) await _prefs.saveBundledHash(bundledHash);
    _buttonPosition =
        await _prefs.loadPosition() ?? const DeeplinkButtonPosition.initial();
    _dispatchMode = await _prefs.loadDispatchMode();
    if (!_dispatchers.containsKey(_dispatchMode)) {
      _dispatchMode = _inProcessMode ?? availableModes.first;
    }
    _history = await _prefs.loadHistory();
    final storedEnv = await _prefs.loadSelectedEnv();
    _selectedEnvId = storedEnv ?? config.initialEnvId;
    _initialized = true;
    notifyListeners();
  }

  /// Stable 32-bit FNV-1a hash of the seed text (String.hashCode is not
  /// guaranteed stable across runs).
  static String _fnv1a(String text) {
    var hash = 0x811C9DC5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  // --------------------------------------------------------- button/panel
  void openPanel() {
    if (_panelOpen) return;
    _panelOpen = true;
    notifyListeners();
  }

  void closePanel() {
    if (!_panelOpen) return;
    _panelOpen = false;
    notifyListeners();
  }

  void togglePanel() => _panelOpen ? closePanel() : openPanel();

  void setDragging(bool dragging) {
    if (_dragging == dragging) return;
    _dragging = dragging;
    notifyListeners();
  }

  Future<void> setButtonPosition(DeeplinkButtonPosition position) async {
    _buttonPosition = position;
    notifyListeners();
    await _prefs.savePosition(position);
  }

  Future<void> selectEnv(String id) async {
    _selectedEnvId = id;
    notifyListeners();
    await _prefs.saveSelectedEnv(id);
  }

  Future<void> setDispatchMode(DispatchMode mode) async {
    _dispatchMode = mode;
    notifyListeners();
    await _prefs.saveDispatchMode(mode);
  }

  void showToast(String message) {
    _toast = message;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 3), () {
      _toast = null;
      notifyListeners();
    });
    notifyListeners();
  }

  // ----------------------------------------------------------------- send
  /// Sends the entry's URL exactly as saved.
  Future<SendOutcome> send(DeeplinkEntry entry) {
    return _dispatch(
      url: entry.url,
      entryId: entry.id,
      name: entry.name,
      envLabel: envLabel(entry.envId),
    );
  }

  Future<SendOutcome> sendById(String entryId) async {
    final entry = entryById(entryId);
    if (entry == null) return SendOutcome.failure('Unknown entry: $entryId');
    return send(entry);
  }

  Future<SendOutcome> sendUrl(String url, {String name = 'Custom URL'}) {
    return _dispatch(
      url: url,
      entryId: '',
      name: name,
      envLabel: selectedEnv?.label ?? '',
    );
  }

  Future<SendOutcome> resendHistory(DeeplinkHistoryItem item) {
    return _dispatch(
      url: item.url,
      entryId: item.entryId,
      name: item.name,
      envLabel: item.envLabel,
    );
  }

  Future<SendOutcome> resendLast() async {
    if (_history.isEmpty) return const SendOutcome.failure('Nothing sent yet');
    return resendHistory(_history.first);
  }

  Future<SendOutcome> _dispatch({
    required String url,
    required String entryId,
    required String name,
    required String envLabel,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      showToast('Deeplink is empty');
      return const SendOutcome.failure('Deeplink is empty');
    }
    var mode = _dispatchMode;
    var note = '';
    final fallback = _inProcessMode;
    if (mode == DispatchMode.osLaunch &&
        _isUniversalLinkOnIos(trimmed) &&
        fallback != null) {
      mode = fallback;
      note = ' (iOS cannot self-open https links, used ${fallback.label})';
    }
    final dispatcher = _dispatchers[mode];
    if (dispatcher == null) {
      return SendOutcome.failure('No dispatcher for ${mode.label}', url: url);
    }
    final result = await dispatcher.dispatch(trimmed);
    if (!result.ok) {
      showToast(result.message);
      return SendOutcome.failure(result.message, url: trimmed);
    }
    await _recordHistory(
      DeeplinkHistoryItem(
        entryId: entryId,
        name: name,
        envLabel: envLabel,
        url: trimmed,
        sentAt: DateTime.now(),
      ),
    );
    _flashActive();
    final message =
        'Sent $name'
        '${envLabel.isEmpty ? '' : ' ($envLabel)'}$note';
    showToast(message);
    return SendOutcome.success(message, trimmed);
  }

  bool _isUniversalLinkOnIos(String url) {
    if (_platform != TargetPlatform.iOS) return false;
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  void _flashActive() {
    _flash = true;
    _flashTimer?.cancel();
    _flashTimer = Timer(config.activeFlashDuration, () {
      _flash = false;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _recordHistory(DeeplinkHistoryItem item) async {
    _history = [item, ..._history].take(config.historyLimit).toList();
    notifyListeners();
    await _prefs.saveHistory(_history);
  }

  Future<void> clearHistory() async {
    _history = const [];
    notifyListeners();
    await _prefs.saveHistory(_history);
  }

  // -------------------------------------------------------- entries CRUD
  /// Returns an error message, or `null` when the input is valid.
  String? validateEntry({
    required String envId,
    required String name,
    required String url,
  }) {
    if (envId.trim().isEmpty) return 'Env is required';
    if (name.trim().isEmpty) return 'Name is required';
    if (url.trim().isEmpty) return 'Deeplink is required';
    if (Uri.tryParse(url.trim()) == null) return 'Deeplink is not a valid URL';
    return null;
  }

  Future<DeeplinkEntry> addEntry({
    required String envId,
    required String name,
    required String url,
  }) async {
    final entry = DeeplinkEntry(
      id: _uniqueId(name),
      envId: envId.trim(),
      name: name.trim(),
      url: url.trim(),
    );
    _setEntries([...entries, entry]);
    showToast('Added ${entry.name}');
    return entry;
  }

  Future<void> updateEntry(DeeplinkEntry entry) async {
    final list = List<DeeplinkEntry>.of(entries);
    final index = list.indexWhere((e) => e.id == entry.id);
    final clean = entry.copyWith(
      envId: entry.envId.trim(),
      name: entry.name.trim(),
      url: entry.url.trim(),
    );
    if (index < 0) {
      list.add(clean);
    } else {
      list[index] = clean;
    }
    _setEntries(list);
    showToast('Saved ${clean.name}');
  }

  Future<DeeplinkEntry?> duplicateEntry(String id) async {
    final source = entryById(id);
    if (source == null) return null;
    final copy = source.copyWith(
      id: _uniqueId(source.name),
      name: '${source.name} (copy)',
    );
    final list = List<DeeplinkEntry>.of(entries);
    final index = list.indexWhere((e) => e.id == id);
    list.insert(index + 1, copy);
    _setEntries(list);
    showToast('Duplicated ${source.name}');
    return copy;
  }

  /// Soft-removes [id]; restorable with [undoRemove] during the undo window.
  Future<void> removeEntry(String id) async {
    _commitPendingRemoval();
    final list = List<DeeplinkEntry>.of(entries);
    final index = list.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final removed = list.removeAt(index);
    _pendingRemoval = PendingRemoval(
      entry: removed,
      index: index,
      timer: Timer(config.undoWindow, _commitPendingRemoval),
    );
    _profile = _profile.copyWith(entries: list);
    notifyListeners();
  }

  void undoRemove() {
    final pending = _pendingRemoval;
    if (pending == null) return;
    pending.timer.cancel();
    _pendingRemoval = null;
    final list = List<DeeplinkEntry>.of(entries);
    final index = pending.index.clamp(0, list.length);
    list.insert(index, pending.entry);
    _profile = _profile.copyWith(entries: list);
    notifyListeners();
    showToast('Restored ${pending.entry.name}');
  }

  void _commitPendingRemoval() {
    final pending = _pendingRemoval;
    if (pending == null) return;
    pending.timer.cancel();
    _pendingRemoval = null;
    _scheduleSave();
    notifyListeners();
  }

  void _setEntries(List<DeeplinkEntry> list) {
    _profile = _profile.copyWith(entries: list);
    _scheduleSave();
    notifyListeners();
  }

  String _uniqueId(String name) {
    var id = _ids.generate(name);
    while (entryById(id) != null) {
      id = _ids.generate(name);
    }
    return id;
  }

  // ------------------------------------------------------------ envs CRUD
  String? validateEnv({required String id, required String label}) {
    if (id.trim().isEmpty) return 'Id is required';
    if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(id.trim())) {
      return 'Id may only contain letters, digits, - and _';
    }
    if (label.trim().isEmpty) return 'Label is required';
    return null;
  }

  Future<void> saveEnv(DeeplinkEnv env) async {
    final clean = env.copyWith(id: env.id.trim(), label: env.label.trim());
    final list = List<DeeplinkEnv>.of(_profile.envs);
    final index = list.indexWhere((e) => e.id == clean.id);
    if (index < 0) {
      list.add(clean);
    } else {
      list[index] = clean;
    }
    _profile = _profile.copyWith(envs: list);
    _scheduleSave();
    notifyListeners();
    showToast('Saved env ${clean.label}');
  }

  /// Why [id] cannot be removed right now, or `null` when it can.
  String? removeEnvBlocker(String id) {
    if (isConfigEnv(id)) return null;
    final count = entryCountFor(id);
    if (count > 0) return 'Delete or move its $count deeplink(s) first';
    return null;
  }

  /// Removes a profile env. A config env is reverted to its config version.
  Future<void> removeEnv(String id) async {
    final blocker = removeEnvBlocker(id);
    if (blocker != null) {
      showToast(blocker);
      return;
    }
    final list = List<DeeplinkEnv>.of(_profile.envs)
      ..removeWhere((e) => e.id == id);
    _profile = _profile.copyWith(envs: list);
    if (_selectedEnvId == id && !isConfigEnv(id)) {
      _selectedEnvId = envs.isEmpty ? null : envs.first.id;
      if (_selectedEnvId != null) await _prefs.saveSelectedEnv(_selectedEnvId!);
    }
    _scheduleSave();
    notifyListeners();
    showToast(isConfigEnv(id) ? 'Reverted env $id' : 'Removed env $id');
  }

  // ----------------------------------------------------------------- icon
  Future<void> setIconPreset(String key) async {
    _profile = _profile.copyWith(iconPreset: key);
    _scheduleSave();
    notifyListeners();
  }

  // --------------------------------------------------------- profile file
  Future<void> resetToDefaults() async {
    _commitPendingRemoval();
    _profile = _bundled;
    await _storage.save(_profile);
    notifyListeners();
    showToast('Reset to bundled defaults');
  }

  /// Opens the file picker and merges the chosen profile. Returns a message.
  Future<String> importFromFile() async {
    final text = await _transfer.pickJsonText();
    if (text == null) return 'Import cancelled';
    return importFromJson(text);
  }

  Future<String> importFromJson(String text) async {
    final incoming = DeeplinkProfileStorage.parse(text);
    if (incoming == null) {
      showToast('Invalid profile file');
      return 'Invalid profile file';
    }
    _commitPendingRemoval();
    _profile = _profile.mergeWith(incoming);
    await _storage.save(_profile);
    notifyListeners();
    final message =
        'Imported ${incoming.entries.length} deeplinks, ${incoming.envs.length} envs';
    showToast(message);
    return message;
  }

  /// Saves the profile through the system save dialog (Downloads etc.).
  Future<String> exportToDevice() async {
    _commitPendingRemoval();
    await _storage.save(_profile);
    final bytes = Uint8List.fromList(utf8.encode(_profile.toPrettyJson()));
    final path = await _transfer.saveToDevice(
      DeeplinkProfileStorage.exportFileName(),
      bytes,
    );
    if (path == null) return 'Save cancelled';
    final message = 'Saved to $path';
    showToast(message);
    return message;
  }

  Future<String> exportToShare() async {
    _commitPendingRemoval();
    await _storage.save(_profile);
    final file = await _storage.writeExportCopy(_profile);
    await _transfer.share(file);
    return 'Exported ${file.path}';
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    showToast('Copied to clipboard');
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () {
      _storage.save(_profile);
    });
  }

  /// Flush any debounced save immediately (tests, dispose).
  Future<void> flush() async {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      await _storage.save(_profile);
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _flashTimer?.cancel();
    _pendingRemoval?.timer.cancel();
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      _storage.save(_profile);
    }
    super.dispose();
  }
}
