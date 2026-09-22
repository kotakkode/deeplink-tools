import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import '../model/deeplink_env.dart';

/// List of envs with add / edit / remove.
class DeeplinkEnvManager extends StatelessWidget {
  final DeeplinkTesterController controller;
  final VoidCallback onAdd;
  final ValueChanged<DeeplinkEnv> onEdit;
  final ValueChanged<String> onRemove;

  const DeeplinkEnvManager({
    super.key,
    required this.controller,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text('Environments', style: theme.textTheme.titleSmall),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add env'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final env in controller.envs)
                ListTile(
                  title: Text(env.label),
                  subtitle: Text(
                    '${env.id} · ${controller.entryCountFor(env.id)} deeplink(s)',
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () => onEdit(env),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => onEdit(env),
                      ),
                      IconButton(
                        tooltip:
                            controller.isConfigEnv(env.id)
                                ? 'Revert to config'
                                : 'Remove',
                        icon: Icon(
                          controller.isConfigEnv(env.id)
                              ? Icons.undo
                              : Icons.delete_outline,
                          size: 20,
                        ),
                        onPressed: () => onRemove(env.id),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
