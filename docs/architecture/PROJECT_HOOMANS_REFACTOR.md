# Project Hoomans Refactor

## Current Chunk

Chunk 3A — Server command protocol inventory and first cohesive handler (`[x]`).
Chunk 3 remains active; Chunk 3B is next.

Chunk 0 established the baseline only. No gameplay, network, persistence, or
load-order code changed.

## Master TODO

- [x] Chunk 0 — Baseline and architectural inventory
- [x] Chunk 1 — Standard Project Hoomans domain contract
- [x] Chunk 2 — Composition/bootstrap cleanup
- [>] Chunk 3 — Server command routing
- [ ] Chunk 4 — Pilot vertical slice: Needs → Provision → Supply → Inventory
- [ ] Chunk 5 — Pilot evaluation gate
- [ ] Chunk 6 — UI boundary migration, incrementally by feature
- [ ] Chunk 7 — Conversation / Relationships / Social
- [ ] Chunk 8 — Pathing / Presence / live-body control
- [ ] Chunk 9 — Factions
- [ ] Chunk 10 — Colony / Settlement / Facilities
- [ ] Chunk 11 — Director / abstract simulation
- [ ] Chunk 12 — Remaining domains, only where change is justified
- [ ] Chunk 13 — PsychopatzCore mechanism-extraction review
- [ ] Chunk 14 — Final consolidation and compatibility validation

## Current Goal

Chunk 3A is complete. Chunk 3B should migrate the next cohesive direct-delegate
command family using the established router contract. Preserve command
identifiers, payloads, validation, authority, responses, side effects,
fallthrough behavior, and registration timing. Do not split unrelated
monoliths.

## Contracts Being Preserved

- Exact shared, server, and client `require` order until a chunk explicitly
  proves a safe change.
- The shared, server, and client `00_*Init.lua` files remain deliberate
  early-loading composition anchors. They must remain thin and must not be
  removed or renamed casually.
- Ordinary implementation modules must not depend on alphabetical filename
  order. Explicit composition roots and canonical domain entry files own
  deterministic dependency-ordered `require(...)` calls.
- `PNC` public tables and callable APIs.
- Network module identifier, command names, payload fields, validation,
  responses, snapshots, and event-registration timing.
- Server authority in MP and the same authority direction in SP.
- ModData keys, schemas, serialized field names, migration behavior, dirty
  tracking, save timing, and retry behavior.
- Existing lazy/optional integration and nil-safe behavior.
- Existing bounded scheduler, spatial, networking, pathing, presence, combat,
  Needs, and Director work.

## SP / MP Risks

- `PNC_Server.lua` is both an authority composition point and runtime
  coordinator; its `onClientCommand` function is a 690-line command boundary.
- `PNC_Client.lua` already delegates inbound server commands through
  `PNC_ClientCommandRouter`; future server extraction must preserve the current
  protocol exactly.
- Shared Lua executes in both runtime modes. Moving a shared module into a
  client/server root can silently change SP or dedicated-server behavior.
- The three ordered bootstrap manifests capture load-order dependencies and
  must be treated as contracts, not unordered module lists.
- Every bootstrap/load-order change requires startup validation in SP, hosted
  MP, and dedicated-server modes; passing only one mode is insufficient.
- Live-body, pathing, combat, inventory, faction, settlement, and world
  simulation changes require explicit SP and MP validation.

## Persistence Risks

- `PNC_PersistenceCoordinator` owns the `OnSave` commit boundary and calls
  domain `Save(false)` operations before `PNC.Registry.FlushDirty()` and
  `GlobalModData.save()`.
- Registry, identity, factions, communities, knowledge, colony storage,
  settlements, abstract world, world discovery, and conversation history have
  separate load or repository ownership.
- Several repositories register `OnInitGlobalModData` directly; the settlement
  repository also registers `OnSave`. Future coordination changes must avoid
  double writes, reordered hydration, lost dirty flags, or schema changes.
- Current documented NPC schema is v15; player, faction, community, and other
  domain stores have independent versions and migration paths.

## Architecture Baseline

Baseline recorded 2026-08-13 against `main` commit
`41fa4b3ce4ff17e1aa7af1b88662abbf56365704`.

