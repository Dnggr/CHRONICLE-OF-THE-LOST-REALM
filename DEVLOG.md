# DEVLOG

This file is the running record of every build session: what problem we
were solving, what we changed to solve it, and why. Inline code comments
cover the "how" at the line level; this file covers the "why" at the
decision level, in one place, so you don't have to reconstruct the
reasoning from git history later.

New entries go at the TOP (most recent first).

--------------------------------------------------------------------------
## Session 2 — Character Archetypes / Origins

**Problem:** The engine only ever created a generic "Wanderer" character
automatically on first launch. There was no player-facing choice of who
you're playing as, and the legacy/origin system had nothing to hook into
besides raw attribute numbers.

**Solution:**
- Added `lib/data/archetypes.dart` — a static roster of 7 playable
  origins (Wanderer, Civilian, Heir of House Aldric, Elf, Dwarf, Vampire,
  Exiled Mercenary), each with attribute bonuses/penalties, starting
  gear/gold, and `originTags`.
- Added `CharacterState.originTags` + `CharacterState.fromArchetype()` —
  a single factory that's now the ONLY way a character gets created, so
  archetype perks can't be silently skipped.
- Extended `ConditionEvaluator` with an `origin.<tag> == true/false`
  pattern, mirroring the existing `flags.<key>` syntax but reading from
  the character instead of the world. This is what lets scene JSON
  differentiate "you rolled high Presence" from "you specifically ARE a
  Vampire."
- Reworked `GameController`: `character` is now nullable.
  `character == null && !isDead` (via the new `needsCharacterCreation`
  getter) is the single signal the whole app uses to decide whether to
  show `CharacterCreationScreen`. This replaced a design where a
  "Wanderer" was auto-created instantly on boot, which left no window
  for a real creation flow.
- `CharacterCreationScreen` rewritten from an unwired name-only scaffold
  into the real flow: name field + scrollable archetype cards showing
  perks and starting gear, wired to `GameController.beginRun()`.
- `DeathScreen` simplified: it no longer collects a name itself. It just
  shows the recap and calls `acknowledgeDeath()`, which hands control
  back to `_AppRoot` → `CharacterCreationScreen` — so choosing your next
  life after death goes through the SAME full archetype picker as your
  very first character, instead of a cut-down "just type a name" flow.
- `LegacyEngine.recordDeath` no longer hardcodes `title: 'The Wanderer'`
  for every dead hero — it now derives the Chronicle title from whichever
  archetype the player actually picked.
- Added two origin-gated example scenes in `prologue.json` (a Royal Heir
  can invoke House Aldric's name to clear the caravan road with no dice
  roll needed; a Vampire can attempt a Cunning-based compulsion instead)
  to prove the wiring works end-to-end, not just in theory.

**Story/design note:** House Aldric (the Royal Heir's family) is
deliberately the same name as `WorldHistory.monarchInPower`'s default
("King Aldric III") — playing a Royal Heir means you are, canonically,
kin to the current king. If you ever rename the default monarch, update
`Archetypes.royalHeir` to match.

**Compatibility note:** `CharacterState.fromJson` defaults `originTags`
to `[]` if missing, so a save written before this session (which has no
`originTags` field) still loads without crashing.

--------------------------------------------------------------------------
## Session 1 — Phase 1 MVP (initial engine)

**Problem:** Needed a working reading/choice engine before any content
or polish work made sense — prove scenes can load, branch on stat
checks, branch on world flags, and persist, before building on top of
that foundation.

**Solution:**
- Built the data models (`SceneNode`/`SceneChoice`, `CharacterState`,
  `WorldHistory`) matching the build plan's schema.
- Built the engine layer: `DiceRoller` (1d20 + modifier vs DC),
  `ConditionEvaluator` (a small hand-rolled expression language — chose
  regex-based pattern matching over a full parser/grammar because the
  actual condition vocabulary needed is small and fixed; a real
  expression parser would be over-engineering for "flags.x == true" /
  "attributes.x >= N" / "inventory.contains('x')"), `SaveManager` (Hive,
  two separate boxes — one for the wipeable per-run save, one for the
  permanent cross-playthrough world save, kept deliberately separate so
  a "new game" can never accidentally wipe legacy data), and
  `LegacyEngine` (the death → DeceasedHero → WorldHistory pipeline).
- Built the UI to match the reference screenshot (Life in Adventure):
  `StatBar`, `ChoiceButton`, `NarrativeText` (renders reward lines in
  green/red and drops in an inline illustration if one is specified,
  with a graceful placeholder box if the art asset doesn't exist yet —
  so writing/testing scenes is never blocked on having final art).
- Wrote a 5-scene prologue proving both branch types work: a Presence
  stat check with two different outcome scenes, and a scene whose text
  changes based on a world flag (`sun_temple_destroyed`).

**Engine choice:** Flutter over Unity — this project is a UI/state
problem (text, images, buttons, stat panels), not a rendering/physics
problem, and Flutter is much lighter on the dev's integrated-GPU PC than
Unity's editor + render loop. Full reasoning is in the original build
plan doc.
