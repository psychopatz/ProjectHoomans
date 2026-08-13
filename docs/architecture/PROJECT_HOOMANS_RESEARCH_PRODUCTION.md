# Research and Colony Production

Status: implemented in source and isolated Lua harnesses on 2026-08-14.
In-game SP, hosted MP, dedicated-server, reconnect, and real-save reload remain
release validation gates; this document does not represent them as passed.

## Dependency direction

```text
Research -> RecipeCatalog, RecipeKnowledgeRegistry, Work, Colony Storage
Crafting -> RecipeCatalog, Research queries, Work, Colony Storage
Work -> Facilities, NPC Registry, Skills
UI -> colony-management request/command adapters only
```

Recipe definitions exist once in the runtime `RecipeCatalog`. Colonies and Work
Orders reference compact recipe IDs and never own normalized descriptors.
PsychopatzCore remains the owner of generic virtual-inventory and reservation
mechanics; all research, blueprint, workstation, crafting, provenance, and
salvage policy remains in Project Hoomans.

## Domain contracts

### RecipeCatalog

- **Owns:** runtime normal-recipe descriptors and key/result/ingredient indexes.
- **Commands:** rebuild from Build 42 `ScriptManager` craft recipes.
- **Queries:** recipe by stable script full type, producers, ingredients, list,
  and diagnostics.
- **Lifecycle:** one guarded build after recipes are available; no UI-frame or
  Work-tick enumeration.
- **Persistence/authority:** runtime-only and identical input discovery on each
  runtime; gameplay use remains server-authoritative.
- **Diagnostics:** inspected, normalized, unsupported, multiple producers,
  source modules, build duration, and generation.
- **Must not depend on:** Research, Work, Facilities, Stockpile, or UI.

### RecipeKnowledgeRegistry

- **Owns:** save-level `id -> stable recipe key` dictionary, schema 1, monotonic
  `nextId`, and runtime-only `key -> id` reverse index.
- **Commands:** lazy ID allocation, import, and revisioned delta application.
- **Queries:** key/ID resolution, export, delta, availability, and diagnostics.
- **Persistence:** `PNC_RecipeKnowledge_V1`; reverse indexes and descriptors are
  excluded. IDs are never recycled. Missing-mod entries resolve as
  `KNOWN_BUT_UNAVAILABLE` and recover if the recipe returns.
- **Must not depend on:** colony state or UI.

### Research

- **Owns:** per-colony authored technology and learned recipe knowledge.
- **Commands:** queue technology, study blueprint, reverse engineer, create a
  debug/API blueprint, and unlock knowledge at completion.
- **Queries:** membership, technology state, and presentation snapshot.
- **Events:** recipe and technology unlock facts.
- **Persistence:** `PNC_Research_V1`, schema 1. Learned recipes are sorted dense
  numeric arrays; O(1) membership sets are rebuilt and never persisted.
- **Authority/network:** server-only mutation. Initial snapshots carry compact
  IDs; later unlocks use ordered `ColonyKnowledgeDelta` messages and request a
  fresh snapshot on a revision gap.
- **Depends on:** RecipeCatalog queries, RecipeKnowledgeRegistry, Work commands,
  and Colony Storage reservation commands.
- **Must not depend on:** client UI or raw ModData consumers.

### Work

- **Owns:** shared Research/Craft/Disassemble Work Orders, worker/station claims,
  status, bounded progress, blockers, and live/abstract handoff.
- **Commands:** queue, assign, add progress/elapsed time, pause, and cancel.
  Player pause/cancel commands validate faction and colony ownership.
- **Queries:** order list and claim/blocker diagnostics.
- **Events:** queued, completed, and cancelled facts.
- **Persistence:** `PNC_WorkOrders_V1`, schema 1. Recipe IDs and compact payloads
  are persisted; runtime objects are excluded. Active claims recover to waiting
  after load and material reservations are rehydrated before reassignment.
- **Lifecycle:** a one-second scheduler processes at most 16 orders. Live bodies
  use the existing order/behavior path to their physical anchor; abstract bodies
  call the same Work Point command with capped elapsed time. Mode changes reset
  elapsed accounting and preserve one logical station claim.
- **Live presentation:** operation-specific Research, Craft, and Disassembly
  animation scenes are requested after arrival; the worker is halted and faced
  toward the station interaction direction while authoritative progress remains
  in Work rather than the animation callback.