- Architecture Audit 2.0.0: production health 65.0/100, coverage 62.9%,
  confidence 52.8%, refactor pressure 100/100.
- Audit inventory: 572 production files, 126,572 scored production LOC, 179
  indexed tests, 3 tooling files, and 1 generated file.
- Findings: 116 production findings (23 large modules, 86 large functions,
  3 possible unbounded loops, and 4 low-confidence hot-path event risks) plus
  2 test-harness candidates.
- The audit currently maps all production code to one logical `PNC` subsystem.
  Its scores are triage evidence and do not establish semantic ownership.
- Executable Lua inventory under the active version root: 547 files / 146,729
  physical lines (`shared` 254 / 59,210; `client` 173 / 51,536; `server` 120 /
  35,983). Physical lines include comments and blanks and therefore differ
  from audit code LOC.
- The codebase-memory generation is `2026-08-13T09:58:16Z` (moderate mode),
  but all production `media` roots are excluded from that graph. Production
  claims in Chunk 0 therefore use the architecture-audit index and targeted
  source reads. The graph is useful for indexed tests but is not currently a
  complete production dependency graph.
- The architecture-audit baseline is stored in the generated
  `.architecture-refactor/index.sqlite` cache.

## Runtime and Boundary Inventory

Active roots were discovered from the current mod layout rather than assumed:

- `Contents/mods/ProjectHoomans/42.20` is the only version directory with
  `mod.info` and owns executable Build 42.20 Lua.
- `Contents/mods/ProjectHoomans/common` owns version-independent declarative
  animation assets and currently contains no executable Lua.
- Shared bootstrap: `shared/PNC/00_PNC_Init.lua`.
- Server bootstrap: `server/PNC/00_PNC_Server_Init.lua`.
- Client bootstrap: `client/PNC/00_PNC_Client_Init.lua`.
- Server network boundary: `PNC_Server.lua` registers `Events.OnClientCommand`
  and owns the current dispatcher.
- Client network boundary: `PNC_Client.lua` registers `Events.OnServerCommand`
  and delegates to the client command router.
- Persistence commit boundary: `PNC_PersistenceCoordinator.lua`; canonical NPC
  record load/dirty persistence begins at `PNC_Registry.lua` and
  `PNC_Persistence.lua`.

Major source-backed domain families include Identity, Inventory, Needs,
Provision, Supply, Health/Combat, Relationships/Social, Conversation,
Factions, Communities, Colony/Settlement/Facilities, Director/Population,
Presence/Pathing, Knowledge, World Discovery/Radio, Research, Orders/Jobs,
Travel, and presentation/UI. These are candidates for ownership analysis, not
pre-approved folder moves.

## Completed This Chunk

- Chunk 3A inventoried all current server command families and legacy
  `CMD_DEBUG` actions in `PROJECT_HOOMANS_SERVER_COMMANDS.md`.
- Added the canonical `PNC_ServerCommandRouting` entry point, thin
  `PNC_ServerCommandRouter`, and inventory command adapter.
- Routed `CMD_INVENTORY_TRANSFER` and `CMD_INVENTORY_ACTION` without changing
  their strings, payload identity, `args or {}` behavior, service validation,
  response behavior, or authoritative mutation owner.
- Kept the `PNC` module namespace gate before router dispatch and retained
  unknown-command fallthrough to the existing dispatcher.
- Kept the single `Events.OnClientCommand` registration in `PNC_Server`.
- Added a focused server-router smoke test and updated Networking documentation.
- Preserved all three `00_*Init.lua` files as thin early-loading anchors.
- Added explicit shared, server, and client composition roots under each
  runtime layer's `PNC/Composition/` directory.
- Moved each prior manifest behind its corresponding anchor without changing
  the order of any existing `require(...)` or composition action.
- Preserved server profiler installation immediately before `PNC_Server` and
  the client EventMarkers binding at its previous manifest position.
- Added a focused bootstrap smoke test covering thin-anchor delegation,
  shared-first server/client composition, server profiler timing, client
  EventMarkers binding, and final runtime-module ordering.
- Updated the system map with the PZ/Kahlua bootstrap contract.
- Added `PROJECT_HOOMANS_DOMAIN_CONTRACT.md` as the minimal migration
  convention for ownership, writers, commands, queries, events, persistence,
  authority, lifecycle, diagnostics, dependencies, failure boundaries, and
  performance.
