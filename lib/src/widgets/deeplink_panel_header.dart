import 'package:flutter/material.dart';

import '../controller/deeplink_tester_controller.dart';
import '../model/dispatch_mode.dart';
import 'deeplink_env_selector.dart';
import 'deeplink_panel_page.dart';

/// Title row, env chips, dispatch-mode toggle and profile actions.
class DeeplinkPanelHeader extends StatelessWidget {
  final DeeplinkTesterController controller;
  final DeeplinkPanelPage page;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onShowEntries;
  final VoidCallback onShowHistory;
  final VoidCallback onManageEnvs;
  final VoidCallback onPickIcon;
  final VoidCallback onReset;
  final Future<String> Function() onImport;
  final Future<String> Function() onExport;
  final Future<String> Function() onSaveToDevice;

  const DeeplinkPanelHeader({
    super.key,
    required this.controller,
    required this.page,
    required this.onClose,
    required this.onBack,
    required this.onShowEntries,
    required this.onShowHistory,
    required this.onManageEnvs,
    required this.onPickIcon,
    required this.onReset,
    required this.onImport,
    required this.onExport,
    required this.onSaveToDevice,
  });

  bool get _isRoot =>
      page == DeeplinkPanelPage.entries || page == DeeplinkPanelPage.history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final envLabel = controller.selectedEnv?.label ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: _isRoot ? 'Close' : 'Back',
                icon: Icon(_isRoot ? Icons.close : Icons.arrow_back),
                onPressed: _isRoot ? onClose : onBack,
              ),
              Expanded(
                child: Text(
                  envLabel.isEmpty
                      ? 'Deeplink Tester'
                      : 'Current Active Env : $envLabel',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Deeplinks',
                icon: const Icon(Icons.list),
                color:
                    page == DeeplinkPanelPage.entries
                        ? theme.colorScheme.primary
                        : null,
                onPressed: onShowEntries,
              ),
              IconButton(
                tooltip: 'History',
                icon: const Icon(Icons.history),
                color:
                    page == DeeplinkPanelPage.history
                        ? theme.colorScheme.primary
                        : null,
                onPressed: onShowHistory,
              ),
            ],
          ),
          if (controller.showEnvSelector)
            DeeplinkEnvSelector(controller: controller, onManage: onManageEnvs),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _chip(Icons.file_download_outlined, 'Import', onImport),
                _chip(Icons.save_alt, 'Save to device', onSaveToDevice),
                _chip(Icons.ios_share, 'Share', onExport),
                _chip(Icons.palette_outlined, 'Icon', onPickIcon),
                _chip(
                  Icons.restart_alt,
                  'Reset',
                  controller.hasBundledDefaults ? onReset : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SegmentedButton<DispatchMode>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments:
                  controller.availableModes
                      .map(
                        (m) => ButtonSegment<DispatchMode>(
                          value: m,
                          label: Text(m.label),
                        ),
                      )
                      .toList(),
              selected: {controller.dispatchMode},
              onSelectionChanged:
                  (set) => controller.setDispatchMode(set.first),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Function()? onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        visualDensity: VisualDensity.compact,
        onPressed: onPressed == null ? null : () => onPressed(),
      ),
    );
  }
}
