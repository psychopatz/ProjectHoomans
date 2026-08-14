# Project Hoomans Refactor

## Tasking Foundation Addendum (2026-08-14)

The first NPC Tasking boundary is documented in
`PROJECT_HOOMANS_TASKING.md`. It adds semantic precedence, runtime task intents,
providers, leases, safe preemption, bounded dirty reevaluation, live/abstract
executors, and lightweight diagnostics. Sleep/Bed is the only migrated gameplay
slice: Needs owns fatigue/rest effects, Facilities owns bed slots, and Tasking
owns arbitration. Research, Crafting, Health/Treatment, and physical Hydration
provider migrations remain explicitly deferred.

## Research and Production Addendum (2026-08-14)

The Project Hoomans Research + Colony Production vertical slice is implemented
and documented in `PROJECT_HOOMANS_RESEARCH_PRODUCTION.md`. It adds runtime
RecipeCatalog indexing, compact save-stable recipe identity, per-colony
knowledge, Research/Workshop facilities and workstations, shared live/abstract
Work Orders, blueprint/reverse-engineering flows, crafting/disassembly, public
Colony Storage reservations with retry-stable transaction stages, revisioned
knowledge deltas, UI, diagnostics, and targeted tests.

Static and isolated-harness validation is green. This addendum does not inherit
the earlier user-confirmed live-SP result: the new feature still requires fresh
SP, hosted-MP, dedicated-server, reconnect, and real-save reload validation.
Monolith Decoupler, broad splitting, Kitchen/evolved recipes, and external
trading integration remain explicitly deferred.

## Current Chunk

Chunk 14 — Final consolidation and compatibility validation (`[x]`).

Chunk 0 established the baseline only. No gameplay, network, persistence, or
load-order code changed.

## Master TODO

- [x] Chunk 0 — Baseline and architectural inventory
- [x] Chunk 1 — Standard Project Hoomans domain contract
- [x] Chunk 2 — Composition/bootstrap cleanup
- [x] Chunk 3 — Server command routing
- [x] Chunk 4 — Pilot vertical slice: Needs → Provision → Supply → Inventory
- [x] Chunk 5 — Pilot evaluation gate
- [x] Chunk 6 — UI boundary migration, incrementally by feature
  - [x] Chunk 6A — Provision Settings request/model/presentation boundary
  - [x] Chunk 6B — Colony Management shell controller/request boundary
- [x] Chunk 7 — Conversation / Relationships / Social
- [x] Chunk 8 — Pathing / Presence / live-body control
- [x] Chunk 9 — Factions
- [x] Chunk 10 — Colony / Settlement / Facilities
- [x] Chunk 11 — Director / abstract simulation
- [x] Chunk 12 — Remaining domains, only where change is justified
- [x] Chunk 13 — PsychopatzCore mechanism-extraction review
- [x] Chunk 14 — Final consolidation and compatibility validation

## Current Goal

All planned architecture chunks are complete. Static and isolated-harness
validation is green, and live SP is user-confirmed. Hosted-MP must be retested
after the pure-client server-file guard fix; dedicated-server and save/reload
validation remain mandatory release gates and are not represented as passed.
The Monolith Decoupler remains deferred to a separately requested pass.

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

- `PNC_Server.lua` remains the authority composition/runtime coordinator, but
  its `onClientCommand` function is now only the module gate and router
  dispatch; routed adapters must continue preserving the protocol contract.
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

- Chunk 14 completed the static consolidation gate. No compatibility path was
  removed: the audit did not prove any remaining adapter obsolete, and removing
  uncertain save, network, or public-API seams would add release risk without a
  demonstrated benefit.
- Fixed the last two Project Hoomans smoke harnesses by preloading dependencies
  that production now requires explicitly: Knowledge Interest for map-hover
  portraits and Provision Diagnostics for NPC-monitor tracking. Production
  behavior was not changed. The complete isolated Lua sweep now passes 193 of
  193 tests.
- Static require resolution checked all 598 executable Lua files across the
  `42.20` and `common` roots. All 588 referenced `PNC/...` module paths resolve.
  All 26 referenced `PsychopatzCore/...` module paths resolve against Core
  `42.19`/`common`. No stale static module target was found.
- The five existing `00_*Init.lua` files are unchanged and remain thin,
  single-require bootstrap anchors. Settlement, Director, and Travel remain
  canonical entries with deterministic internal order, and their composition
  positions match the former inline blocks. Facility Jobs deliberately remains
  later in server composition because its runtime dependencies initialize
  between Settlement and that stage.
- The public/internal review retained four known cross-domain implementation
  seams rather than disguising them as safe cleanup: Network transport helpers
  used by Conversation/Faction/Profiler, Combat action completion used by the
  command registry, Path Service traversal state used by the client native-path
  controller, and Colony Storage commit/activity helpers used by Settlement
  facility costs. These are explicit future boundary candidates, not evidence
  that compatibility can be removed now.
- The Project Zomboid architecture profile reports 83.9/100 health, 70.2%
  coverage, 56.4% confidence, 597 production files, 193 tests, and 130
  production findings. Its 12 subsystem-cycle findings include composition
  anchor relationships, Colony/Inventory, and Conversation/UI. They remain
  heuristic architectural evidence; no runtime dependency was reordered merely
  to eliminate a reported cycle.
