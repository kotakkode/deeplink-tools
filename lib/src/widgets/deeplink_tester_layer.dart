import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import 'deeplink_floating_button.dart';
import 'deeplink_panel_host.dart';
import 'deeplink_toast.dart';

/// The tester's own layer: panel, floating button, toast.
class DeeplinkTesterLayer extends StatelessWidget {
  final DeeplinkTesterController controller;

  const DeeplinkTesterLayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: [
            DeeplinkPanelHost(controller: controller),
            DeeplinkFloatingButton(controller: controller),
            DeeplinkToast(message: controller.toastMessage),
          ],
        );
      },
    );
  }
}
