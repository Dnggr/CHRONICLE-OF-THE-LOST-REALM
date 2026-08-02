# Production Priorities

This is the working source for what is complete and what should be built next.
Update it when a content milestone changes. It is deliberately concrete: do not
mark a route complete because an NPC merely has a registry entry or one scene.

## Done

- [x] Prologue, Event 0–8 major campaign spine, with persistent world flags.
- [x] Seven distinct origin openings; Royal Heir now includes birth, childhood,
  family, Ser Aldous, and Lady Marrow context before the shared road.
- [x] Mira Talbot's Harvest Failure arc, including trust and estrangement.
- [x] Old Hendrik's roadside setup and plague survival/death decision.
- [x] Early Yeva/Petra/Tamsin post-Rebellion reading interlude.
- [x] Ser Aldous's war, succession, Legion, and capstone callbacks.
- [x] Scene-log reveal animation, minimalist choice rows, and quiet event
  approach notices.
- [x] NPC registry, timeline, route matrix, and project-memory documentation.

## Priority 1 — reading-first vertical slice

Build these before adding more world events or combat systems.

1. **Royal Heir / Ser Aldous route, Acts 1–3** — *Act 1 now playable*
   - [x] Add recurring scenes after Event 1, Event 2, Event 4, and Event 5.
   - [ ] Add 2–4 further scenes after Event 7 and a final resolution beat.
   - Make the childhood trust choice affect his tone, rescue option, and final
     presence.
   - Add the Dowager Regent Elowen and Cousin Tobias as living family pressure,
     not only lore references.
   - End states: principled ally, dutiful distance, sacrifice, survival.

2. **Mira Talbot route, Acts 2–3** — *Act 2 now playable*
   - [x] Add a post-Rebellion farm return, family meal, farmers' meeting, and
     an estranged-route encounter where Mira can disagree without vanishing.
   - [ ] Add farm letters and a later adult-choice scene after Event 4.
   - Branch from redemption/cover-up/report into friendship, estrangement,
     institutional revenge, and only then a slow-burn romance possibility.
   - Do not label romance before several event-spanning acts and mutual trust.

3. **Yeva / Petra dual route**
   - [x] Add a Salt Road culture route with market, orphanage, rooftop, and
     bell-tower conversations plus meaningful relationship decisions.
   - [ ] Add one quiet interlude and one meaningful decision after Events 2, 4,
     and 5 each.
   - Make both women sometimes correct; trust with one must not automatically
     erase the other.
   - End states: guild partnership, bitter respect, betrayal, reconciliation,
     or political rivalry.

4. **Old Hendrik aftermath**
   - If saved: teaching, letters, and an earned practical legacy.
   - If dead: grief scenes and an inherited tool/lesson that changes later
     prose, not a resurrection or a forgotten flag.

## Priority 2 — interludes and lore density

- [ ] Add 2–4 reading interludes between every major-event pair. Use travel,
  meals, work, letters, rumors, arguments, and aftermath.
- [ ] Give every region a small recurring culture: food, work, prayer, slang,
  funeral practice, weather belief, and a local contradiction.
- [ ] Add optional lore routes that never block urgent story progress.
- [ ] Add origin-specific observations to every major-event coda.
- [ ] Add letters and journal fragments that reflect the player’s prior choices.

## Priority 3 — systems needed for long-form routes

- [ ] Persist the scene log or a compact chapter recap across app restarts.
- [ ] Add explicit route milestones (for example `mira_route_act`) only when
  trust and flags alone become too ambiguous.
- [ ] Add a relationship journal page with last meaningful interaction, route
  state, and remembered promises.
- [ ] Add an accessibility/reduced-motion setting for text and button motion.
- [ ] Add a scene-authoring validator that checks all targets, NPC IDs, flags,
  and unreachable choices in CI.

## Priority 4 — playtesting and polish

- [ ] Test on a physical device after each route act.
- [ ] Track where a player reaches a choice before feeling a scene’s stakes;
  insert a reading interlude there.
- [ ] Track lore that never changes a later line, relationship, or opportunity;
  either connect it or cut it.
- [ ] Test every origin through Event 2 and every major resolution through its
  coda.
- [ ] Add final illustration, sound, and accessibility passes only after the
  reading rhythm is stable.

## Not a current priority

- Hundreds of disconnected NPCs with one-off quests.
- More major world events before the existing characters have deeper routes.
- A large combat system that displaces reading and relationship consequences.
