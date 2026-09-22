import 'package:flutter/material.dart';

import '../model/deeplink_entry.dart';

/// One row: tap to send, swipe to remove, inline edit / duplicate buttons.
class DeeplinkEntryTile extends StatelessWidget {
  final DeeplinkEntry entry;
  final VoidCallback onSend;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;

  const DeeplinkEntryTile({
    super.key,
    required this.entry,
    required this.onSend,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey('dismiss-${entry.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      child: ListTile(
        dense: true,
        onTap: onSend,
        leading: const Icon(Icons.send_outlined),
        title: Text(entry.name),
        subtitle: Text(
          entry.url,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Duplicate',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_outlined, size: 20),
              onPressed: onDuplicate,
            ),
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
