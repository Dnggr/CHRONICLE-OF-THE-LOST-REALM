import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_controller.dart';
import '../../engine/settings_controller.dart';

/// PROBLEM: there was no settings surface at all - text size, theme,
/// and "reset everything" all needed a home, and "reset everything"
/// specifically needed to be hard to trigger by accident since it wipes
/// the permanent Chronicle. SOLUTION: a straightforward preferences
/// list backed by SettingsController (see settings_controller.dart for
/// why settings live in their own persistence box, separate from
/// GameController/SaveManager's world_box), with the destructive action
/// visually separated at the bottom and gated behind a confirmation
/// dialog that requires typing to confirm intent isn't accidental.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final settings = settingsController.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Display'),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Switch the reading theme from parchment to dark'),
            value: settings.darkMode,
            onChanged: settingsController.setDarkMode,
          ),
          ListTile(
            title: const Text('Text size'),
            subtitle: Slider(
              value: settings.textScale,
              min: 0.85,
              max: 1.3,
              divisions: 9,
              label: '${(settings.textScale * 100).round()}%',
              onChanged: settingsController.setTextScale,
            ),
          ),
          const Divider(height: 32),
          const _SectionHeader('Gameplay'),
          SwitchListTile(
            title: const Text('Show dice roll details'),
            subtitle: const Text(
              'Display "Roll: 14 + 2 = 16 vs DC 12" after stat checks',
            ),
            value: settings.showRollBanner,
            onChanged: settingsController.setShowRollBanner,
          ),
          const Divider(height: 32),
          const _SectionHeader('Danger Zone'),
          Card(
            color: Colors.red.withOpacity(0.06),
            child: ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.red),
              title: const Text('Reset World'),
              subtitle: const Text(
                'Permanently deletes your current run AND the entire '
                'Chronicle of fallen heroes. This cannot be undone.',
              ),
              onTap: () => _confirmReset(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final gameController = context.read<GameController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset the entire world?'),
        content: const Text(
          'This deletes your current adventurer AND every fallen hero '
          'ever recorded in the Chronicle. There is no undo. Are you '
          'absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await gameController.resetWorld();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
