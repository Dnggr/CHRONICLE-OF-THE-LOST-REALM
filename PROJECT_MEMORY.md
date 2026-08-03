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

## 2026-08-02 — Reading-first NPC route direction

- The user wants a vast, reading-first fantasy game where the player develops
  emotional attachment to NPCs and their own character, rather than rapidly
  clicking through decisions.
- Treat the existing NPC registry as a foundation, not completed content.
  Future work should author recurring 6–12 beat routes, long quiet interludes,
  and delayed consequences; avoid choice prompts for mere page turns.
- Added the first post-rebellion reading interlude and `docs/npc_route_matrix.md`
  to distinguish currently playable NPC beats from the NPC-route backlog.

## 2026-08-02 — Literary depth and minimal interaction direction

- The user wants original, literary dark-fantasy prose with richer lore,
  distinct origin voices, and emotional character interiority; do not imitate
  living or copyrighted authors directly.
- The interface should be minimalist and responsive: prose-led choice rows with
  motion feedback, not oversized ornamental buttons, plus quiet non-blocking
  notice text when a major world event is close.

## 2026-08-02 — Royal Heir first deep-route pass

- Chose Royal Heir as the next origin to deepen because it naturally connects
  Ser Aldous Fenn, Lady Ysolde Marrow, family history, court lore, and the
  Succession Crisis.
- Added a birth/childhood/family route before the shared road, with remembered
  choices that affect Aldous and Marrow trust.
- Added `docs/production_priorities.md` as the detailed, prioritized record of
  completed work and next production tasks, per the user's request.

## 2026-08-02 — Ser Aldous reading-heavy route, Act 1

- Added Royal Heir-exclusive Aldous scenes after Events 1, 2, 4, and 5. They
  cover shared time with townsfolk, a close tavern attack, aftermath, war
  watch, Elowen's counsel, and a final Capital vigil.
- The tavern scene makes the player's physical actions, spoken dialogue, and
  the surrounding townsfolk's responses explicit; mercy and intimidation carry
  separate trust/reputation consequences.

## 2026-08-02 — Complete major-event spine

- Interpreted the request to implement all events as completing the remaining
  numbered major campaign events (6–8), following Events 0–5 already authored.
- Added Event 6 (Salt Sea Invasion), Event 7 (Dark Legion), and Event 8 (Demon
  Lord) scene graphs. Event 5 now hands off to Event 6; Event 7 can end a
  surviving run or route a fallen realm to the capstone.
- Updated the author timeline and README to show Events 0–8 as the complete
  major spine. Minor catalog events remain future optional content.

## 2026-08-03 — Mira Talbot route, Act 2

- Audited the campaign from the prologue through the endings: scene JSON,
  targets, NPC ids, and route gates are valid; only deliberate final-ending
  scenes have no choices.
- Added an Event 1 follow-up route for high-trust and estranged Mira states:
  returning to Talbot farm, family context with Tovin, a farmers' cooperative
  conflict, and an unresolved estrangement path. The route records friendship,
  defiance, or estrangement for later prose.

## 2026-08-03 — Salt Road culture and dialogue route

- Added a reading-heavy Salt Road route for Yeva Solt, Petra Voss, and Tamsin
  after the Rebellion: market road-bread, a guild-supported orphan house,
  carrier-family history, bell codes, and recurring local idioms.
- The route uses longer player/NPC dialogue and records relationship decisions
  about Yeva's secret support, Petra's view of loyalty, and Tamsin's truth.

## 2026-08-03 — Priority 1 backlog: Hendrik aftermath, Mira letters, Salt Road check-in

- The user asked to broaden existing content specifically (more dialogue and
  routes on what already exists) rather than add new breadth, and asked for
  ready-to-paste output. Worked directly from `docs/production_priorities.md`'s
  unchecked Priority 1 items rather than picking new scope.
- Added Old Hendrik's aftermath: a saved branch (a real teaching scene or a
  rest-first alternative, either way inheriting his toolkit) and a dead
  branch (two grief options, inheriting his whetstone). Both set
  `world_flags.hendrik_legacy_tool` as a hook for later scenes to react to —
  nothing downstream reads it yet; flagged as follow-up work in
  `production_priorities.md`.
- Added Mira Talbot's post-Event-4 farm letters: a courier check-in gated on
  trust/estrangement, and — for the trusted branch — a real adult choice
  (cover a farmer's debt for gold, write back with only encouragement, or
  leave the letter unanswered), each with distinct trust/reputation
  consequences.
- Added one Yeva/Petra quiet interlude + decision after Event 2 (matching the
  existing Salt Road culture route's tone), gated on Yeva trust. The same
  treatment for Events 4 and 5 remains unchecked in production_priorities.md
  — deliberately scoped down to one solid addition rather than three thin
  ones in a single pass.
- Engine gap found and fixed while wiring this in: `inventory_add` was used
  in the new Hendrik scenes (handing over a toolkit/whetstone) but
  `GameController`'s effects handler didn't support that key yet — only
  `gold` had been added previously. Added `inventory_add` alongside it.
- Ran a full referential-integrity check across all 15 scene files after
  editing (130 scenes, no dangling references, no duplicate scene ids) since
  this session edited existing files rather than only adding new ones.
## 2026-08-03 — Choice-reaction rule + fixing the "skipping" bug in the opening arc

- The user reported that reading the game felt like "skipping" and left them
  lost, and asked specifically for reactions to choices (what happens next,
  in-world, immediately after picking one) rather than a vague pacing pass.
- Root cause found in the actual scene JSON, not the prose style: several
  branch points had many different choices — sometimes 8 or 9, representing
  different origins or entirely different actions — all landing on the exact
  same next scene with one generic line that reacted to nothing specific.
  Separately, three stat checks had their success and failure outcomes
  pointed at the identical next scene, so failing read exactly like
  succeeding. Both are the same underlying bug: a choice with no felt
  consequence before the story moves on.
- Added a new non-negotiable rule (rule 9) to `npc_dialogue_and_routes.txt`,
  plus a checklist item, specifically naming this failure mode and requiring
  every stat check to split success/failure and every multi-choice
  convergence point to react to a `world_flags.<key>` value set per choice —
  with a concrete self-test ("cover the choice list, read only the next
  paragraph — can you tell which choice was picked?").
- Fixed it in the part of the game every player reads first:
  - `prologue.json`: split the Hendrik wheel-repair check into
    `prologue_hendrik_wheel_fixed` / `_failed`, each with its own reaction
    before rejoining the same conversation.
  - `chapter1_harvest.json`: split the Mira fence-repair check the same way
    (`chapter1_harvest_fence_fixed` / `_failed`); split all three stat-checked
    origin routes at the granary scene (elf ward, dwarf mill, vampire
    compulsion) into distinct success/fail scenes; and rewrote
    `chapter1_harvest_mira_check` from one generic line into 12
    `narrativeVariants`, one per `world_flags.harvest_response` value, so
    every one of the granary scene's nine choices gets its own reacting text
    before the story converges.
  - `event1_rebellion.json`: same treatment for `event1_toll_trouble`'s eight
    choices — added `world_flags.toll_response` per choice and rewrote
    `event1_closed_doors` with 8 matching variants.
- Did NOT audit Events 2–8 or the Royal/Aldous/Salt-Road-culture route files
  for the same pattern this session — the rule now exists to catch it going
  forward, but the existing files there haven't been re-read against it yet.
  That audit is the natural next step if the "skipping" feeling persists past
  the opening arc.
