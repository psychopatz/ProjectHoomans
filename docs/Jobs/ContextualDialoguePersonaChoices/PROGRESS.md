# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23  
**Parent status:** REOPENED — P10 infrastructure is retained, but P11 runtime-parity/relationship/UX acceptance is mandatory.  
**Current mandatory phase:** P11A — Truthful actor/context model and UI cleanup skeleton.  
**Implementation baseline audited:** ProjectHoomans remote `main` at `c412d50c27a423965911e115c0947b65c1eb2b6c`.  
**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Accepted foundation to preserve

Current source materially contains:

- contextual What's Up semantic hub;
- removal of the old authored What's Up category;
- generic registered hub/choice providers;
- typed Simulation Control Catalog;
- structured inventory + Advanced JSON;
- inline Simulation workbench and Apply + Replay;
- hub diagnostics;
- ConversationBlock graph projection/history;
- ActorConversationContext and SpeechStyleContext;
- EN/TL realization infrastructure;
- relationship-state resolver/hysteresis;
- production trait registries;
- production social-profile generator/resolvers;
- existing gender/orientation compatibility math;
- server-authoritative directed relationship service/persistence;
- broad regression coverage from P10.

Do not discard these systems.

## 2026-10-23 post-P10 audit findings

### Main Simulation UX remains developer-centric

The primary screen still exposes:

- Preview;
- Snapshot;
- Persona matrix;
- World knowledge;
- Restart worker;
- Capture baseline;
- Sweep.

Several are diagnostics or hidden comparison mechanisms rather than normal conversation-testing controls.

### Sweep/Persona Matrix is cryptic

`Sweep` selects which field a three-scenario Persona Matrix operation varies. The UI does not explain this relationship and the result is primarily diagnostic/raw output.

This must become one explicit Compare surface.

### Relationship sliders need immediate explanation

Approval/respect/familiarity apply through the worker, but changing them alone does not replay dialogue and the UI does not clearly explain state thresholds.

At familiarity below the production recognition threshold, even approval/respect extremes still resolve to `unknown`; this is correct production logic but poor UX without reason/progress display.

### Runtime graph coverage is incomplete

Current Simulation graph consumes ConversationBlock graph projection.

A greeting handled by production semantic Flow can leave the graph blank.

Semantic Hub activation likewise needs a runtime graph adapter rather than a fake ConversationBlock.

### Actor symmetry is missing

NPC state has more first-class semantic controls than Player state.

Player needs are not first-class scenario data and Player traits/social profile are not exposed alongside NPC traits/personality in the main workbench.

### Personality source is misleading

Live NPC personality is generated from identity/archetype/traits and then normalized.

The harness currently presents manual numeric personality sliders as ordinary state rather than explicit override/debug state.

### Normal relationship-kind catalog is not truthful enough

The extensible registry includes hypothetical/future/internal kinds that current gameplay does not actually produce.

Normal UI must only expose real current production kinds.

### Dynamic friend/lover progression is missing

Current durable bond handling is still too manual.

Approved runtime model is now:

```text
family = authored/pre-existing

none
 -> automatic friend after high relationship milestone
 -> lover only after compatibility + player proposal + NPC acceptance
```

Current relationship standing remains separate and may later become rival/enemy without erasing social history.

## Current Exact Next Chunk — P11A

On the user's actual local checkout:

1. read root `AGENTS.md` and the ContextualDialoguePersonaChoices docs in documented order, including `RUNTIME_PARITY_ACTORS_RELATIONSHIPS_AND_UX.md`;
2. verify ProjectHoomans/Core/DynamicTrading branch, HEAD, upstream/divergence, dirty/concurrent changes; existing `main` only;
3. inspect:
   - current Simulation toolbar/workbench ownership;
   - scenario player/NPC state;
   - Simulation Control Catalog;
   - player and NPC trait registries;
   - RelationshipKindRegistry;
   - Starting Companion real relationship-kind producers;
   - relationship record/persistence/normalization;
   - current graph adapters;
4. remove hypothetical/future relationship kinds from **normal selectable catalogs** while preserving safe extensibility/aliases internally;
5. normal production-visible relationship kinds must reflect actual current producers, presently:
   - friend;
   - lover;
   - mother;
   - father;
   - sister;
   - brother;
6. establish the actor-centric primary workbench shell:
   ```text
   NPC Target | Player | Relationship | World
   ```
   with actor sub-tabs:
   ```text
   Overview | Needs | Personality & Traits
   ```
7. preserve existing Apply / Apply + Replay / structured inventory / Advanced JSON;
8. begin moving low-level controls to their target owners without deleting capabilities:
   - World Knowledge refresh -> World Knowledge inspector;
   - Restart worker / Snapshot -> Diagnostics/Worker;
   - Preview -> Send/Preview control or diagnostics;
   - Persona Matrix / Sweep / Capture baseline -> future Compare surface;
9. do not implement friend/lover persistence in the same P11A chunk unless the UI/catalog skeleton requires a small read-only placeholder;
10. add Tk/Xvfb geometry/navigation tests proving Player and NPC Target surfaces are first-class and normal bond catalogs contain no hypothetical kinds;
11. run focused Python/Tk/Lua syntax/diff checks;
12. update this ledger with exact evidence and continue automatically to P11B if P11A passes.

## P11A acceptance

The actual Semantic Lab must visibly provide:

```text
NPC Target
Player
Relationship
World
```

and the normal relationship/bond selectors/catalogs must no longer advertise future synthetic kinds such as cousin/grandmother/partner/spouse unless a real current production owner is found during the source audit.

Primary workflow clutter should already begin moving to meaningful destinations.

## Ordered remaining milestones

After P11A continue automatically:

- **P11B:** first-class Player/NPC needs + production traits/personality;
- **P11C:** durable automatic friend promotion on existing relationship records;
- **P11D:** compatibility + proposal + server-authoritative acceptance -> lover;
- **P11E:** live relationship preview + Compare/toolbar cleanup;
- **P11F:** unified semantic Flow / Hub / ConversationBlock runtime graph;
- **P11G:** modular speech-realization content packs;
- **P11H:** final runtime-parity usability/regression gate.

See `RUNTIME_PARITY_ACTORS_RELATIONSHIPS_AND_UX.md` for full contracts.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** again until P11A-P11H all pass.

Native Project Zomboid SP/MP remains user-owned and must remain UNTESTED unless the user supplies evidence.
