import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import 'deeplink_tester_panel.dart';

/// Scrim + bottom panel, present only while the panel is open.
class DeeplinkPanelHost extends StatelessWidget {
  final DeeplinkTesterController controller;

  const DeeplinkPanelHost({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.isPanelOpen) return const SizedBox.shrink();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.closePanel,
              child: Container(color: Colors.black38),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SizedBox(
                height: _panelHeight(context, bottomInset),
                child: DeeplinkTesterPanel(controller: controller),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 85% of the screen, shrunk by the keyboard, never below a usable minimum.
  double _panelHeight(BuildContext context, double bottomInset) {
    final screen = MediaQuery.sizeOf(context).height;
    final available = screen - bottomInset;
    return (screen * 0.85).clamp(240.0, available < 240 ? 240.0 : available);
  }
}