- Lua syntax validation passed for all 598 executable files. `pz_verify`
  scanned 592 files (six configured exclusions) and reported zero Kahlua errors
  or warnings at ERROR severity. `git diff --check` is clean.
- Chunk 14 network protocol changed: NO. Authority direction changed: NO.
  Persistence keys/schema/save order changed: NO. Runtime initialization timing
  changed: NO. Public APIs removed: NO. The Monolith Decoupler was not used.
- Live SP startup, hosted-MP startup/replication, dedicated-server startup, and
  save/reload migration validation are **NOT RUN** in this environment. Static
  composition and protocol harnesses reduce risk but do not replace those four
  release checks.
- Post-consolidation live validation: the user confirmed SP works, while a
  hosted-MP client exposed `PNC_Supply.lua:18` (`PNC.NPCSupplyService` was nil)
  followed by four Colony Storage child-module errors where
  `PNC.ColonyStorageService.Internal` was nil. Console evidence showed the pure
  client executing the server composition and later visiting server child files
  independently through `LoadDirBase`.
- Added a pure-client guard to the server composition root, the canonical Supply
  entry, and the four Colony Storage implementation children implicated by the
  runtime trace. The `00_PNC_Server_Init.lua` anchor remains unchanged and thin.
  Hosted and dedicated server execution is preserved because the guard permits
  execution whenever `isServer()` is true.
- Added `pnc_mp_server_file_guard_smoke.lua`. It verifies that the affected
  server files perform no requires or state initialization in a pure client,
  while hosted-server mode still composes and exports the Supply facade. The
  complete suite now passes 194 of 194 tests; all 598 Lua files parse and the
  Kahlua scan remains clean across 592 scanned files (six exclusions).
- Hosted MP after this fix is **RETEST REQUIRED**. Dedicated-server and
  save/reload validation remain **NOT RUN**.
- A second hosted-MP retry exposed the next direct-loader family: all ten
  `PNC_Server*CommandHandler.lua` files were visited independently on the pure
  client and attempted `Router.Register(...)` before the server router existed.
  The command router, routing entry, and complete handler family now use the
  same pure-client gate. Their canonical server require order is unchanged.
- Added reusable `PsychopatzCore.RuntimeRole` in Core common/shared code with
  `IsClient`, `IsServer`, `IsPureClient`, `IsSinglePlayer`,
  `AllowsServerCode`, and `AllowsClientCode`. PsychopatzCore loads it first from
  its existing `00_PsychopatzCore_Init.lua`; `PNC.Core.IsClientOnly` and
  `PNC.Core.IsAuthority` remain compatible delegating APIs.
- Replaced 112 repeated raw Project Hoomans client/server predicates with calls
  to `PsychopatzCore.RuntimeRole.AllowsServerCode`. All 138 ordinary server Lua
  files now share the Core policy rather than duplicating engine-role logic.
  The sole excluded server file is the deliberate `00_PNC_Server_Init.lua`
  anchor; it remains unchanged and delegates to the guarded composition root.
- Added a four-context Core runtime-role smoke (SP, pure client, dedicated
  server, and combined hosted role) and expanded the Hoomans MP direct-loader
  smoke across the routing family. PsychopatzCore now passes 25 of 25 tests,
  including corrected active-version paths in the corpse-item and event-marker
  harnesses. Project Hoomans passes 194 of 194 tests.
- Hosted MP after the reusable Core-role migration is **RETEST REQUIRED**.
  Dedicated-server and save/reload validation remain **NOT RUN**.
- Chunk 13 completed the PsychopatzCore extraction gate without moving code.
  Extraction was treated as an evidence-based decision, not a required outcome:
  a candidate had to be policy-free and have a credible non-Hoomans consumer.
- PsychopatzCore already owns the reusable mechanisms surfaced by prior chunks:
  compact/physical inventory adapters, codecs, reservations and transactions;
  material allocation transactions; grid regions, zones and selectors; square
  rules; event bus, ring buffer and journal storage; responsive UI; profiler;
  radio/trait integrations; teleport; and physical item/corpse boundaries.
  Project Hoomans consumes these while retaining domain policy.
- Travel Route/Projection is reusable in shape, but the bounded adjacent-mod
  search found no consumer in CurrencyExpanded, DynamicColonies,
  DynamicObjectives, DynamicTrading, or MarketSense. Moving it would create a
  speculative Core API before its actual abstraction requirements are known.
- The periodic-job portion of `PNC_Scheduler` is generic-looking but currently
  cohabits with Hoomans NPC timer-wheel scheduling and depends on Hoomans
  constants, identity seeding, and Simulation LOD. Extracting only that portion
  requires an explicit split/API design and a real second consumer; it was not
  folded into this review.
- Simulation LOD, Spatial Index, deterministic population helpers, Travel
  Service, Presence, Director, Knowledge, Relationships, and Map policies remain
  Hoomans-owned. Their records, constants, Registry/Census coupling, authority,
  gameplay state, and lifecycle semantics are not generic mechanisms merely
  because portions of their algorithms are pure.
- Result: no Project Hoomans or PsychopatzCore production file changed in Chunk
  13, no compatibility wrapper was added, and the Monolith Decoupler was not
  used. Future extraction requires a concrete consuming mod and can then define
  the smallest mechanism around both consumers instead of guessing now.
