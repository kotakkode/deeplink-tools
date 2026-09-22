import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';

/// Shown while a removed entry can still be restored.
class DeeplinkUndoBar extends StatelessWidget {
  final DeeplinkTesterController controller;

  const DeeplinkUndoBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.hasPendingRemoval) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.inverseSurface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Removed ${controller.pendingRemovalName}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: controller.undoRemove,
              child: const Text('UNDO'),
            ),
          ],
        ),
      ),
    );
  }
}
