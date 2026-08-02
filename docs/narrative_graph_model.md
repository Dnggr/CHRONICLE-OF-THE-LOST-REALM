# Two-Scale Narrative Graph

The game is a branching graph, not a list of chapter pages. It uses two scales:

```text
World-event node (arc opening)
  → 10+ common-event nodes (people, places, discoveries, consequences)
  → world-event resolution / next arc opening
```

## Node types

Every scene JSON object may include:

```json
{
  "sceneId": "event2_envoy",
  "arcId": "arc2_northern_war",
  "arcTitle": "Arc III · The War with the Northern Reach",
  "nodeType": "world"
}
```

- `nodeType: "world"` marks an arc-level turning point. The UI renders a quiet
  title card before it.
- Omit `nodeType` or use `"common"` for common-event nodes: travel, meals,
  letters, arguments, local work, small threats, lore, and immediate aftermath.
- `arcId` groups the nodes for validation and planning. Every new node in an
  arc should carry the same id once its file is being actively expanded.

The current model deliberately remains backward compatible: old scenes default
to the `legacy` arc and common-event type until they are migrated.

## Required arc rhythm

Each world-event arc should contain at least ten common-event nodes across its
main path, plus optional relationship and lore branches. A useful minimum:

1. Arrival / place context
2. Ordinary local work or ritual
3. First NPC observation
4. Conversation with a small personal stake
5. Optional lore or rumor
6. First meaningful choice
7. Immediate response to that choice
8. Consequence scene / relationship beat
9. Escalation
10. Arc-level decision or world-event resolution

Do not interpret “ten nodes” as ten decisions. Most nodes should provide
reading, conversation, and reaction; choices only appear when the player can
actually change a relationship, cost, safety, information, or future path.

## Choice continuity

Consequential choices require these JSON fields:

```json
{
  "label": "Ask Mira to organize the farmers",
  "preview": "Turn private survival into a public meeting; the assessor may answer.",
  "aftermath": "Mira looks at the empty bowls, then at the door.",
  "outcomeSuccessNode": "mira_valley_meeting"
}
```

For a stat check, add `aftermathFailure` as well. This produces the mandatory
reader rhythm: **context → action intent → immediate response → inherited
consequence**.

## Content-file rule

- One JSON file may hold one world-event arc and its supporting common events.
- Personal routes may live in dedicated files, but must rejoin a valid common
  or world-event node.
- Never hardcode arc progression in Flutter widgets; scene JSON targets and
  conditions remain the source of truth.
- Before adding an arc, run the scene-target and NPC-id integrity checks.
