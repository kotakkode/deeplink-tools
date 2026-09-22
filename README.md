# deeplink_tools

In-app deeplink testing tool for Flutter. A floating button opens a panel where
you pick an **environment** and a **saved deeplink**; the package then makes
your app behave as if the device had just received that link.

No dependency on your app code. Works with any Flutter app: either push links
onto the native->Flutter `EventChannel` your app already listens on, or hand
them to a Dart callback (router, `app_links` stream, bloc event, ...).

## Features

- **Floating button**: draggable, snaps to the nearest edge. Idle it rests
  at 30% opacity; while active (panel open, dragging, or just after a send) it
  fades to 80%, springs up in scale, lifts its shadow and shows a pulsing ring.
- **Environments**: dev / staging / prod ... passed in from your app and
  editable in-app. Each saved deeplink belongs to one env; the panel shows the
  deeplinks of the selected env and its title reads
  `Current Active Env : DEV`. The env UI hides itself when there is nothing to
  choose between (fewer than two envs), and `showEnvSelector: false` hides it
  for good, locking the tester to one env.
- **Simple entries**: env (dropdown) + name + deeplink URL. Executing sends the
  URL exactly as saved.
- **Three dispatch modes** (only the ones you wire up are shown):
  - *In-app inject* pushes the URL onto your event channel, so your existing
    deeplink handler runs exactly as for a real link. Needs `eventChannelName`.
  - *App callback* calls your `onDeeplink` handler in Dart. Needs `onDeeplink`.
  - *OS launch* asks the OS to open the URL (real intent on Android). Always on.
- **Edit on the fly**: add, edit, duplicate, remove deeplinks and envs, swipe
  to delete with undo.
- **Shareable profiles**: one JSON file, auto-saved on every change. "Save to
  device" opens the system save dialog (Downloads, Files, Drive ...), "Share"
  opens the share sheet, "Import" opens the file picker (merged by id).
  Optional bundled seed asset.
- **Custom icon and theme**: any icon widget from config, or a runtime preset
  from the panel. One `DeeplinkTesterTheme` colours the whole tester:
  `primaryColor` (button, accents), `secondaryColor` (panel surface),
  `textColor` (text on primary), optional `panelTextColor` (text on panel).
- **Prod-safe**: `enabled: false` renders your app untouched.

## Install

```yaml
dependencies:
  deeplink_tools:
    path: ../deeplink_tools   # relative to your project's pubspec.yaml
```

## Usage

Wrap your app in `MaterialApp.builder`:

```dart
import 'package:deeplink_tools/deeplink_tools.dart';

MaterialApp(
  builder: (context, child) => DeeplinkTesterOverlay(
    config: DeeplinkTesterConfig(
      enabled: !kReleaseMode,
      // Pick one or both:
      eventChannelName: 'com.example.app/deeplinks',   // native EventChannel
      onDeeplink: (url) async => myRouter.handle(url), // plain Dart handler
      icon: const Icon(Icons.link),
      theme: const DeeplinkTesterTheme(
        primaryColor: Colors.blueAccent,
        secondaryColor: Colors.white,
        textColor: Colors.white,
      ),
      initialEnvId: 'dev',
      bundledProfileAsset: 'assets/deeplink_profiles.json', // optional
      envs: const [
        DeeplinkEnv(id: 'dev', label: 'DEV'),
        DeeplinkEnv(id: 'staging', label: 'STAGING'),
        DeeplinkEnv(id: 'prod', label: 'PROD'),
      ],
    ),
    child: child!,
  ),
  home: const HomePage(),
);
```

With `eventChannelName`, your app keeps its normal listener and the tester
feeds it:

```dart
const EventChannel('com.example.app/deeplinks')
    .receiveBroadcastStream()
    .listen((link) => handleDeeplink(link as String));
```

With `onDeeplink`, point it at whatever handles links today, for example an
`app_links`-style stream or a GoRouter:

```dart
onDeeplink: (url) async => GoRouter.of(navigatorKey.currentContext!).go(Uri.parse(url).path),
```

Programmatic use (integration tests, VM-service drivers):

```dart
await DeeplinkTesterRegistry.instance.sendById('dev-home');
await DeeplinkTesterRegistry.instance.sendUrl('myapp://dev.example.com/x');
```

See [`example/`](example/) for a runnable app.

## Profile JSON

```json
{
  "version": 1,
  "iconPreset": "bug",
  "envs": [
    { "id": "dev", "label": "DEV" },
    { "id": "prod", "label": "PROD" }
  ],
  "entries": [
    { "id": "dev-verify", "envId": "dev", "name": "Email verification",
      "url": "myapp://dev.example.com/verify/abc123" },
    { "id": "prod-home", "envId": "prod", "name": "Home",
      "url": "https://example.com/home" }
  ]
}
```

- `envId` links a deeplink to an env; the panel lists deeplinks per env.
- Profile envs override config envs with the same id; removing an overridden
  config env reverts it to the config version. A custom env can only be removed
  once it has no deeplinks.
- The bundled seed is loaded on first launch. When the seed file changes in
  code, it is merged on the next startup: ids defined in the seed take the
  seed's version, entries you added in-app are kept (`syncBundledOnChange`).
- Import merges by id (file wins). Save/Share always reflect the current
  in-app state. The working copy lives in the app's private documents folder
  (`deeplink_profiles.json`), which is not visible in the phone's file browser;
  use "Save to device" to put a copy in Downloads.

## Config reference

| Field | Default | Meaning |
|-------|---------|---------|
| `enabled` | `true` | `false` = render child only |
| `eventChannelName` | none | enables in-app inject on that channel |
| `onDeeplink` | none | enables app-callback mode |
| `icon` | `Icons.link` | button icon widget when no runtime preset is set |
| `theme` | derived from host theme | `DeeplinkTesterTheme(primaryColor, secondaryColor, textColor, panelTextColor?)` for button, panel, chips, inputs, toast |
| `envs` | `[]` | host envs |
| `initialEnvId` | first env | env selected on first launch |
| `showEnvSelector` | `true` | `false` hides the env chips, the "Envs" manager and the form's env dropdown, locking the tester to `initialEnvId`. The same UI hides automatically while there are fewer than two envs |
| `bundledProfileAsset` | none | seed profile asset |
| `syncBundledOnChange` | `true` | merge a changed seed into the saved profile on startup |
| `buttonSize` | `48` | dp |
| `idleOpacity` / `activeOpacity` | `0.3` / `0.8` | |
| `activeScale` | `1.12` | button scale while active |
| `pulseWhenActive` | `true` | pulsing ring while active |
| `activeFlashDuration` | `1.5s` | active time after a send |
| `undoWindow` | `5s` | undo time for removals |
| `historyLimit` | `20` | |

## Limits

- Cold-start deeplinks (app launched by a link) are not emulated. Use
  `adb shell am start -a android.intent.action.VIEW -d "<url>"` or
  `xcrun simctl openurl booted "<url>"` for that.
- iOS cannot open its own universal (`https://`) links from inside the app.
  OS-launch mode falls back to inject for those and says so in the toast.
- Inject delivers only once your event-channel listener is registered.

## Development

```
flutter analyze
flutter test
```

## Author

Riky Haryadi Lesmana <zhanza@gmail.com> - <https://github.com/kotakkode>

## License

MIT (c) 2026 Riky Haryadi Lesmana - see [LICENSE](LICENSE).