- Six focused PsychopatzCore mechanism smokes passed: events/journals, grid
  regions, inventory framework, material transactions, square rules, and world
  inventory. The full Core sweep was 22 passed and 2 failed out of 24; both
  failures are existing standalone harness paths pinned to obsolete `42.16`
  locations for corpse items and event markers while the active Core version is
  `42.19`. No production code was implicated.
- Project Hoomans Lua was unchanged in this chunk, so Chunk 12's current full
  gate remains 191 passed and 2 known harness-resolution failures, with clean
  syntax/Kahlua verification across 566 files. Live runtime validation remains
  deferred to the final consolidation matrix.
- Chunk 13 network protocol changed: NO. Authority direction changed: NO.
  Persistence/schema changed: NO. Load order changed: NO. PsychopatzCore public
  API changed: NO. Every shared/server/client `00_*Init.lua` anchor remains
  unchanged.
- Chunk 12 ranked the remaining lower-pressure domains rather than applying the
  newest pattern indiscriminately. Knowledge, Scheduling, World Discovery,
  Needs, Conduct, Skills, Registry, Journals, Map Commands, and other small or
  isolated systems have clear ownership and no demonstrated resilience problem,
  so they were intentionally left unchanged.
- Equipment retains its recorded large-module and large-function findings, and
  Travel Directory retains its 126-line projection finding. Addressing either
  would be an explicit decoupling task rather than a load-order fix; both remain
  deferred and the Monolith Decoupler was not used.
- Shared Travel was the sole justified boundary change. Route owns immutable
  geometry; Providers owns pluggable route/speed registries; Arrivals owns
  persistence-safe handler descriptors; Model owns canonical journey creation
  and validation; Projection owns pure advancement/ETA; and Service owns the
  authoritative record lifecycle, dirtying, deltas, and public events.
- Added canonical `PNC/Core/Travel/PNC_Travel.lua`, explicitly preserving the
  original Route → Providers → Arrivals → Model → Projection → Service order.
  Shared composition now requires that entry at the former block's exact
  position between Path Service and Map Command Service. No alphabetical order
  or implicit discovery establishes Travel dependencies.
- Travel record fields, route limits, provider IDs, arrival descriptors,
  projection math, authority checks, Registry dirty domains, roster deltas,
  public `PNC.Travel`/API surfaces, and event names are unchanged. No network or
  persistence schema was introduced.
- Full Lua syntax validation passed. `pz_verify` scanned 566 files with zero
  Kahlua errors or warnings at ERROR severity. Ten focused composition, Travel,
  map-command/layer, navigation, threat, traversal, and abstract-world smokes
  passed; the audit-selected inventory transaction smoke also passed.
- Full Lua smoke sweep remained 191 passed and 2 failed out of 193. The two
  failures are the existing standalone harness module-resolution gaps in map-
  hover portrait and NPC monitor tracking.
- Project-Zomboid-profile architecture rescan: 83.9/100 health, 70.2% coverage,
  597 production files, 193 tests, and 130 production findings. Travel remains
  98.2/100 health with its existing client Directory finding; the canonical
  shared entry introduced no new finding.
- Affected analysis identified Composition, Travel, and tests, selecting the
  inventory transaction smoke transitively. Codebase-memory still excludes
  production `media`; exact source reads, audit evidence, and focused runtime
  harnesses supplied the production fallback.
- Chunk 12 network protocol changed: NO. Authority direction changed: NO.
  Persistence/schema changed: NO. Travel math/semantics changed: NO. Runtime
  initialization order changed: NO. Every shared/server/client `00_*Init.lua`
  anchor remains unchanged. Live SP, hosted-MP, and dedicated-server shared
  startup/travel validation could not be launched here and remains mandatory
  before release.
- Chunk 11 confirmed `PNC_AbstractWorld_v1` as the single Director persistence
  boundary. `PNC_AbstractWorldStore` owns groups, locations, bounded encounter
  reports/cooldowns, and optional population state. The Persistence Coordinator
  retains save ordering; queues, plans, candidate pools, reservations, spatial
  indexes, player positions, rate history, and debug history remain transient.
- Abstract Groups/Locations own strategic records and indexes; Traversal and
  Action Resolver own timer-state transitions; Encounter evaluation/resolution
  and Combat/Casualty/Retreat modules own bounded strategic outcomes. Canonical
  Registry, Health, Wounds, Factions, Communities, Group Needs, Presence, and
  World Discovery remain referenced systems rather than duplicated Director
  state. No physical NPC simulation was added or moved.
- Population Director remains orchestration over bounded sector refresh,
  reconciliation, generation queues, starter population, rate limits, and
  canonical group/settlement generators. `PNC_WorldDirector` remains the sole
  scheduler coordinator and `PNC_Server` retains its established authority-side
  load/initialize/pump timing.
- Added canonical `PNC/Director/PNC_Director.lua`, explicitly preserving all 33
  former server-composition requires. World Discovery remains deliberately
  fourth: it consumes Store → Location → Group foundation state and supplies
  strategic sites before combat, traversal, population, World Director, and
  debug initialization. It was not alphabetized or absorbed as Director-owned
  state.
