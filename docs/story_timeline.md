# Authored Story Timeline

This is the authoring map for the playable campaign. Scene JSON remains the
runtime source of truth; this file explains the intended handoffs and gates so
new content does not leave a coda with nowhere to go.

| Event | Arc | Entry | Resolution / next handoff |
| --- | --- | --- | --- |
| 0 | Harvest Failure | Prologue routes | `event1_toll_trouble` |
| 1 | Rebellion of the Salt Road | Harvest coda | `event2_envoy` |
| 2 | War with the Northern Reach | Salt Road coda | Sun Temple Schism if `sun_temple_destroyed`; otherwise Plague |
| 3 | Sun Temple Schism | Only when `sun_temple_destroyed == true` | `event4_cough` |
| 4 | Plague out of the Hollow Reaches | War or Schism coda | `event5_kings_health` |
| 5 | Succession Crisis | Plague coda | `event6_strange_sails` |
| 6 | Foreign Invasion from Across the Salt Sea | Succession coda | `event7_omens` |
| 7 | Dark Legion | Invasion coda | Demon Lord only after `realm_falls`; otherwise a survival ending |
| 8 | Demon Lord | Only after Dark Legion `realm_falls` | Capstone ending: the hero falls or survives |

## Authoring rules

- Every non-terminal coda must have a visible, state-valid choice into the
  next event.
- Conditional events route around their scene file at the preceding coda;
  never use a placeholder "nothing happens" scene.
- Keep branch consequences in `world_flags`, `reputation`, and `npc` effects,
  then reference them with scene conditions or narrative variants.
- Terminal codas are intentional only for a completed playthrough. Event 7's
  survival coda and Event 8's final outcomes are the current terminal states.
