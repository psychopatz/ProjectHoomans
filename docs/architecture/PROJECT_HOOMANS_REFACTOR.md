# Project Hoomans Refactor

## Current Chunk

Chunk 3J — Legacy debug-envelope command routing (`[x]`).
Chunk 3 is complete; Chunk 4 is next.

Chunk 0 established the baseline only. No gameplay, network, persistence, or
load-order code changed.

## Master TODO

- [x] Chunk 0 — Baseline and architectural inventory
- [x] Chunk 1 — Standard Project Hoomans domain contract
- [x] Chunk 2 — Composition/bootstrap cleanup
- [x] Chunk 3 — Server command routing
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

Chunk 3J and the server-command routing phase are complete. Chunk 4 should
begin the Needs → Provision → Supply → Inventory pilot vertical slice by
confirming current ownership, writers, queries, commands, persistence, and
runtime budgets before changing behavior. Do not split unrelated monoliths.

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

- Chunk 3J moved the legacy `CMD_DEBUG` compatibility envelope behind one
  explicit handler while preserving its single authorization gate, all action
  strings, early-return semantics, payload mutation, domain/API calls,
  responses, and unknown-action no-op behavior.
- Kept `PsychopatzTeleport` loading at its original `PNC_Server` position and
  injected the loaded mechanism into the registered debug handler, preserving
  initialization timing while making the dependency explicit.
- Grouped the handler's internal action families into cohesive local helpers;
  the final audit introduces no replacement large-function finding.
- `PNC_Server.onClientCommand` now contains only the PNC module-namespace gate
  and canonical router dispatch. The single `Events.OnClientCommand`
  registration remains at its prior location.
- Updated three source-inspection smoke tests to follow the canonical routed
  debug entry and added comprehensive legacy-envelope behavior coverage.
- Chunk 3I added one colony-management network adapter for snapshot and action
  requests while leaving action policy in `PNC.ColonyManagement`.
- Preserved raw action payload identity including nil, `actionResult`
  attachment, the exact twelve-action settlement allowlist, settlement and
  storage delta arguments, full-snapshot fallback, and the existing
  `unknown_colony_action` unavailable-handler result.
- Loaded the adapter deterministically from the canonical server routing entry
  and added focused coverage for all allowlisted settlement actions.
- Chunk 3H added one authority-diagnostics adapter for faction debug/member,
  community debug, Needs debug, and Director debug requests.
- Preserved all four admin gates, exact diagnostic snapshot arguments,
  response flags/reasons, ungated faction membership query behavior, faction
  member action payload identity, and nil-payload normalization.
- Kept snapshot and mutation policy in FactionDebug, FactionMembership,
  CommunityDebug, NeedsDebug, and AbstractDirectorDebug; the adapter only
  translates network requests and responses.
- Loaded the adapter deterministically from the canonical server routing entry
  and added focused authority-diagnostics routing coverage.
- Chunk 3G added one diagnostic-query adapter for debug-roster, relationship,
  conversation-safe relationship, NPC-knowledge, and knowledge-debug requests.
- Preserved multiplayer/SP debug authorization, optional body-audit timing,
  audit metadata, response shapes/reasons, relationship payload identity,
  all-known fan-out, direct-disclosure arguments, and unavailable-service
  reasons.
- Extended the router callback contract with an optional untouched raw payload
  while preserving the normalized second argument. This retains the legacy
  distinction between missing and empty knowledge-debug payloads without
  changing existing handlers.
- Loaded the adapter deterministically from the canonical server routing entry
  and added focused diagnostic routing coverage.
- Chunk 3F added one boundary-level gameplay-request adapter for companion
  orders, map commands, and faction-toll responses without moving policy out
  of their existing domains.
- Preserved companion payload guards and identity, map payload normalization,
  the `source = "network"` context, centralized debug authorization, exact map
  result response command/payload, unavailable-service response, and toll
  payload normalization.
- Loaded the adapter from the canonical ordered server routing entry; no
  bootstrap anchor, composition timing, or event registration changed.
- Added focused gameplay-request routing coverage and updated protocol and
  Networking documentation.
- Chunk 3E added one health/combat adapter for revive, bandage, and
  player-weapon-hit requests.
- Preserved malformed-payload no-op behavior, `args or {}` normalization,
  original weapon-hit payload identity, treatment options, and domain-owned
  authoritative mutation.
- Moved the unchanged debug authorization policy to
  `PNC_ServerCommandRouter.CanUseDebug`; SP still uses the debug flag and
  multiplayer still requires the admin access level.
