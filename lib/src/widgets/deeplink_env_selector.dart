import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';

/// Horizontal env chips + a "manage" chip.
class DeeplinkEnvSelector extends StatelessWidget {
  final DeeplinkTesterController controller;
  final VoidCallback onManage;

  const DeeplinkEnvSelector({
    super.key,
    required this.controller,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final selectedId = controller.selectedEnvId;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final env in controller.envs)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(env.label),
                selected: env.id == selectedId,
                onSelected: (_) => controller.selectEnv(env.id),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.tune, size: 16),
            label: const Text('Envs'),
            onPressed: onManage,
          ),
        ],
      ),
    );
  }
}
