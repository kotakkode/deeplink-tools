import 'package:flutter/material.dart';

import '../config/deeplink_tester_config.dart';
import '../config/deeplink_tester_theme.dart';
import '../controller/deeplink_tester_controller.dart';
import '../deeplink_tester_registry.dart';
import 'deeplink_tester_layer.dart';

/// Wraps the host app and adds the floating tester button on top.
///
/// Place it in `MaterialApp.builder`:
/// ```dart
/// builder: (context, child) => DeeplinkTesterOverlay(
///   config: myConfig,
///   child: child!,
/// ),
/// ```
class DeeplinkTesterOverlay extends StatefulWidget {
  final DeeplinkTesterConfig config;
  final Widget child;

  /// Optional pre-built controller (tests / custom wiring).
  final DeeplinkTesterController? controller;

  const DeeplinkTesterOverlay({
    super.key,
    required this.config,
    required this.child,
    this.controller,
  });

  @override
  State<DeeplinkTesterOverlay> createState() => _DeeplinkTesterOverlayState();
}

class _DeeplinkTesterOverlayState extends State<DeeplinkTesterOverlay> {
  DeeplinkTesterController? _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (!widget.config.enabled) return;
    final controller =
        widget.controller ?? DeeplinkTesterController(config: widget.config);
    _ownsController = widget.controller == null;
    _controller = controller;
    DeeplinkTesterRegistry.attach(controller);
    controller.init();
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      DeeplinkTesterRegistry.detach(controller);
      if (_ownsController) controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) {
                final host = Theme.of(context);
                final theme =
                    widget.config.theme ?? DeeplinkTesterTheme.fromHost(host);
                return Theme(
                  data: theme.toThemeData(host),
                  child: DeeplinkTesterLayer(controller: controller),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
