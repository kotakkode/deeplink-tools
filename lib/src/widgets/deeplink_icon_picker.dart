import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import '../core/deeplink_icon_presets.dart';

/// Grid of preset icons for the floating button.
class DeeplinkIconPicker extends StatelessWidget {
  final DeeplinkTesterController controller;
  final VoidCallback onDone;

  const DeeplinkIconPicker({
    super.key,
    required this.controller,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = controller.iconPreset;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text('Button icon', style: theme.textTheme.titleSmall),
              ),
              TextButton(
                onPressed: () => controller.setIconPreset(''),
                child: const Text('Use app default'),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final entry in DeeplinkIconPresets.icons.entries)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => controller.setIconPreset(entry.key),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color:
                          entry.key == current
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(entry.value, size: 28),
                        const SizedBox(height: 4),
                        Text(entry.key, style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(onPressed: onDone, child: const Text('Done')),
        ),
      ],
    );
  }
}