- Replaced the exact contiguous server-composition block with the canonical
  entry between Need Supply Bridge and Needs Scheduler. Shared Director config/
  types, server callbacks, job registration, startup grace, deterministic
  seeds, budgets, persistence schema, event names, and public `PNC` APIs are
  unchanged. No monolith was split and the Monolith Decoupler was not used.
- Full Lua syntax validation passed. `pz_verify` scanned 565 files with zero
  Kahlua errors or warnings at ERROR severity. Ten focused composition,
  abstract-world, population, community, debug, LOD, persistence, map, and
  travel smokes passed.
- Full Lua smoke sweep remained 191 passed and 2 failed out of 193. The two
  failures are the existing standalone harness module-resolution gaps in map-
  hover portrait and NPC monitor tracking.
- Project-Zomboid-profile architecture rescan: 83.9/100 health, 70.2% coverage,
  596 production files, 193 tests, and 130 production findings. Director now
  reports 98.3/100 health and 81.5% coverage. Its sole finding is the existing
  126-line `Combat.Resolve`; splitting it is deferred to an explicit decoupling
  pass rather than mixed into this ownership phase.
- Affected-test analysis correctly identified only the new Composition/Director
  boundary and could not infer behavioral tests through the composition entry,
  so the documented Director validation matrix was run manually. Codebase-
  memory still excludes production `media`; exact source reads, the audit index,
  and runtime harnesses supplied the production evidence fallback.
- Chunk 11 network protocol changed: NO. Authority direction changed: NO.
  Persistence/schema changed: NO. Deterministic generation changed: NO.
  Scheduler cadence/budgets changed: NO. Physical/live transition behavior
  changed: NO. Every shared/server/client `00_*Init.lua` anchor remains
  unchanged. Live SP, hosted-MP, and dedicated-server startup/save-reload checks
  could not be launched here and remain mandatory before release.
- Chunk 10 confirmed that `PNC_SettlementRepository` owns the version-1 Base,
  Facility, Component, Stockpile Node, and Core Zone store. Base/Facility
  services own authoritative validation and mutation; facility reservations
  remain runtime-only; Facility Jobs owns its bounded `OnTick` work loop; and
  Colony Management plus its routed server handler retain the existing intent,
  ownership, revision, result, snapshot, and requester-only delta boundaries.
- Colony Storage remains a separate faction-owned repository over the
  PsychopatzCore virtual inventory. It owns its existing ModData schema and
  serialized `activityJournal` compatibility key. Research changes the storage
  tier through the authoritative service without changing inventory identity.
  Client Colony Management remains presentation/request code and receives
  bounded snapshots rather than mutable server state.
- Fixed the storage activity hard-cap regression by making
  `PNC_ColonyStorageJournal.MAX_ENTRIES` the single capacity authority used by
  the server journal route. The route had re-registered the same journal type
  with capacity 20 after the compatibility adapter declared/documented 10,
  allowing 14 entries in the smoke scenario. Persistence keys, journal tuple
  format, semantic event IDs, and successful-mutation timing are unchanged.
- Added canonical `PNC/Settlement/PNC_Settlement.lua`. It explicitly reproduces
  the original Repository → Base Validation → Base Service → Facility World
  Validation → Facility Validation → Facility Cost → Facility Service → Target
  Resolver → Reservations → Stockpile Access → Settlement Debug sequence. The
  server composition now requires this entry at the former contiguous block's
  exact position between Community Service and Journal Routes.
- Facility Jobs remains explicitly staged at its existing later composition
  position because it consumes runtime domains initialized between Settlement
  and that point. Colony Storage, Supply, Provision, and Research likewise keep
  their established relative positions. No module was moved merely to make the
  directory look uniform, and the Monolith Decoupler was not used.
- Full Lua syntax validation passed. `pz_verify` scanned 564 files with zero
  Kahlua errors or warnings at ERROR severity. Seven focused storage/journal/
  seed-delta/composition/settlement/facility/management smokes passed.
- Full Lua smoke sweep: 191 passed and 2 failed out of 193. Chunk 10 resolved
  the colony-storage journal-cap failure. The remaining two failures are the
  previously documented standalone harness module-resolution gaps in map-hover
  portrait and NPC monitor tracking.
- Project-Zomboid-profile architecture rescan: 83.8/100 health, 69.1% coverage,
  595 production files, 193 tests, and 130 production findings. Settlement
  reports 99.7/100 health with one low-confidence hot-path event heuristic;
  Facilities reports 100/100 with no finding. The broader Colony/Inventory/
  Composition cycle remains recorded for later semantic analysis.
- Affected-test analysis selected colony storage, journal routes, and seed
  delta as direct dependencies. Codebase-memory still excludes production
  `media`; exact source reads, the audit index, and focused runtime harnesses
  supplied the production evidence fallback.
- Chunk 10 network protocol changed: NO. Authority direction changed: NO.
  Persistence keys/schema changed: NO. Facility reservation or job timing
  changed: NO. The Settlement implementation order is unchanged behind its new
  canonical entry. Every shared/server/client `00_*Init.lua` anchor remains
  unchanged. Live SP, hosted-MP, and dedicated-server startup/save-reload checks
  could not be launched here and remain mandatory before release.
