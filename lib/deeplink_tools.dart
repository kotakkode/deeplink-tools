/// In-app deeplink testing tool.
///
/// Wrap the host app (typically in `MaterialApp.builder`) with
/// [DeeplinkTesterOverlay] and pass a [DeeplinkTesterConfig].
library;

export 'src/config/deeplink_tester_config.dart';
export 'src/config/deeplink_tester_theme.dart';
export 'src/controller/deeplink_tester_controller.dart';
export 'src/controller/send_outcome.dart';
export 'src/core/callback_dispatcher.dart';
export 'src/core/channel_inject_dispatcher.dart';
export 'src/core/deeplink_dispatcher.dart';
export 'src/core/deeplink_icon_presets.dart';
export 'src/core/deeplink_profile_storage.dart';
export 'src/core/dispatch_result.dart';
export 'src/core/os_launch_dispatcher.dart';
export 'src/deeplink_tester_registry.dart';
export 'src/model/deeplink_button_position.dart';
export 'src/model/deeplink_entry.dart';
export 'src/model/deeplink_env.dart';
export 'src/model/deeplink_history_item.dart';
export 'src/model/deeplink_profile.dart';
export 'src/model/dispatch_mode.dart';
export 'src/widgets/deeplink_tester_overlay.dart';
