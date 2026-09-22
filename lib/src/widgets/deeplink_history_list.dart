import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';

/// Recently sent links. Tap to resend, long press to copy.
class DeeplinkHistoryList extends StatelessWidget {
  final DeeplinkTesterController controller;

  const DeeplinkHistoryList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = controller.history;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text('History', style: theme.textTheme.titleSmall),
              ),
              TextButton(
                onPressed: items.isEmpty ? null : controller.clearHistory,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              items.isEmpty
                  ? const Center(child: Text('Nothing sent yet.'))
                  : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.replay),
                        title: Text('${item.name} · ${item.envLabel}'),
                        subtitle: Text(
                          item.url,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          TimeOfDay.fromDateTime(item.sentAt).format(context),
                          style: theme.textTheme.labelSmall,
                        ),
                        onTap: () => controller.resendHistory(item),
                        onLongPress: () => controller.copyToClipboard(item.url),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