- Chunk 9 added canonical `PNC/Factions/PNC_FactionCore.lua`, explicitly
  preserving the original Telemetry → FactionService → Leadership →
  MembershipService order at the same server composition position.
- Incident ingestion, tactical behavior, tolls, validation, and debug adapters
  remain explicitly staged later because they consume runtime domains loaded
  between those positions. Shared FactionTypes remains after Community and
  Provision types because it normalizes their nested records. No alphabetical
  filename ordering is used as a dependency mechanism.
- Fixed stable-character command ownership for player-controlled factions.
  If the exact player entity key cannot be resolved, command authorization now
  denies access instead of falling back to account username or transient online
  ID. This prevents a replacement survivor on the same account from inheriting
  the dead/previous character's faction companions.
- Companion-command and player-damage cross-domain checks now consume copied
  faction records through `PNC.Factions.Get` rather than reading the mutable
  faction registry directly. Legacy owner fields remain compatible only for
  unaffiliated/legacy companion records.
- Preserved faction ModData key/schema V6, NPC affiliation V2, directed
  relations, treaty invariants, incident aggregation, bounded reconciliation,
  revision rules, server authority, command payloads, and presentation. The
  3,500-line FactionService and other large faction modules were not split; the
  Monolith Decoupler was not used.
- Chunk 8 established `PNC.PathService.Commands` as the canonical mutation
  boundary and `PNC.PathService.Queries` as the read boundary. Existing direct
  methods remain compatible; the canonical reset command intentionally takes
  `(record, zombie, reason)` and adapts to the legacy body-first method.
- Migrated order changes, abstraction, incapacitation, facility arrival,
  behavior halt, and combat hold through the reset command with legacy fallback
  for isolated harnesses/addons. This corrected the combat fallback's reversed
  body/record arguments and removes OrderSystem's direct lane clear during
  normal production composition.
- Added deterministic `PNC_PresenceRuntime.lua`, preserving the prior contiguous
  Admission → MaterializationSafety → Presence order at the same shared
  composition position. `PNC_BodyLifecycle.lua` remains intentionally earlier
  because Health and PathService consume its lifecycle facade.
- Preserved movement algorithms, native/fake locomotion selection, live and
  abstract transitions, engine-object lifecycle, materialization budget,
  scheduler cadence, network traffic, and recovery behavior. The reset boundary
  adds no tick, scan, allocation loop, scheduler wake, path request, or packet.
- Clarified managed-body usefulness ownership: `PNC_LiveBodyControl` alone
  switches between fake/idle suppression and temporary native/action leases.
  The oversized PathService motion and LiveBodyControl implementations were not
  split; the Monolith Decoupler was not used.
- Chunk 7 established `PNC.Relationships.Personal.Queries` and `.Commands` as
  the canonical boundary for directed persisted personal relationships.
  Existing direct methods remain compatibility aliases, while shared tactical
  and faction hostility helpers deliberately remain outside the boundary.
- Conversation rules, server authority, and the social-event service now use
  that personal boundary with direct-method fallback for existing addon and
  isolated-harness compatibility. Server authority, mutation validation,
  schemas, ModData keys, dirty marking, and network payloads are unchanged.
- Preserved the shared and client `00_PNC_Conversation_Init.lua` paths as thin
  early-loading anchors. Their new composition roots reproduce the prior
  dependency order exactly, including the client local-pump registration at
  the same guarded initialization point.
- Added canonical `PNC_ConversationServer.lua`, which explicitly loads History
  before Authority. The server composition delegates to it at the same point
  formerly occupied by those two contiguous requires.
- Documented Conversation authority/history/load order and the distinction
  between persisted personal relationships and shared tactical hostility.
  The oversized Conversation composer and relationship service were not split;
  the Monolith Decoupler was not used.
- Chunk 6B added `PNC.ColonyManagementClient` to the existing canonical client
  entry. It projects one snapshot envelope (`snapshot`, `revision`, and
  `receivedAt`) and owns the unchanged snapshot request call.
- The Colony Management controller now consumes snapshot envelopes and retains
  selection, tab binding, row coordination, and responsive-layout orchestration.
  The window retains input, rendering, refresh timing, and controller
  delegation. Neither reads raw client network state or issues requests
  directly.
- Preserved synchronous SP refresh after an immediately applied request and
  asynchronous MP refresh when replicated revision/receive time advances.
- Preserved the canonical nine-module Colony Management client require order,
  all lazy storage/research controls, tab registry behavior, diagnostics, and
  the existing controller/window file split.
- Added focused boundary coverage for exact canonical load order, snapshot
  projection, stale/new update detection, request result/timing, and source
  enforcement. No new production file or generalized UI framework was added.
- Chunk 6 is complete after two bounded feature migrations. Larger UI findings,
  including Inventory and debug windows, remain with their owning future domain
  or explicit decoupling work rather than becoming a repository-wide UI rewrite.
- Chunk 6A introduced `PNC.ProvisionSettingsClient` as the existing feature's
  explicit client gateway without adding a production file. It owns current
  snapshot/update reads plus the unchanged colony-management snapshot and
  `provision_set` request calls.
- `ProvisionSettingsModel` now owns only the editable policy copy, registry-
  driven defaults, shared pre-validation, permission snapshot, and submission
  construction. Its client dependency is injectable for focused tests.
