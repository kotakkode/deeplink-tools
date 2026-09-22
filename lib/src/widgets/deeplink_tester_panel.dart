import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import '../model/deeplink_entry.dart';
import '../model/deeplink_env.dart';
import 'deeplink_confirm_view.dart';
import 'deeplink_entry_form.dart';
import 'deeplink_entry_list.dart';
import 'deeplink_env_form.dart';
import 'deeplink_env_manager.dart';
import 'deeplink_history_list.dart';
import 'deeplink_icon_picker.dart';
import 'deeplink_panel_header.dart';
import 'deeplink_panel_page.dart';
import 'deeplink_undo_bar.dart';

/// The bottom panel. Holds only navigation state between its sub-views.
class DeeplinkTesterPanel extends StatefulWidget {
  final DeeplinkTesterController controller;

  const DeeplinkTesterPanel({super.key, required this.controller});

  @override
  State<DeeplinkTesterPanel> createState() => _DeeplinkTesterPanelState();
}

class _DeeplinkTesterPanelState extends State<DeeplinkTesterPanel> {
  DeeplinkPanelPage _page = DeeplinkPanelPage.entries;
  DeeplinkEntry? _editingEntry;
  DeeplinkEnv? _editingEnv;
  String _envToRemove = '';

  DeeplinkTesterController get _controller => widget.controller;

  void _go(DeeplinkPanelPage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            DeeplinkPanelHeader(
              controller: _controller,
              page: _page,
              onClose: _controller.closePanel,
              onBack: () => _go(DeeplinkPanelPage.entries),
              onShowEntries: () => _go(DeeplinkPanelPage.entries),
              onShowHistory: () => _go(DeeplinkPanelPage.history),
              onManageEnvs: () => _go(DeeplinkPanelPage.envManager),
              onPickIcon: () => _go(DeeplinkPanelPage.iconPicker),
              onReset: () => _go(DeeplinkPanelPage.confirmReset),
              onImport: _controller.importFromFile,
              onExport: _controller.exportToShare,
              onSaveToDevice: _controller.exportToDevice,
            ),
            DeeplinkUndoBar(controller: _controller),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_page) {
      case DeeplinkPanelPage.entries:
        return DeeplinkEntryList(
          controller: _controller,
          onSend: _send,
          onAdd: () => _openEntryForm(null),
          onEdit: _openEntryForm,
        );
      case DeeplinkPanelPage.history:
        return DeeplinkHistoryList(controller: _controller);
      case DeeplinkPanelPage.entryForm:
        return DeeplinkEntryForm(
          key: ValueKey(_editingEntry?.id ?? 'new'),
          controller: _controller,
          entry: _editingEntry,
          onDone: () => _go(DeeplinkPanelPage.entries),
        );
      case DeeplinkPanelPage.envManager:
        return DeeplinkEnvManager(
          controller: _controller,
          onAdd: () => _openEnvForm(null),
          onEdit: _openEnvForm,
          onRemove: _askRemoveEnv,
        );
      case DeeplinkPanelPage.envForm:
        return DeeplinkEnvForm(
          key: ValueKey(_editingEnv?.id ?? 'new-env'),
          controller: _controller,
          env: _editingEnv,
          onDone: () => _go(DeeplinkPanelPage.envManager),
        );
      case DeeplinkPanelPage.iconPicker:
        return DeeplinkIconPicker(
          controller: _controller,
          onDone: () => _go(DeeplinkPanelPage.entries),
        );
      case DeeplinkPanelPage.confirmReset:
        return DeeplinkConfirmView(
          title: 'Reset to bundled defaults?',
          message:
              'All deeplinks and envs you added or changed in the app will be replaced by the bundled profile.',
          confirmLabel: 'Reset',
          onCancel: () => _go(DeeplinkPanelPage.entries),
          onConfirm: () async {
            await _controller.resetToDefaults();
            _go(DeeplinkPanelPage.entries);
          },
        );
      case DeeplinkPanelPage.confirmRemoveEnv:
        return DeeplinkConfirmView(
          title: 'Remove env "$_envToRemove"?',
          message:
              _controller.isConfigEnv(_envToRemove)
                  ? 'This env comes from the app config. Your changes will be reverted to the config version.'
                  : 'The env will be removed from the list.',
          confirmLabel: 'Remove',
          onCancel: () => _go(DeeplinkPanelPage.envManager),
          onConfirm: () async {
            await _controller.removeEnv(_envToRemove);
            _go(DeeplinkPanelPage.envManager);
          },
        );
    }
  }

  void _openEntryForm(DeeplinkEntry? entry) {
    setState(() {
      _editingEntry = entry;
      _page = DeeplinkPanelPage.entryForm;
    });
  }

  void _openEnvForm(DeeplinkEnv? env) {
    setState(() {
      _editingEnv = env;
      _page = DeeplinkPanelPage.envForm;
    });
  }

  void _askRemoveEnv(String id) {
    final blocker = _controller.removeEnvBlocker(id);
    if (blocker != null) {
      _controller.showToast(blocker);
      return;
    }
    setState(() {
      _envToRemove = id;
      _page = DeeplinkPanelPage.confirmRemoveEnv;
    });
  }

  Future<void> _send(DeeplinkEntry entry) async {
    final outcome = await _controller.send(entry);
    if (!mounted) return;
    if (outcome.sent) _controller.closePanel();
  }
}
