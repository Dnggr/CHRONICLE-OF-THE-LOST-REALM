# Project Memory

This is the durable record of design decisions made in collaboration. It is
updated after project-relevant user conversations; it intentionally stores
summaries, not private or verbatim chat transcripts.

## 2026-08-02 — Novel pacing and long-form direction

- The user wants the game to read like a slow-paced fantasy novel, with context
  and NPC introduction before urgent choices.
- Desired tonal palette: fantasy adventure, love, revenge, redemption,
  suspense/thriller, drama, fiction, and consequential gore.
- Long-term ambition is 1,000+ hours of replayable play and approximately
  10,000 pages of authored/variant narrative. Build this through event arcs,
  relationship routes, legacy variation, and reusable scene systems—not one
  linear mandatory script.
- Added `npc_dialogue_and_routes.txt` as the authoring reference for voice,
  feelings, slow-burn routes, and novel-pacing rules.
- Added Old Hendrik roadside scenes between every origin opening and the
  caravan/ruin path, so the Harvest Failure has human context before Mira
  Talbot asks for help.
- Future content must update this file when it changes a design decision or
  implementation sequence.

## 2026-08-02 — Legacy and first event implementation

- The Story & Systems Bible contains a formal Living Legend / Retired Hero
  design. It is documented but not yet implemented in Dart.
- Events 0 (Harvest Failure) and 1 (Salt Road Rebellion) are playable.
- Event 2 is currently only foreshadowed at the Event 1 coda and needs authoring
  before the campaign can continue.

## 2026-08-02 — Events 2–5 playable campaign spine

- Events 0–1 were reviewed; the missing work was Event 1's coda handoff, which
  now leads to Event 2 instead of ending the active run.
- Added playable scene graphs for Event 2 (Northern War), the conditional Event
  3 (Sun Temple Schism), Event 4 (Hollow Reaches Plague), and Event 5
  (Succession Crisis). They use dialogue, NPC trust/status, reputation, and
  persistent world flags to carry consequences between arcs.
- Added `docs/story_timeline.md` as the human-facing campaign handoff map. JSON
  scene files remain the runtime source of truth; the timeline prevents missing
  transitions while later events are authored.
- Event 5 is intentionally the current authored endpoint and foreshadows Event
  6; when Event 6 is implemented, replace its terminal coda with a handoff.

## 2026-08-02 — Narrative reveal motion

- New scene-log entries now reveal their complete lines in a short staggered
  fade/slide/size animation after a player chooses an option. The scroll view
  follows the expanding passage so it reads as new text arriving, rather than
  jumping to a fully rendered block at the bottom.

## 2026-08-02 — Complete major-event spine

- Interpreted the request to implement all events as completing the remaining
  numbered major campaign events (6–8), following Events 0–5 already authored.
- Added Event 6 (Salt Sea Invasion), Event 7 (Dark Legion), and Event 8 (Demon
  Lord) scene graphs. Event 5 now hands off to Event 6; Event 7 can end a
  surviving run or route a fallen realm to the capstone.
- Updated the author timeline and README to show Events 0–8 as the complete
  major spine. Minor catalog events remain future optional content.
