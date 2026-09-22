import 'dart:io';

import 'package:deeplink_tools/deeplink_tools.dart';
import 'package:deeplink_tools/src/core/deeplink_tester_prefs.dart';
import 'package:deeplink_tools/src/widgets/deeplink_entry_form.dart';
import 'package:deeplink_tools/src/widgets/deeplink_env_selector.dart';
import 'package:deeplink_tools/src/widgets/deeplink_floating_button.dart';
import 'package:deeplink_tools/src/widgets/deeplink_pulse_ring.dart';
import 'package:deeplink_tools/src/widgets/deeplink_tester_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoopDispatcher implements DeeplinkDispatcher {
  @override
  Future<DispatchResult> dispatch(String url) async =>
      const DispatchResult.success('ok');
}

void main() {
  late Directory dir;
  late DeeplinkTesterController controller;

  // Pulse off so pumpAndSettle can settle while the panel is open.
  const config = DeeplinkTesterConfig(
    eventChannelName: 'test/events',
    icon: Icon(Icons.bug_report),
    envs: [DeeplinkEnv(id: 'dev', label: 'DEV')],
    pulseWhenActive: false,
  );
  const pulseConfig = DeeplinkTesterConfig(
    eventChannelName: 'test/events',
    icon: Icon(Icons.bug_report),
    envs: [DeeplinkEnv(id: 'dev', label: 'DEV')],
  );

  DeeplinkTesterController buildController(DeeplinkTesterConfig cfg) {
    return DeeplinkTesterController(
      config: cfg,
      storage: DeeplinkProfileStorage(directoryProvider: () async => dir),
      prefs: DeeplinkTesterPrefs(),
      dispatchers: {
        DispatchMode.inject: NoopDispatcher(),
        DispatchMode.osLaunch: NoopDispatcher(),
      },
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('deeplink_widget_');
    controller = buildController(config);
  });

  tearDown(() async {
    await controller.flush();
    controller.dispose();
    await dir.delete(recursive: true);
  });

  Widget app({DeeplinkTesterConfig cfg = config}) {
    return MaterialApp(
      builder:
          (context, child) => DeeplinkTesterOverlay(
            config: cfg,
            controller: controller,
            child: child!,
          ),
      home: const Scaffold(body: Text('host')),
    );
  }

  double opacityOf(WidgetTester tester) {
    return tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byIcon(Icons.bug_report),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
  }

  testWidgets('button idles at 0.3 and goes to 0.8 when panel opens', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('host'), findsOneWidget);
    expect(opacityOf(tester), 0.3);

    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pumpAndSettle();
    expect(opacityOf(tester), 0.8);
    expect(find.text('Current Active Env : DEV'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(opacityOf(tester), 0.3);
    expect(find.text('Current Active Env : DEV'), findsNothing);
  });

  double scaleOf(WidgetTester tester) {
    return tester
        .widget<AnimatedScale>(
          find.ancestor(
            of: find.byIcon(Icons.bug_report),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;
  }

  testWidgets('button scales up and pulses while active, rests when idle', (
    tester,
  ) async {
    await controller.flush();
    controller.dispose();
    controller = buildController(pulseConfig);
    await tester.pumpWidget(app(cfg: pulseConfig));
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1.0);
    expect(find.byType(DeeplinkPulseRing), findsNothing);

    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(scaleOf(tester), pulseConfig.activeScale);
    expect(find.byType(DeeplinkPulseRing), findsOneWidget);
    double ringScale() =>
        tester
            .widget<Transform>(
              find.descendant(
                of: find.byType(DeeplinkPulseRing),
                matching: find.byType(Transform),
              ),
            )
            .transform
            .getMaxScaleOnAxis();
    final ringBefore = ringScale();
    await tester.pump(const Duration(milliseconds: 400));
    expect(ringScale(), greaterThan(ringBefore));

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(scaleOf(tester), 1.0);
    expect(find.byType(DeeplinkPulseRing), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('button can be dragged, snaps to an edge and persists', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final start = tester.getCenter(find.byIcon(Icons.bug_report));
    expect(controller.buttonPosition.isLeft, isFalse);

    // Drag towards the top-left corner.
    await tester.drag(
      find.byIcon(Icons.bug_report),
      Offset(-start.dx + 30, -start.dy + 30),
    );
    await tester.pumpAndSettle();

    final end = tester.getCenter(find.byIcon(Icons.bug_report));
    expect(end.dx, lessThan(start.dx));
    expect(end.dy, lessThan(start.dy));
    expect(controller.buttonPosition.isLeft, isTrue);
    expect(controller.buttonPosition.yFraction, lessThan(0.2));
    expect(find.text('Current Active Env : DEV'), findsNothing); // drag is not a tap

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('deeplink_tester.button_pos'), contains('true'));
  });

  testWidgets('theme colours apply to button, icon and panel', (tester) async {
    await controller.flush();
    controller.dispose();
    const coloured = DeeplinkTesterConfig(
      eventChannelName: 'test/events',
      icon: Icon(Icons.bug_report),
      theme: DeeplinkTesterTheme(
        primaryColor: Colors.orange,
        secondaryColor: Colors.white,
        textColor: Colors.black,
      ),
      envs: [DeeplinkEnv(id: 'dev', label: 'DEV')],
      pulseWhenActive: false,
    );
    controller = buildController(coloured);
    await tester.pumpWidget(app(cfg: coloured));
    await tester.pumpAndSettle();

    final model = tester.widget<AnimatedPhysicalModel>(
      find
          .descendant(
            of: find.byType(DeeplinkFloatingButton),
            matching: find.byType(AnimatedPhysicalModel),
          )
          .first,
    );
    expect(model.color, Colors.orange);
    final iconTheme = tester.widget<IconTheme>(
      find
          .ancestor(
            of: find.byIcon(Icons.bug_report),
            matching: find.byType(IconTheme),
          )
          .first,
    );
    expect(iconTheme.data.color, Colors.black);

    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pumpAndSettle();
    final panel = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(DeeplinkTesterPanel),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(panel.color, Colors.white);
    final panelTheme = Theme.of(
      tester.element(find.byType(DeeplinkTesterPanel)),
    );
    expect(panelTheme.colorScheme.primary, Colors.orange);
    expect(panelTheme.colorScheme.surface, Colors.white);
    expect(
      panelTheme.filledButtonTheme.style?.backgroundColor?.resolve({}),
      Colors.orange,
    );
    expect(
      panelTheme.filledButtonTheme.style?.foregroundColor?.resolve({}),
      Colors.black,
    );
  });

  testWidgets('disabled config renders host child untouched', (tester) async {
    await tester.pumpWidget(
      app(
        cfg: const DeeplinkTesterConfig(
          eventChannelName: 'test/events',
          enabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DeeplinkTesterOverlay), findsOneWidget);
    expect(find.byIcon(Icons.bug_report), findsNothing);
    expect(find.byType(AnimatedOpacity), findsNothing);
  });

  testWidgets('add entry on the fly appears in the list', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name *'), 'Home');
    await tester.enterText(
      find.widgetWithText(TextField, 'Deeplink *'),
      'myapp://x/home',
    );
    await tester.scrollUntilVisible(
      find.text('Save'),
      200,
      scrollable:
          find
              .descendant(
                of: find.byType(DeeplinkEntryForm),
                matching: find.byType(Scrollable),
              )
              .first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(controller.entries.single.url, 'myapp://x/home');
    expect(controller.entries.single.envId, 'dev');

    // Let the toast and debounced save timers finish.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('showEnvSelector: false hides the env UI and locks the env', (
    tester,
  ) async {
    await controller.flush();
    controller.dispose();
    const locked = DeeplinkTesterConfig(
      eventChannelName: 'test/events',
      icon: Icon(Icons.bug_report),
      envs: [
        DeeplinkEnv(id: 'dev', label: 'DEV'),
        DeeplinkEnv(id: 'prod', label: 'PROD'),
      ],
      initialEnvId: 'dev',
      showEnvSelector: false,
      pulseWhenActive: false,
    );
    controller = buildController(locked);
    await tester.pumpWidget(app(cfg: locked));
    await tester.pumpAndSettle();

    await controller.addEntry(
      envId: 'dev',
      name: 'Dev home',
      url: 'myapp://dev/home',
    );
    await controller.addEntry(
      envId: 'prod',
      name: 'Prod home',
      url: 'myapp://prod/home',
    );

    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pumpAndSettle();

    // No env chips, no "Envs" manage chip.
    expect(find.byType(DeeplinkEnvSelector), findsNothing);
    expect(find.text('DEV'), findsNothing);
    expect(find.text('PROD'), findsNothing);
    expect(find.text('Envs'), findsNothing);

    // The list still shows only the locked env.
    expect(find.text('Dev home'), findsOneWidget);
    expect(find.text('Prod home'), findsNothing);

    // The form drops the env dropdown and still saves into the locked env.
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('env-dropdown')), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Name *'), 'Promo');
    await tester.enterText(
      find.widgetWithText(TextField, 'Deeplink *'),
      'myapp://dev/promo',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final added = controller.entries.firstWhere((e) => e.name == 'Promo');
    expect(added.envId, 'dev');
    expect(find.text('Promo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a lone env hides the env UI without any config', (tester) async {
    // `config` has exactly one env and leaves showEnvSelector at its default.
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pumpAndSettle();

    expect(find.byType(DeeplinkEnvSelector), findsNothing);
    expect(find.text('Envs'), findsNothing);
    // The title still tells you which env you are in.
    expect(find.text('Current Active Env : DEV'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('env-dropdown')), findsNothing);
  });

  testWidgets('two envs bring the env UI back', (tester) async {
    await controller.flush();
    controller.dispose();
    const twoEnvs = DeeplinkTesterConfig(
      eventChannelName: 'test/events',
      icon: Icon(Icons.bug_report),
      envs: [
        DeeplinkEnv(id: 'dev', label: 'DEV'),
        DeeplinkEnv(id: 'prod', label: 'PROD'),
      ],
      initialEnvId: 'dev',
      pulseWhenActive: false,
    );
    controller = buildController(twoEnvs);
    await tester.pumpWidget(app(cfg: twoEnvs));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pumpAndSettle();

    expect(find.byType(DeeplinkEnvSelector), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'PROD'), findsOneWidget);
    expect(find.text('Envs'), findsOneWidget);
    expect(find.text('Current Active Env : DEV'), findsOneWidget);

    // Switching env retitles the panel.
    await tester.tap(find.widgetWithText(ChoiceChip, 'PROD'));
    await tester.pumpAndSettle();
    expect(find.text('Current Active Env : PROD'), findsOneWidget);
  });
}