- Added focused health/combat routing coverage and updated protocol/Networking
  documentation.
- Chunk 3D added one character-replication adapter for full-sync and authorized
  character-detail/inventory-delta requests.
- Moved roster/death-marker list assembly out of `PNC_Server` while preserving
  record order, optional death-marker support, snapshot builders, and broadcast
  behavior.
- Preserved character visibility checks, positive inventory-revision response
  selection, original revision values, unauthorized warnings, and malformed
  request no-op behavior.
- Added focused replication routing coverage and updated protocol/Networking
  documentation.
- Chunk 3C added one conversation adapter for begin/end/ceasefire scene
  commands and category/choice/recruit Authority requests.
- Preserved scene command strings, original command forwarding, `args or {}`
  normalization, optional Authority guards, and domain-owned validation,
  mutations, history, and response construction.
- Added focused routing coverage for scene, category, choice, recruit,
  nil-payload, and unavailable-Authority behavior; updated protocol and
  Networking documentation.
- Chunk 3B added one knowledge/discovery adapter for player bootstrap, NPC
  presentation, knowledge disclosure, and both world-discovery commands.
- Preserved original payload-table identity, `args or {}` normalization,
  knowledge-service validation, discovery action handling, and
  `SendWorldDiscovery` response behavior.
- Added focused handler coverage for all five command identifiers and the
  discovery response path; updated the protocol inventory and Networking docs.
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
- Chunk 3B `luac -p` and Kahlua checks passed for the new handler, routing entry,
  `PNC_Server`, and focused test.
- Seven targeted smoke tests passed: knowledge handler, server router, player
  knowledge commands, world discovery, world-discovery MP client guard, client
  commands, and composition bootstrap.
- Architecture rescan: 579 production files, 182 tests, health 65.0, and 116
  production findings. `PNC_Server` is now 1039 code lines and
  `onClientCommand` is 655 lines; equivalent size findings remain.
- Chunk 3B network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO.
- Chunk 3C `luac -p` and Kahlua checks passed for the conversation adapter,
  routing entry, `PNC_Server`, and focused test.
- Seven actual targeted smoke tests passed: conversation handler, conversation
  authority, conversation safety, conversation integration, debug companion
  recruit, server router, and composition bootstrap.
- Architecture rescan: 580 production files, 183 tests, health 65.0, and 116
  production findings. `PNC_Server` is now 1007 code lines and
  `onClientCommand` is 619 lines; equivalent size findings remain.
- Chunk 3C network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO.
- Chunk 3D `luac -p` and Kahlua checks passed for the replication adapter,
  routing entry, `PNC_Server`, and focused test.
- Six targeted smoke tests passed: character replication handler, network
  scale, client commands, inventory transactions, server router, and
  composition bootstrap.
- Architecture rescan: 581 production files, 184 tests, health 65.0, and 116
  production findings. `PNC_Server` is now 974 code lines and
  `onClientCommand` is 596 lines; equivalent size findings remain.
- Chunk 3D network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO.
- Chunk 3E `luac -p` and Kahlua checks passed for the health/combat adapter,
  command router, routing entry, `PNC_Server`, and focused test.
- Ten targeted smoke tests passed: health/combat handler, character
  replication handler, conversation handler, knowledge handler, server router,
  bandage timed action, bandage context menu, player damage, melee live commit,
  and composition bootstrap.
- Architecture rescan: 582 production files, 185 tests, health 65.0, and 116
  production findings. `PNC_Server` is now 942 code lines and
  `onClientCommand` is 571 lines; equivalent size findings remain.
- Codebase-memory coverage still excludes the production `media` tree; exact
  source reads and focused tests supplied the fallback evidence for this
  chunk. The new test has no recorded index issue but is not freshness-tracked.
- Chunk 3E network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO.
- Chunk 3F `luac -p` and Kahlua checks passed for the gameplay-request adapter,
  routing entry, `PNC_Server`, and focused test.
- Seven targeted smoke tests passed: gameplay-request handler, server router,
  companion commands, map-command service, faction tolls, client commands, and
  composition bootstrap.
- Architecture rescan: 583 production files, 186 tests, health 65.0, and 116
  production findings. `PNC_Server` is now 904 code lines and
  `onClientCommand` is 532 lines; equivalent size findings remain.
- Codebase-memory coverage still excludes the production `media` tree; exact
  source reads supplied fallback evidence. The new focused test has no
  recorded index issue but is not freshness-tracked.