- **Retention:** only persisted terminal orders are eligible for pruning; the
  newest 512 are retained for UI/diagnostics and older matching Stockpile
  transaction markers are removed with them.
- **Depends on:** Facilities, NPC Registry, Skills, and operation completion
  handlers. It does not own crafting or research results.

### Facilities and workstations

- **Owns:** physical availability and server-authoritative component/activity
  reservations.
- **Definitions:** Research Facility has one `work.research` station. Workshop
  has independent capacity-one `work.craft` and `work.disassemble` stations.
  Additional parallel Craft work therefore requires another Workshop.
- **Recovery:** claims renew while active. Component/facility removal invalidates
  the reservation; Work releases/reblocks it on the next bounded pass.
- **Progression:** Research Facility is available from HQ progression. Workshop
  construction requires authored technology `facility:workshop`.

### Crafting and Disassembly

- **Owns:** queue validation, known-recipe projection, completion policy,
  provenance, and bounded salvage policy.
- **Craft contract:** consumed inputs and retained tools/catalysts are reserved;
  only consumed inputs are committed. Outputs receive namespaced compact recipe
  provenance and are deposited through Colony Storage.
- **Disassembly contract:** provenance selects the producer; unprovenanced items
  require exactly one producer. Only consumed inputs are salvage candidates.
  The deterministic, retry-stable salvage plan is skill-scaled and capped below
  full refund.
- **Persistence:** Work owns the queue. Colony Storage persists transaction-stage
  markers with inventory state so retries cannot consume or deposit twice.

### Colony Storage production seam

- **Commands:** reserve materials/retained tools, reserve a record, reserve a
  metadata-matching record, commit, release, and deposit products.
- **Queries:** record inspection, availability, active production reservations,
  and persisted transaction stages.
- **Persistence:** transaction stages live beside the authoritative inventory
  snapshot. Runtime reservation tokens are reconstructed from compact Work
  payload requirements after load.
- **Must not expose:** mutable virtual-inventory records to Research/Crafting/UI.

## UI and diagnostics

Research and Workshop are Colony Management tabs. They issue existing
server-routed colony actions and consume snapshots/deltas. Research supports
technology, explicit blueprint/specimen selection, progress, worker, blockers,
pause/cancel, and authorized blueprint debug creation. Workshop supports known
recipe selection, quantity, requirements and current availability, skill gates,
disassembly input selection, queue/station/worker state, pause, and cancel.

Diagnostics cover catalog normalization, registry size/unavailable mappings,
knowledge revision/counts, Work queues/claims/blockers, workstation ownership,
and production material/blueprint/specimen reservations.

## Neat Crafting inspection

The installed reference was located at:

`steamapps/workshop/content/108600/3502080466/mods/Neat_Crafting`

Useful Build 42 patterns confirmed there and against installed vanilla Lua:

- enumerate normal recipes with `ScriptManager.instance:getAllCraftRecipes()`;
- use `getScriptObjectFullType()` as nonlocalized recipe identity;
- inspect `getInputs()`, `getOutputs()`, possible item lists, integer amounts,
  keep/tool flags, required skills, category, module, and craft time;
- normalize defensively because third-party recipes and Java collections can be
  malformed or irregular;
- cache indexes instead of scanning recipes during UI refresh.

No Neat Crafting source or architecture was copied, and it is not a dependency.

## Validation and scale

The isolated harness covers a vanilla recipe, a synthetic generic mod recipe,
and `Base.JB_ChopLog` modeled from the locally installed JBLogging Workshop mod,
unsupported recipes, producer/ingredient indexes, stable/lazy IDs, removal and
re-add, station capacity, skill gates/rates, material contention, cancellation,
exactly-once completion retry, blueprint/reverse-engineering semantics, and
compact storage scale.

The scale harness uses 5,000 persistent recipe keys and 50 colonies with 2,000
learned IDs each: 100,000 compact references with an eight-byte numeric proxy of
800,000 bytes. Growth is proportional to unique referenced keys plus compact
learned IDs, not colonies multiplied by full descriptors.

## Explicitly deferred

- Monolith Decoupler and broad large-file splitting.
- Kitchen and evolved recipes.
- Medical production, repair, advanced assembly, mass production, and
  craft-to-stock automation.
- External Dynamic Trading / ZedColonies integration.
