/// How a deeplink is delivered to the app.
enum DispatchMode {
  /// Push the URL straight onto the native->Flutter event channel.
  inject('inject', 'In-app inject'),

  /// Ask the OS to open the URL (real intent on Android, scheme on iOS).
  osLaunch('os_launch', 'OS launch'),

  /// Hand the URL to [DeeplinkTesterConfig.onDeeplink] in Dart. Use this when
  /// your app resolves links with a package (app_links, go_router, ...).
  callback('callback', 'App callback');

  const DispatchMode(this.key, this.label);

  final String key;
  final String label;

  static DispatchMode fromKey(String? key) {
    return values.firstWhere((m) => m.key == key, orElse: () => inject);
  }
}