- Chunk 3F network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO.
- Chunk 3G `luac -p` and Kahlua checks passed for the diagnostic adapter,
  router, routing entry, `PNC_Server`, and focused test.
- Fourteen targeted smoke tests passed: diagnostic-query handler, server
  router, body lifecycle, knowledge, player-knowledge commands, relationship
  foundation, relationship graph, client commands, composition bootstrap, and
  all five previously routed server-handler suites selected by the affected
  analysis.
- Architecture rescan: 584 production files, 187 tests, health 65.0, and 115
  production findings. `PNC_Server` is now 793 code lines and no longer has a
  large-module finding; `onClientCommand` is 420 lines and remains a staged
  large-function finding.
- Codebase-memory coverage still excludes the production `media` tree; exact
  source reads supplied fallback evidence. The new focused test has no
  recorded index issue but is not freshness-tracked.
- Chunk 3G network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO.
- Chunk 3H `luac -p` and Kahlua checks passed for the authority-diagnostics
  adapter, routing entry, `PNC_Server`, and focused test.
- Nine targeted smoke tests passed: authority-diagnostics handler, server
  router, faction foundation, community foundation, Needs foundation,
  community Director, faction-member UI, client commands, and composition
  bootstrap.
- Architecture rescan: 585 production files, 188 tests, health 65.0, coverage
  63.0%, and 115 production findings. `PNC_Server` is now 696 code lines and
  `onClientCommand` is 319 lines; the staged large-function finding remains.
- Codebase-memory coverage still excludes the production `media` tree; exact
  source reads supplied fallback evidence. The new focused test has no
  recorded index issue but is not freshness-tracked.
- Chunk 3H network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO.
- Chunk 3I `luac -p` and Kahlua checks passed for the colony adapter, routing
  entry, `PNC_Server`, and focused test.
- Eight relevant smoke tests passed: colony routing, server router, colony
  management, colony-management UI model, settlement foundation, facility
  debug work, client commands, and composition bootstrap.
- `pnc_colony_storage_smoke` deterministically fails its pre-existing journal
  hard-cap assertion (`expected=10`, `actual=14`). It imports no modified
  routing/server modules and no storage or journal file changed in this chunk;
  the failure is recorded rather than expanded into an unrelated fix.
- Architecture rescan: 586 production files, 189 tests, health 65.0, coverage
  63.0%, and 115 production findings. `PNC_Server` is now 660 code lines and
  `onClientCommand` is 282 lines; the staged large-function finding remains.
- Codebase-memory coverage still excludes the production `media` tree; exact
  source reads supplied fallback evidence. The new focused test has no
  recorded index issue but is not freshness-tracked.
- Chunk 3I network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO.
- Chunk 3J `luac -p` and Kahlua checks passed for the debug handler, routing
  entry, `PNC_Server`, and affected tests.
- Eight focused debug/routing smoke tests passed, followed by all eight other
  server-handler suites selected for cross-handler regression coverage.
- Full Lua smoke sweep: 186 passed and 4 failed out of 190. The failures are
  outside modified routing code: the recorded colony journal-cap mismatch;
  a faction-warfare ownership expectation; and missing-module harness errors
  in map-hover portrait and NPC-monitor tracking tests. None of those four test
  files or their cited domain modules changed in Chunk 3J.
- Architecture rescan: 587 production files, 190 tests, health 65.0, coverage
  63.0%, and 114 production findings. Relative to the Chunk 0 baseline, both
  the `PNC_Server` large-module and `onClientCommand` large-function findings
  are resolved with no replacement finding. `PNC_Server` is 320 code lines.
- Codebase-memory coverage still excludes the production `media` tree; exact
  source reads supplied fallback evidence. Modified tests report no recorded
  coverage issue but metadata freshness requires reindexing.
- Chunk 3J network protocol changed: NO. Authority changed: NO. Persistence
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
- Chunk 3 is structurally complete: every inventoried server command family is
  routed, the namespace gate and event registration remain in `PNC_Server`,
  and unknown commands remain no-ops.
- The unrelated colony-storage journal-cap smoke failure described in Chunk 3I
  remains open for its owning storage/journal work rather than being folded
  into command routing.

## Next Chunk

Chunk 4 — begin the Needs → Provision → Supply → Inventory pilot vertical
slice. Confirm current ownership and contracts first, then introduce the
smallest useful command/query boundary without changing persistence, authority,
or runtime budgets.