- `ProvisionSettingsWindow` no longer reads `PNC.Network.ClientState` or calls
  `PNC.Client` directly. It consumes the gateway and retains only layout,
  translated status, refresh timing, and user interaction.
- `ProvisionRulePanel` now uses model operations rather than mutating
  `model.changed` directly and propagates model-set failures to the window.
- Preserved the four-file feature shape and canonical client load chain:
  client composition → settings window → model, rule panel, scroll panel.
  Every file remains below the 2,000-token threshold, so no split or new
  abstraction file was justified.
- Chunk 5 accepted the pilot convention with constraints: canonical entries
  are deterministic composition/navigation seams, direct APIs remain valid,
  and command/query groupings are used only when their semantics are honest.
- Removed Inventory's reverse dependency on Provision. Successful inventory
  deltas now publish `NPC_INVENTORY_CHANGED`; the canonical Provision entry
  subscribes after its scheduler loads and preserves dirty-rule timing.
- The event replaces one direct callback with one protected dispatch per
  successful delta. It adds no recurring tick, scan, queue, persistence write,
  or network message, and prevents a Provision listener failure from escaping
  an already-committed Inventory mutation.
- Evaluated ownership, dependency direction, authority, network, persistence,
  load order, performance, tests, context locality, fragmentation, and
  abstraction in `PROJECT_HOOMANS_PILOT_EVALUATION.md`.
- Typical pilot changes require two to three principal files and approximately
  3,616–5,587 estimated tokens. Four oversized implementation files remain
  recorded for a later explicit decoupling pass; no file was split and the
  Monolith Decoupler was not used.
- Selected Provision Settings for Chunk 6A: its four UI files are each below
  2,000 estimated tokens and already include a model, making it a bounded UI
  boundary migration before any large Inventory-window work.
- Chunk 4 documented the actual two-lane pilot flow:
  `NeedsScheduler → NeedSupplyBridge → NPCSupplyService` and
  `ProvisionScheduler → ProvisionEvaluator → NPCSupplyService`, with both
  lanes reaching canonical Inventory mutation through `SupplyInventory`.
- Added direct command aliases to Inventory and command/query boundaries to
  SupplyInventory. Existing public methods remain callable; the Supply query
  reads explicitly initialized state and returns IDs/descriptors instead of
  mutable inventory records.
- Migrated Supply service mutation calls through `SupplyInventory.Commands`,
  Supply reads through `SupplyInventory.Queries`, and canonical compact
  inventory mutation through `Inventory.Commands`. Hydration-aware legacy
  helpers remain direct methods because they are not read-only queries.
- Added canonical `PNC_Supply.lua` and `PNC_Provision.lua` server domain entry
  files. Each reproduces its prior contiguous implementation-module order with
  explicit deterministic `require(...)` calls.
- Replaced the corresponding contiguous server composition blocks with those
  two domain entries at the same composition position. Needs remains
  deliberately interleaved with Facility Jobs and Director dependencies; its
  timing was documented rather than casually reordered.
- Preserved every shared, server, and client `00_*Init.lua` anchor unchanged.
  Authority gates, persistence ownership and schema, network protocol, event
  registrations, scheduler cadence, work limits, retries, and save timing are
  unchanged.
- Added a focused executable contract for Supply and Provision internal load
  order plus Inventory command/query aliases, and documented pilot ownership,
  persistence, performance, and load-order findings.
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
- Chunk 4 `luac -p` passed for all seven changed/new production Lua files and
  the focused pilot contract test. `pz_verify --kahlua --severity ERROR`
  reported zero errors for all seven production files.
- Seven focused smoke tests passed: pilot domain boundaries, Provision, seed
  delta, Needs foundation, inventory transactions, composition bootstrap, and
  bandage timed action.
- Full Lua smoke sweep: 187 passed and 4 failed out of 191. The failures are
  unchanged from the Chunk 3J sweep: colony-storage journal-cap mismatch,
  faction-warfare ownership expectation, and missing-module harness errors in
  map-hover portrait and NPC-monitor tracking. No cited failing module changed
  in Chunk 4.
- Architecture rescan: 589 production files and 191 tests. The current audit
  reports health 83.5/100, coverage 67.6%, and 129 production findings across
  86 classified subsystems. This classification differs materially from prior
  single-`PNC` scans, so its score delta is not attributed to this pilot.
  Affected analysis is bounded to Composition, Inventory, Provision, and
  Supply; Provision has no findings and Supply retains one large-service and
  one low-confidence hot-path caution.
- Codebase-memory coverage again confirms that production `media` is excluded;
  direct reads, compilation, Kahlua checks, and smoke tests supplied fallback
  evidence. The new pilot test has no recorded coverage issue but is not
  freshness-tracked.
- Chunk 4 network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Event registration timing changed: NO. Existing internal module
  order changed: NO. Composition delegation changed: YES, at the same runtime
  position through deterministic canonical entries.
- Live SP, hosted-MP, and dedicated-server startup could not be launched in the
  current non-game environment. Static load-order contracts pass, but all
  three runtime startup checks remain mandatory before release.
- Chunk 5 `luac -p` passed for the event definition, Inventory mutation module,
  canonical Provision entry, and updated pilot test. `pz_verify --kahlua
  --severity ERROR` reported zero Kahlua errors in the three production files.
