# Chronicle of the Lost Realm — Phase 1 MVP

This is the Phase 1 skeleton from the build plan: the reading/choice
engine, save system, and legacy (death → canon → new run) pipeline,
with a 5-scene prologue that demonstrates a stat-check branch and a
world-flag-gated narrative variant.

I don't have the Flutter SDK available in the sandbox that generated this
project, so `android/`, `ios/`, etc. are NOT included — you'll generate
those locally in one step below. Everything under `lib/` and `assets/`
is complete and ready to drop in.

## Setup (Android only)

1. Install Flutter (if you haven't): https://docs.flutter.dev/get-started/install
   Run `flutter doctor` and make sure Android toolchain is green.

2. Unzip this project somewhere, `cd` into it, then generate the missing
   native scaffolding (this creates `android/` and the other platform
   folders that couldn't be included from the sandbox):

       flutter create --platforms=android .

   This will NOT overwrite any of the `lib/` or `assets/` files already
   here — it only fills in the missing native project files.

3. Get packages:

       flutter pub get

4. Plug in your Android phone (USB debugging on) or start an emulator,
   then run:

       flutter run

## What's implemented (Phase 1)

- `lib/models/` — SceneNode/SceneChoice, CharacterState, WorldHistory
  data models (see build plan section 5).
- `lib/engine/` — dice roller (1d20 + attribute vs DC), condition
  evaluator (the small `flags.x == true` / `attributes.x >= N` /
  `inventory.contains('x')` expression language), save manager (Hive,
  two separate boxes for the per-run save vs the permanent world save),
  legacy engine (death → DeceasedHero → WorldHistory), and
  `game_controller.dart`, the ChangeNotifier the whole UI listens to.
- `lib/ui/` — StatBar (top bar matching the reference screenshot),
  ChoiceButton, NarrativeText (renders prose + reward lines + optional
  inline illustration), SceneScreen, DeathScreen, JournalScreen, and a
  Phase-2-scaffold CharacterCreationScreen (not yet wired in — see the
  comment at the top of that file for how to wire it).
- `assets/scenes/prologue.json` — 5 connected scenes: the opening
  (matches your reference screenshot's text almost verbatim), a village
  fork, a Presence stat check with two different outcome scenes, and a
  scene whose text changes if `sun_temple_destroyed` is set — proving
  the world-flag branching system works.

## What's NOT implemented yet (see the plan's Phase 2+)

- No illustrations are bundled. `NarrativeText` gracefully shows a
  `[ illustration: id ]` placeholder box if the asset is missing, so the
  game runs fine without art — drop PNGs into
  `assets/images/illustrations/<id>.png` whenever you have them (must
  match the `illustrationId` used in the scene JSON).
- Character creation screen exists but isn't wired into the startup
  flow yet — right now a "Wanderer" is auto-created on first launch so
  you can test the engine immediately.
- Inventory screen, Achievements screen, and audio are all Phase 5 in
  the plan.
- Only one chapter (the prologue) exists. Adding more chapters means
  adding more `assets/scenes/*.json` files AND listing their paths in
  `lib/data/scene_repository.dart`'s `_sceneFiles` list AND in
  `pubspec.yaml` (already globbed via `assets/scenes/`, so new files in
  that folder are picked up automatically — you only need to add them to
  `_sceneFiles`).

## Testing the legacy loop right now

There's no fatal choice wired into the prologue yet (on purpose, so you
can read through it safely first). To test the death → new run → canon
loop:

1. Open `assets/scenes/prologue.json`.
2. Add `"isFatal": true` and `"fatalCause": "Slain by bandits"` to any
   choice object.
3. Run the app, pick that choice, confirm the DeathScreen appears with
   the correct cause, name a new hero, and confirm you land back on
   `prologue_start` — then check the Journal screen to see the fallen
   hero listed under "The Chronicle."
