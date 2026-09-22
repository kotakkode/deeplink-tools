import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import '../model/deeplink_entry.dart';
import 'deeplink_entry_tile.dart';

/// Deeplinks of the selected env, searchable, with an add button.
class DeeplinkEntryList extends StatefulWidget {
  final DeeplinkTesterController controller;
  final ValueChanged<DeeplinkEntry> onSend;
  final ValueChanged<DeeplinkEntry> onEdit;
  final VoidCallback onAdd;

  const DeeplinkEntryList({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  State<DeeplinkEntryList> createState() => _DeeplinkEntryListState();
}

class _DeeplinkEntryListState extends State<DeeplinkEntryList> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.filteredEntries(_search.text);
    final envLabel = widget.controller.selectedEnv?.label ?? '';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search name or deeplink',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              items.isEmpty
                  ? Center(
                    child: Text(
                      'No deeplinks for $envLabel yet.\nTap Add or import a profile.',
                      textAlign: TextAlign.center,
                    ),
                  )
                  : ListView(
                    children: [
                      for (final entry in items)
                        DeeplinkEntryTile(
                          key: ValueKey(entry.id),
                          entry: entry,
                          onSend: () => widget.onSend(entry),
                          onEdit: () => widget.onEdit(entry),
                          onDuplicate:
                              () => widget.controller.duplicateEntry(entry.id),
                          onRemove:
                              () => widget.controller.removeEntry(entry.id),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
        ),
      ],
    );
  }
}
