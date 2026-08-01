import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/game_controller.dart';
import '../widgets/choice_button.dart';
import '../widgets/narrative_text.dart';
import '../widgets/stat_bar.dart';
import 'death_screen.dart';
import 'journal_screen.dart';

class SceneScreen extends StatelessWidget {
  const SceneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        if (controller.isDead) {
          return const DeathScreen();
        }

        final scene = controller.currentScene;
        if (scene == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFE9E2D3), // parchment page
          body: SafeArea(
            child: Column(
              children: [
                // Safe to force-unwrap: reaching this line means isDead
                // was false AND currentScene was non-null above, and
                // GameController only ever has a non-null currentScene
                // while character is also non-null (see _loadCurrentScene).
                StatBar(character: controller.character!),
                Container(height: 3, color: Colors.amber[800]),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NarrativeText(
                          text: controller.currentNarrative,
                          illustrationId: scene.illustrationId,
                        ),
                        if (controller.lastCheckResult != null)
                          _CheckResultBanner(
                            result: controller.lastCheckResult!,
                          ),
                        const SizedBox(height: 16),
                        ...controller.availableChoices.map(
                          (choice) => ChoiceButton(
                            label: choice.label,
                            onTap: () => controller.selectChoice(choice),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _BottomNav(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CheckResultBanner extends StatelessWidget {
  final dynamic result; // StatCheckResult

  const _CheckResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final success = result.success as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: success ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Roll: ${result.roll} + ${result.modifier} = ${result.total} '
        'vs DC ${result.difficultyClass} - ${success ? "Success" : "Failure"}',
        style: TextStyle(
          color: success ? Colors.green[800] : Colors.red[800],
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFCFC7B8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Journal',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JournalScreen()),
              );
            },
          ),
          const IconButton(
            icon: Icon(Icons.inventory_2_outlined),
            onPressed: null, // Phase 2: build inventory screen
          ),
          const IconButton(
            icon: Icon(Icons.emoji_events_outlined),
            onPressed: null, // Phase 2: build achievements/endings screen
          ),
          const IconButton(
            icon: Icon(Icons.account_balance_wallet_outlined),
            onPressed: null,
          ),
        ],
      ),
    );
  }
}