- Seven pilot-focused smoke tests passed. Audit-selected journal routes,
  settlement foundation, and seed-delta tests also passed; the selected colony
  storage test reproduced its pre-existing journal-cap failure.
- Full Lua smoke sweep remained 187 passed and 4 failed out of 191, with the
  same four unrelated failures recorded in Chunk 4.
- Architecture rescan remained 83.5/100 health across 589 production files and
  191 tests. Findings increased from 129 to 130 because the audit flags the
  new Inventory event publisher as a low-confidence hot-path risk. The event
  is mutation-driven rather than tick-driven and replaces an existing direct
  callback, so the finding is accepted as heuristic evidence rather than a
  regression. The concrete Inventory → Provision source dependency is gone.
- Exact token-bloat tooling could not run because its optional local `tiktoken`
  dependency is absent. The zero-dependency `pz_verify` estimator supplied the
  recorded four-characters-per-token working-set measurements.
- Codebase-memory still excludes production `media`; exact source reads and
  source tests supplied fallback evidence. The focused pilot test has no
  recorded index gap but is not freshness-tracked.
- Chunk 5 network protocol changed: NO. Authority changed: NO. Persistence
  changed: NO. Scheduler budgets changed: NO. Load-order impact: Provision now
  wires one event subscription after its established internal module order;
  every `00_*Init.lua` anchor remains unchanged.
- Live SP, hosted-MP, and dedicated-server startup remain pending and mandatory
  before release. The static gate passes without treating those modes as
  validated.
- Chunk 6A `luac -p` passed for the three changed production files and updated
  Provision smoke test. `pz_verify --kahlua --severity ERROR` reported zero
  Kahlua errors, and all four Provision UI files remain below 2,000 estimated
  tokens.
- Four focused tests passed: Provision, Colony Management UI model, client
  commands, and composition bootstrap. The Provision test now covers injected
  submission transport, current/stale snapshot reads, snapshot requests, and
  verifies that the window does not bypass its client gateway.
- Full Lua smoke sweep remained 187 passed and 4 failed out of 191, with the
  same unrelated failures recorded in Chunks 4 and 5.
- Architecture rescan: 83.4/100 health, 67.5% coverage, 589 production files,
  191 tests, and 130 production findings. Affected analysis is UI-only and no
  finding was introduced or resolved; the 0.1 displayed health change is
  rounding after added boundary/testable-adapter LOC.
- Codebase-memory production coverage remains excluded; targeted source reads
  supplied the request/response and authority evidence. The modified Provision
  test reports no recorded index gap and matching metadata.
- Chunk 6A network protocol changed: NO. Client authority changed: NO. Server
  validation changed: NO. Persistence changed: NO. Load order changed: NO.
  Every `00_*Init.lua` anchor remains unchanged.
- Chunk 6B `luac -p` and `pz_verify --kahlua --severity ERROR` passed for the
  canonical Colony Management client entry, controller, window, and new focused
  test. The three changed production files remain below 2,000 estimated tokens.
- Five focused tests passed: Colony Management UI boundary, UI model, client
  commands, authoritative Colony Management, and composition bootstrap.
- Full Lua smoke sweep: 188 passed and 4 failed out of 192. The additional pass
  is the new boundary test; the same four unrelated failures remain.
- Architecture rescan: 83.4/100 health, 67.5% coverage, 589 production files,
  192 tests, and 130 production findings. Affected analysis is UI-only with no
  new or resolved finding.
- Codebase-memory production coverage remains excluded. Direct source reads
  supplied the shell, transport, and load-order evidence; existing related tests
  have matching metadata and the new test has no recorded issue.
- Chunk 6B network protocol changed: NO. SP/MP authority changed: NO. Server
  behavior changed: NO. Persistence changed: NO. Internal require order changed:
  NO. Every `00_*Init.lua` anchor remains unchanged.
- Chunk 7 full Lua syntax validation passed, and `pz_verify` scanned 561 files
  with zero Kahlua errors or warnings at ERROR severity.
- Seven focused smokes passed: composition bootstrap, relationship foundation,
  conversation, conversation safety, conversation authority, social events,
  and social profiles.
- Full Lua smoke sweep: 188 passed and 4 failed out of 192. The four failures
  are unchanged and unrelated: colony-storage journal cap, faction same-account
  replacement, and two harness module-resolution gaps in map-hover portrait and
  NPC monitor tracking.
- Architecture rescan: 83.4/100 health, 67.5% coverage, 592 production files,
  192 tests, and 130 production findings. Conversation pressure remains 54.0;
  affected analysis is limited to Composition, Conversation, Relationships,
  and SocialEvent boundaries and introduced no new finding count.
- Codebase-memory coverage confirms the production media tree remains excluded;
  exact source reads and focused runtime harnesses supplied fallback evidence.
- Chunk 7 network protocol changed: NO. Authority direction changed: NO.
  Persistence/schema changed: NO. Runtime initialization order changed: NO.
  The two Conversation `00_*Init.lua` anchors retain their names and timing;
  the three global shared/server/client anchors remain untouched.
- Chunk 8 full Lua syntax validation passed, and `pz_verify` scanned 562 files
  with zero Kahlua errors or warnings at ERROR severity.
