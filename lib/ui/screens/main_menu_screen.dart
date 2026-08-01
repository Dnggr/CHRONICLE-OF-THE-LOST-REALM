import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../engine/game_controller.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// PROBLEM: the app used to route straight from "loaded" into either
/// CharacterCreationScreen or SceneScreen - there was no home base to
/// return to, and no way to reach Settings or a legacy/statistics
/// overview without already being mid-game. SOLUTION: this screen is
/// now the actual `home:` destination (see main.dart's _AppRoot) - every
/// other top-level screen is reached FROM here, and death now routes
/// back HERE (see GameController.acknowledgeDeath) instead of straight
/// into character creation, so a Chronicle update is always visible
/// before the player commits to their next life.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final deceasedCount = controller.world.deceasedHeroes.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1B1712),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Chronicle of\nthe Lost Realm',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: Colors.amber[100],
                    fontSize: 30,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  deceasedCount == 0
                      ? 'No hero has yet fallen. The realm awaits its first.'
                      : 'The realm remembers $deceasedCount who came before.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.merriweather(
                    color: Colors.white54,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 48),
                if (controller.hasActiveRun)
                  _MenuButton(
                    label: 'Continue',
                    icon: Icons.play_arrow,
                    filled: true,
                    onTap: controller.resumeGame,
                  ),
                _MenuButton(
                  label: 'New Game',
                  icon: Icons.add,
                  filled: !controller.hasActiveRun,
                  onTap: () => _confirmNewGame(context, controller),
                ),
                _MenuButton(
                  label: 'History',
                  icon: Icons.menu_book,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                _MenuButton(
                  label: 'Settings',
                  icon: Icons.settings,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// PROBLEM: tapping "New Game" while a run is already in progress used
  /// to silently overwrite it - beginRun() replaces `character` and
  /// SaveManager.saveRun() writes over the same save slot, so the
  /// abandoned run would vanish without ever being recorded as a death
  /// in the Chronicle (recordDeath is only called by _handleDeath).
  /// SOLUTION: warn before overwriting, so an in-progress run is never
  /// lost by an accidental tap.
  Future<void> _confirmNewGame(
    BuildContext context,
    GameController controller,
  ) async {
    if (!controller.hasActiveRun) {
      controller.goToCharacterCreation();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon current run?'),
        content: const Text(
          'Starting a new game will abandon your current adventurer '
          'without recording them in the Chronicle. This cannot be '
          'undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Abandon & Start New'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      controller.goToCharacterCreation();
    }
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: 240,
        child: filled
            ? ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(icon, size: 18),
                label: Text(label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )
            : OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(icon, size: 18, color: Colors.amber[200]),
                label: Text(label, style: TextStyle(color: Colors.amber[200])),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.amber[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
      ),
    );
  }
}
