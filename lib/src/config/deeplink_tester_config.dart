import 'package:flutter/widgets.dart';

import '../model/deeplink_env.dart';
import 'deeplink_tester_theme.dart';

/// Host-side configuration for the tester.
class DeeplinkTesterConfig {
  /// When false the overlay renders the host child untouched.
  final bool enabled;

  /// Icon shown in the floating button when no runtime preset is chosen.
  /// Any widget works: `Icon(Icons.link)`, `Image.asset(...)`, `Text('DL')`.
  final Widget? icon;

  /// Colours for the whole tester (button, panel, chips, inputs, toast).
  /// `null` derives them from the host app's theme.
  final DeeplinkTesterTheme? theme;

  /// Environments known to the host. The profile file can override/extend.
  final List<DeeplinkEnv> envs;

  /// Env selected on first launch (falls back to the first env).
  final String? initialEnvId;

  /// Whether the panel may show the env list (the env chips, the "Envs" manage
  /// chip and the env dropdown in the add/edit form).
  ///
  /// When false the tester stays locked to the env selected on first launch
  /// ([initialEnvId]): the deeplink list keeps showing only that env's links
  /// and new deeplinks are created in it, but the user cannot switch, add or
  /// edit envs. Use it for a build pinned to one environment. Provide at
  /// least one env in [envs] when this is false, otherwise no deeplink can
  /// be saved.
  ///
  /// Even when true the env UI stays hidden while there are fewer than two
  /// envs, since there is nothing to choose between; the panel title names the
  /// active env. Note that this also hides the "Envs" manager, so a host that
  /// wants envs to be created in-app should ship at least two.
  final bool showEnvSelector;

  /// Native->Flutter [EventChannel] name your app already listens on for
  /// incoming deeplinks (e.g. `com.example.app/deeplinks`). Enables the
  /// "In-app inject" mode. Leave `null` if your app has no such channel.
  final String? eventChannelName;

  /// Dart handler that receives the resolved URL. Enables the "App callback"
  /// mode: wire it to whatever your app uses to handle links (a router,
  /// app_links stream controller, bloc event, ...).
  final Future<void> Function(String url)? onDeeplink;

  /// Optional asset path of a seed profile (registered in the host pubspec).
  final String? bundledProfileAsset;

  /// When true (default), a changed [bundledProfileAsset] is merged into the
  /// saved profile on startup: entries/envs whose id is in the seed take the
  /// seed's version, everything else the tester added is kept. When false the
  /// seed is only used on first launch or via Reset.
  final bool syncBundledOnChange;

  final double buttonSize;
  final double idleOpacity;
  final double activeOpacity;

  /// Scale of the button while active (1.0 = no growth).
  final double activeScale;

  /// Whether the pulsing ring is shown while active.
  final bool pulseWhenActive;

  /// How long the button stays "active" after a send.
  final Duration activeFlashDuration;

  /// How long a removed entry can be undone.
  final Duration undoWindow;

  final int historyLimit;

  const DeeplinkTesterConfig({
    this.enabled = true,
    this.icon,
    this.theme,
    this.eventChannelName,
    this.onDeeplink,
    this.envs = const [],
    this.initialEnvId,
    this.showEnvSelector = true,
    this.bundledProfileAsset,
    this.syncBundledOnChange = true,
    this.buttonSize = 48,
    this.idleOpacity = 0.3,
    this.activeOpacity = 0.8,
    this.activeScale = 1.12,
    this.pulseWhenActive = true,
    this.activeFlashDuration = const Duration(milliseconds: 1500),
    this.undoWindow = const Duration(seconds: 5),
    this.historyLimit = 20,
  });
}