- Seventeen focused smokes passed across the new boundary, composition,
  PathService/native planning, simulation LOD, Presence admission/wake/position
  recovery, BodyLifecycle, grounded/fake/vehicle locomotion, orders, facilities,
  combat tactics/commitment, and incapacitated pose.
- Full Lua smoke sweep: 189 passed and 4 failed out of 193. The additional pass
  is the new boundary test; the same four unrelated failures remain.
- Architecture rescan: 83.4/100 health, 67.6% coverage, 593 production files,
  193 tests, and 130 production findings. Pathing pressure remains 29.5 and
  Presence remains 6.9; affected analysis selected the facility debug-work
  smoke as its one direct dependency.
- Codebase-memory production coverage remains excluded. Exact source reads,
  bounded state-writer searches, and focused harnesses supplied fallback
  evidence.
- Chunk 8 network protocol changed: NO. Persistence/schema changed: NO.
  Authority direction changed: NO. Scheduler cadence/budgets changed: NO.
  Movement algorithms changed: NO. No `00_*Init.lua` anchor was modified,
  renamed, or removed.
- Chunk 9 full Lua syntax validation passed, and `pz_verify` scanned 563 files
  with zero Kahlua errors or warnings at ERROR severity.
- Seventeen focused smokes passed: the full faction/emblem/diplomacy/warfare/
  toll/member/debug/target matrix, companion commands, player damage, and
  composition bootstrap.
- Full Lua smoke sweep: 190 passed and 3 failed out of 193. Chunk 9 resolved the
  previous faction-warfare same-account replacement failure. Remaining failures
  are the colony-storage journal cap and two unrelated harness module-resolution
  gaps in map-hover portrait and NPC monitor tracking.
- Architecture rescan: 83.8/100 health, 68.9% coverage, 594 production files,
  193 tests, and 130 production findings. Factions now reports 80.5/100 health
  and 81.5% coverage; the large-module findings remain honestly recorded.
- Codebase-memory production coverage remains excluded. Exact source reads,
  complete focused graph-test pagination, and runtime harnesses supplied the
  evidence fallback.
- Chunk 9 network protocol changed: NO. Persistence/schema changed: NO.
  Authority direction changed: NO. Treaty/incident semantics changed: NO.
  Runtime initialization order changed: NO. No `00_*Init.lua` anchor was
  modified, renamed, or removed.

## Open Issues

- Architecture-audit now classifies production into domain-shaped subsystems,
  but confidence and several coverage categories remain limited. Treat its
  coupling and score changes as triage evidence rather than runtime proof.
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
- The colony-storage journal-cap smoke failure described in Chunk 3I was
  resolved in Chunk 10 by unifying the route and compatibility-adapter capacity
  authority at ten entries.
- Chunk 4 static and harness validation is complete. Live SP, hosted-MP, and
  dedicated-server startup validation remains open because canonical Supply
  and Provision composition entries changed bootstrap delegation.
- The audit still reports a broader Composition/Colony/Inventory cycle after
  the direct Inventory → Provision dependency was removed. Its concrete edges
  require separate owning-domain analysis; it is not expanded into Chunk 6A.
- Provision Settings live SP/hosted-MP UI interaction was not launchable in the
  current environment. The unchanged transport paths and SP fallback are
  covered statically and by smoke tests; live interaction remains a release
  validation item.
- Colony Management live SP/hosted-MP UI interaction was not launchable in the
  current environment. Static tests cover synchronous SP and replicated-update
  MP paths, but live interaction remains a release validation item.
- Large UI modules were not split in Chunk 6. They remain candidates for their
  owning domain chunks or the later explicit decoupling pass.
- Chunk 7 bootstrap changes have static/simulated order coverage, but live SP,
  hosted-MP, and dedicated-server startup validation could not be launched in
  this environment and remains required before runtime release.
- Chunk 8 has static and harness coverage for composition, SP authority paths,
  and MP-native ownership contracts. Live SP, hosted-MP, and dedicated-server
  startup/movement validation remains required before runtime release.
- Chunk 9 has static and harness coverage for exact UUID authority, persistence
  normalization, diplomacy, warfare, and composition. The documented live SP,
  hosted-MP, and dedicated-server faction validation matrix remains NOT RUN and
  is required before runtime release.
- Chunk 11 has static and harness coverage for exact Director composition,
  persistence, deterministic population, bounded scheduling, traversal,
  encounters, LOD, and canonical integrations. Live SP, hosted-MP, and
  dedicated-server Director startup/save-reload validation remains NOT RUN and
  is required before runtime release.
- Chunk 12 has static and harness coverage for exact shared Travel composition,
  route/model/projection behavior, map commands, navigation, and abstract-world
  integration. Live SP, hosted-MP, and dedicated-server shared startup/travel
  validation remains NOT RUN and is required before runtime release.
- Chunk 13 made no production change. Its extraction conclusions are bounded by
  the currently available adjacent mods and must be revisited when a concrete
  second consumer requests one of the deferred mechanisms.

## Next Chunk

No further architecture chunk is scheduled. Retest hosted MP after the
pure-client server-file guard fix, then perform dedicated-server and save/reload
validation. Any monolith decoupling or further module splitting requires a
separate explicit request.