- Kept public grouping optional: no empty architecture namespaces are required.
- Preserved current direct public methods as valid compatibility contracts.
- Documented shared/client/server as runtime layers rather than logical domain
  boundaries.
- Added the PZ/Kahlua load-order constraint: preserve thin `00_*Init.lua`
  anchors, delegate to explicit composition roots, and require each substantial
  domain through one canonical entry file with deterministic internal ordering.
- Recorded the provisional Needs → Provision → Supply → Inventory pilot
  ownership model and the evidence requirement for deviations.
- Explicitly deferred large-file splitting and Monolith Decoupler use to a
  later dedicated pass.
- Chunk 0 also completed the baseline inventory recorded above.
- Read the system map plus networking and persistence architecture documents.
- Confirmed the active version/common source layout dynamically.
- Identified the shared, server, and client bootstrap manifests.
- Identified server/client command boundaries and principal persistence hooks.
- Read the current audit summary and focused `PNC` inspection.
- Saved the architecture-audit baseline.
- Recorded source, test, LOC, finding, graph-coverage, and runtime-boundary
  evidence without changing production code.

## Validation

- Repository was clean before documentation work.
- Architecture-audit `summary`, `inspect PNC`, and `baseline` commands passed.
- Codebase-memory coverage check explicitly confirmed known gaps for all three
  production Lua scopes; targeted source fallback was completed for each cited
  entry/boundary file.
- Active source-root discovery found exactly one `mod.info` version root.
- No Lua, protocol, persistence, load-order, or test files changed in Chunk 0.
- Chunk 1 changed documentation only; production behavior and public contracts
  remain unchanged.
- Chunk 2 manifest comparison: each composition root after its new comment is
  byte-identical to the corresponding pre-change `00_*Init.lua` manifest.
- `luac -p` passed for all six changed production files and the new smoke test.
- `pz_verify --kahlua --severity ERROR` passed for all six changed production
  files with zero errors or warnings.
- `pnc_composition_bootstrap_smoke`, `pnc_inventory_transactions_smoke`,
  `pnc_inventory_ui_smoke`, and `pnc_mp_replica_transport_smoke` passed.
- Architecture rescan: 575 production files, 180 tests, health 65.0, 116
  production findings; no findings resolved or introduced.
- Network protocol changed: NO. Persistence changed: NO. Event registration
  order changed: NO.
- Live SP, hosted-MP, and dedicated-server startup could not be launched in the
  current non-game test environment and remains an explicit runtime check.
- Chunk 3A `luac -p` and Kahlua checks passed for the router, canonical entry,
  inventory adapter, server composition root, `PNC_Server`, and router test.
- Eight targeted smoke tests passed: server router, inventory transactions,
  inventory UI, teleport, equipment debug, animation-scene debug routes,
  engine path planner, and composition bootstrap.
- Architecture rescan: 578 production files, 181 tests, health 65.0, and 116
  production findings. The prior large-module/function IDs were superseded by
  equivalent findings at 1060 lines and 680 lines; no net finding-count change.
- Chunk 3A network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO.

## Open Issues

- Architecture-audit logical-module configuration does not yet reveal domain
  coupling because all production files are grouped as `PNC`.
- Codebase-memory production exclusion limits graph-backed call/dependency
  analysis until its indexing configuration is corrected and refreshed.
- Large-file findings are deferred. Per user direction, do not use the
  Monolith Decoupler or perform file splitting during the early architecture
  chunks; record candidates for a later dedicated pass.
- SP, MP/dedicated-server, and save/reload runtime checks were not applicable
  to the documentation-only baseline and remain mandatory for production
  chunks.
- Chunk 2 has static/simulated bootstrap coverage but still requires live SP,
  hosted-MP, and dedicated-server startup confirmation before runtime release.
- Chunk 3 remains incomplete: inventory is routed, while all families listed
  under `Remaining Direct Families` in the server command inventory still use
  the legacy dispatcher.

## Next Chunk

Chunk 3B — migrate the next cohesive direct-delegate command family through
the established router, update the command inventory, and validate its exact
protocol and authority behavior. Chunk 3 remains `[>]` until every planned
family is migrated and the legacy dispatcher is thin.
