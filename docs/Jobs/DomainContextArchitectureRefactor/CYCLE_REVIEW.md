# Current dependency-cycle review

Scope: maintained current-runtime Lua and recorded literal imports. Dynamic
imports, callbacks and heuristic alias edges need direct source review. Counts
of analyzer manifestations are not counts of independent architecture problems.

## Resolved directions

- Persistence coordinates envelopes/timing and uses domain-owned repositories.
  Storage is a separate schema-neutral mechanism. Persistence and Storage are
  outside the current owner SCCs; deserialization needs no UI behavior.
- Conversation uses the public Presentation palette query. The implementation
  moved intact from `client/PNC/UI/PNC_NPCTypePalette.lua` to
  `client/PNC/Presentation/PNC_NPCTypePalette.lua`. Conversation is outside the
  UI-related owner SCC. Maintained callers use the canonical entry.
- The old palette require path is a permanent public compatibility forwarder.
  It returns the same palette/color table; it contains no implementation or
  duplicate state. Bootstrap canonicalization verifies the pure forwarder and
  preserves the expanded provider order.

## Retained UI navigation SCC

The all-phase import report contains one three-file SCC, wholly owned by UI.
Paths in this table are relative to `client/PNC/`:

| Edge | Execution evidence |
| --- | --- |
| `UI/NPCPresentationDebug/PNC_NPCPresentationDebug.lua` → `UI/PNC_AnimationSceneDebugWindow.lua` | `openScenes`, lines 154–168, requires the destination on demand; Animation tab action dispatch calls it at line 292. |
| `UI/PNC_AnimationSceneDebugWindow.lua` → `UI/PNC_AnimationSceneDebugWindow_Actions.lua` | Top-level assembly of that window's actions. |
| Actions → Presentation Debug window | `onOpenXML`, lines 81–94, requires the destination on demand. Core binds this method as the Open XML Player button callback, lines 117–129. |

This reviewed SCC contains no all-top-level require loop. It is two explicit
window-navigation routes inside one owner, with permission checks still in the
public Open methods. Retain the lazy loads: adding a callback registry or moving
window-opening policy into gameplay domains would add machinery without
improving authority or change-local context. The diagnostic SCC remains visible.

`P5D2_MCP_TRACES.json` records coverage and trace limitations;
`P5D2_ARCHITECTURE_PROOF.json` pins source hashes and exact unchanged palette
bytes. The existing animation-scene debug route/smoke tests remain green.

## Remaining owner groups

Still require individual P5/P6/P7 review:

- Activities ↔ Production: work-policy/requirement/item-service ownership.
- Companions / Knowledge / Networking / UI: command admission, presentation
  mirrors, knowledge-interest queries and result presentation.
- Identity / Semantics / Social / World: immutable vocabulary/value contracts,
  accepted-interaction evidence, trait context and world-fact projections.

These groupings collapse many different functions, runtime roles and contracts.
They are not automatically runtime recursion, and they are not yet blanket
accepted. Review actual call/initialization paths and owner seams; remove real
foreign-private coupling and justify each retained protocol/composition relation.
