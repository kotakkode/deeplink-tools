import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../model/deeplink_profile.dart';

/// Reads and writes the profile JSON file in the app documents directory.
class DeeplinkProfileStorage {
  final Future<Directory> Function() directoryProvider;
  final String fileName;

  DeeplinkProfileStorage({
    Future<Directory> Function()? directoryProvider,
    this.fileName = 'deeplink_profiles.json',
  }) : directoryProvider =
           directoryProvider ?? getApplicationDocumentsDirectory;

  Future<File> file() async {
    final dir = await directoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  /// Returns `null` when the file is absent or unreadable.
  Future<DeeplinkProfile?> load() async {
    try {
      final f = await file();
      if (!await f.exists()) return null;
      return parse(await f.readAsString());
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DeeplinkProfile profile) async {
    final f = await file();
    await f.parent.create(recursive: true);
    await f.writeAsString(profile.toPrettyJson(), flush: true);
  }

  Future<void> delete() async {
    final f = await file();
    if (await f.exists()) await f.delete();
  }

  /// `deeplink_profiles_<timestamp>.json`
  static String exportFileName() {
    final stamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    return 'deeplink_profiles_$stamp.json';
  }

  /// Writes a timestamped copy next to the profile file for sharing.
  Future<File> writeExportCopy(DeeplinkProfile profile) async {
    final dir = await directoryProvider();
    final f = File('${dir.path}${Platform.pathSeparator}${exportFileName()}');
    await f.writeAsString(profile.toPrettyJson(), flush: true);
    return f;
  }

  /// Parses JSON text. Returns `null` on malformed content.
  static DeeplinkProfile? parse(String source) {
    try {
      return DeeplinkProfile.fromJson(source);
    } catch (_) {
      return null;
    }
  }
}
