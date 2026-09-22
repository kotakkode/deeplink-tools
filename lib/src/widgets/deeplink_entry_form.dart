import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import '../model/deeplink_entry.dart';

/// Add / edit a deeplink: env (dropdown), name (text), deeplink (textarea).
class DeeplinkEntryForm extends StatefulWidget {
  final DeeplinkTesterController controller;
  final DeeplinkEntry? entry;
  final VoidCallback onDone;

  const DeeplinkEntryForm({
    super.key,
    required this.controller,
    required this.entry,
    required this.onDone,
  });

  @override
  State<DeeplinkEntryForm> createState() => _DeeplinkEntryFormState();
}

class _DeeplinkEntryFormState extends State<DeeplinkEntryForm> {
  late final TextEditingController _name;
  late final TextEditingController _url;
  late String _envId;
  String? _error;

  DeeplinkTesterController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _name = TextEditingController(text: e?.name ?? '');
    _url = TextEditingController(text: e?.url ?? '');
    _envId = e?.envId ?? _controller.selectedEnvId;
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          widget.entry == null ? 'New deeplink' : 'Edit deeplink',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        if (_controller.showEnvSelector) ...[
          DropdownMenu<String>(
            key: const ValueKey('env-dropdown'),
            initialSelection: _envId,
            label: const Text('Env *'),
            expandedInsets: EdgeInsets.zero,
            onSelected:
                (id) => setState(() {
                  _envId = id ?? _envId;
                  _error = null;
                }),
            dropdownMenuEntries: [
              for (final env in _controller.envs)
                DropdownMenuEntry(value: env.id, label: env.label),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Name *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          minLines: 4,
          maxLines: 10,
          keyboardType: TextInputType.url,
          style: theme.textTheme.bodyMedium,
          decoration: const InputDecoration(
            labelText: 'Deeplink *',
            hintText: 'https://... or myapp://...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 16),
        Text(_error ?? '', style: TextStyle(color: theme.colorScheme.error)),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onDone,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    final error = _controller.validateEntry(
      envId: _envId,
      name: _name.text,
      url: _url.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final existing = widget.entry;
    if (existing == null) {
      await _controller.addEntry(
        envId: _envId,
        name: _name.text,
        url: _url.text,
      );
    } else {
      await _controller.updateEntry(
        existing.copyWith(envId: _envId, name: _name.text, url: _url.text),
      );
    }
    widget.onDone();
  }
}
