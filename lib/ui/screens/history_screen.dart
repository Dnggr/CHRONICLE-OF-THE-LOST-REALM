import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../engine/game_controller.dart';
import '../../models/world_history.dart';

/// PROBLEM: JournalScreen (reachable mid-game from SceneScreen's bottom
/// nav) already lists deceased heroes, but only as a flat list with no
/// aggregate view, and it's only reachable while a run is active - there
/// was no way to browse your Chronicle from the main menu, or to see it
/// as a summary rather than a log. SOLUTION: HistoryScreen is a separate,
/// main-menu-reachable screen focused on STATISTICS (computed on the fly
/// from WorldHistory, never stored - see the note in _HistoryStats)
/// plus the same per-hero detail list. Journal and History intentionally
/// overlap on the deceased-hero list, but serve different moments:
/// Journal is "where am I / what have I done lately," History is "what
/// has this world become."
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final world = controller.world;
    final heroes = world.deceasedHeroes;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: heroes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No hero has fallen yet. The Chronicle is still blank.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.merriweather(color: Colors.black54),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HistoryStats(world: world),
                const SizedBox(height: 20),
                Text('Fallen Heroes', style: GoogleFonts.cinzel(fontSize: 18)),
                const SizedBox(height: 8),
                ...heroes.reversed.map((hero) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${hero.name}, ${hero.title}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Died ${hero.yearOfDeath}, aged ${hero.ageAtDeath} '
                              '(${hero.causeOfDeath})',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (hero.relicsLeft.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Relics left behind: ${hero.relicsLeft.join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            ...hero.majorCanonEvents.map(
                              (e) => Text('- $e', style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}

/// Aggregate stats card. Everything here is DERIVED from
/// WorldHistory.deceasedHeroes at build time, not stored anywhere - if
/// you want a new stat, add a getter here rather than a new save field.
class _HistoryStats extends StatelessWidget {
  final WorldHistory world;

  const _HistoryStats({required this.world});

  @override
  Widget build(BuildContext context) {
    final heroes = world.deceasedHeroes;

    final oldestHero = heroes.reduce(
      (a, b) => a.ageAtDeath >= b.ageAtDeath ? a : b,
    );
    final youngestHero = heroes.reduce(
      (a, b) => a.ageAtDeath <= b.ageAtDeath ? a : b,
    );
    final totalCanonEvents =
        heroes.fold<int>(0, (sum, h) => sum + h.majorCanonEvents.length);

    final causeCounts = <String, int>{};
    for (final hero in heroes) {
      causeCounts[hero.causeOfDeath] = (causeCounts[hero.causeOfDeath] ?? 0) + 1;
    }
    final mostCommonCause = causeCounts.entries.isEmpty
        ? null
        : causeCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return Card(
      color: const Color(0xFFEFE8D8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The Realm', style: GoogleFonts.cinzel(fontSize: 16)),
            const SizedBox(height: 8),
            _StatLine('Current year', '${world.currentYear}'),
            _StatLine('Monarch', world.monarchInPower),
            _StatLine('Heroes fallen', '${heroes.length}'),
            _StatLine('Total canon events written', '$totalCanonEvents'),
            _StatLine(
              'Longest-lived',
              '${oldestHero.name} (${oldestHero.ageAtDeath})',
            ),
            _StatLine(
              'Shortest-lived',
              '${youngestHero.name} (${youngestHero.ageAtDeath})',
            ),
            if (mostCommonCause != null)
              _StatLine(
                'Most common cause of death',
                '${mostCommonCause.key} (${mostCommonCause.value}x)',
              ),
            if (world.worldFlags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'World flags: ${world.worldFlags.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
