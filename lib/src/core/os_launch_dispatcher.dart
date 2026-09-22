import 'package:url_launcher/url_launcher.dart';

import 'deeplink_dispatcher.dart';
import 'dispatch_result.dart';

/// Asks the OS to open the URL. On Android this fires a real VIEW intent that
/// re-enters the app through its intent filters.
class OsLaunchDispatcher implements DeeplinkDispatcher {
  final Future<bool> Function(Uri uri) launcher;

  OsLaunchDispatcher({Future<bool> Function(Uri uri)? launcher})
    : launcher = launcher ?? _defaultLauncher;

  static Future<bool> _defaultLauncher(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<DispatchResult> dispatch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return const DispatchResult.failure('Invalid URL');
    try {
      final launched = await launcher(uri);
      return launched
          ? const DispatchResult.success('Launched via OS')
          : const DispatchResult.failure('OS refused to launch URL');
    } catch (e) {
      return DispatchResult.failure('Launch failed: $e');
    }
  }
}
