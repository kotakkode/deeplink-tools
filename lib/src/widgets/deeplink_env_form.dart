import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import '../model/deeplink_env.dart';

/// Add / edit an env (id + label).
class DeeplinkEnvForm extends StatefulWidget {
  final DeeplinkTesterController controller;
  final DeeplinkEnv? env;
  final VoidCallback onDone;

  const DeeplinkEnvForm({
    super.key,
    required this.controller,
    required this.env,
    required this.onDone,
  });

  @override
  State<DeeplinkEnvForm> createState() => _DeeplinkEnvFormState();
}

class _DeeplinkEnvFormState extends State<DeeplinkEnvForm> {
  late final TextEditingController _id;
  late final TextEditingController _label;
  String? _error;

  @override
  void initState() {
    super.initState();
    _id = TextEditingController(text: widget.env?.id ?? '');
    _label = TextEditingController(text: widget.env?.label ?? '');
  }

  @override
  void dispose() {
    _id.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          widget.env == null ? 'New env' : 'Edit env',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _id,
          enabled: widget.env == null,
          decoration: const InputDecoration(
            labelText: 'Id *',
            helperText: 'e.g. dev, staging',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _label,
          decoration: const InputDecoration(
            labelText: 'Label *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _error ?? '',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
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
    final error = widget.controller.validateEnv(
      id: _id.text,
      label: _label.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    await widget.controller.saveEnv(
      DeeplinkEnv(id: _id.text.trim(), label: _label.text.trim()),
    );
    widget.onDone();
  }
}
