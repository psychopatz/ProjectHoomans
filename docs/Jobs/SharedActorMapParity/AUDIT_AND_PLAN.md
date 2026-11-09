# Shared actor map parity — audit and implementation plan

## Scope

Make the map and survivor-world behavior provider-agnostic for these supported
profiles:

1. Project Hoomans + DTHoomans, where nearby traders materialize as Hoomans
   NPCs and remote traders remain abstract.
2. Standalone DTAbstract, where traders never materialize and remain abstract.

Both profiles must use the same Core actor, group, settlement, travel,
discovery, map, hover, selection, tracking, and save/reload contracts.

## Agreed architecture

PsychopatzCore is the sole authority for canonical actor identity, group
membership, settlement identity, journey state, route projection, and the actor
map renderer. DTHoomans and DTAbstract differ only in world presence:

- DTHoomans materializes the existing Core actor when nearby and eligible for
  live simulation, then dematerializes it when remote.
- DTAbstract never creates a physical body and always uses the Core abstract
  projection.

The full stable contract is recorded in [ARCHITECTURE.md](ARCHITECTURE.md).

## Audit findings

### Marker taxonomy

- Project Hoomans' `AbstractGroups` layer uses a yellow `SCAVENGER` color and
  draws persistent abstract survivor groups. A yellow square is not evidence of
  a DTHoomans trader or a physical NPC.
- Project Hoomans' `WorldDiscovery` layer draws unresolved settlement and mobile
  group signals. `Located` is a discovery phase, not physical presence.
- DTAbstract's discovery overlay also renders settlement/group/signal knowledge,
  not trader actors. Trader actors must come from the Core actor map and receive
  Dynamic Trading decoration.
- Hoomans community geometry uses a separate `communityDebug` snapshot, so a
  discovered settlement signal and an actual settlement site can currently be
  visible through different data paths.

### DTHoomans path

The intended chain is:

`DTCommon trader -> DTHoomans provider -> Hoomans faction/mobile group -> Core
journey -> Hoomans physical body when nearby -> Core actor projection`

Hoomans' abstract traversal bridge already imports Core journey primitives. The
remaining work is to make the physical controller, materialization handoff,
watchdog, rebase, and arrival lifecycle consume the same Core journey contract
without creating parallel journey truth.

### DTAbstract path

The intended chain is:

`DTCommon trader -> DTAbstract provider -> Core actor/group -> Core abstract
journey -> Core actor-map projection`

This path must work without Project Hoomans loaded. It must never depend on a
Hoomans faction, body, pathing service, or Hoomans-only map layer.

### Debug lifecycle

The map Debug window has a stale singleton defect. Its close path clears the
menu reference but not `PsychopatzMapDebugWindow.instance`; a later open can
reuse an invisible window that has already been removed from the UI manager.
This explains the intermittent Debug-button failure. Existing smoke coverage
does not assert the UI singleton is cleared.

### Performance

The network refresh paths are bounded, but every map render still walks the
registered Core, Hoomans, and Dynamic Trading overlays. Dense maps therefore
pay for repeated marker iteration, world-to-screen transforms, labels, hover
checks, and route lines. A runtime profile is still required before assigning
one definitive hotspot or selecting an optimization budget.

## Implementation phases

### Phase 1 — shared Debug reliability and diagnostics

- Make Debug `Open`/`Close` idempotent and stale-instance-safe.
- Add open-close-open and map-close-reopen regression tests.
- Add a Core marker diagnostic contract containing source, kind, IDs, position,
  discovery phase, presence mode, materialization state, journey state, and
  route availability.
- Keep diagnostics permission-checked and free when disabled.

Gate: Debug reliably opens after repeated use, and every visible marker can be
classified as actor, abstract group, discovery signal, or settlement site.

### Phase 2 — Core journey/controller contract

- Make Core journey ID, progress, route, rebase, arrival, and cancellation
  events the only canonical movement lifecycle.
- Keep Project Zomboid pathfinding and live-body details behind a Hoomans
  controller adapter.
- Preserve the abstract Core controller for DTAbstract.
- Ensure materialization changes presence state only; it never creates a new
  actor or journey.

Gate: abstract and physical actors have identical Core identity and journey
state before, during, and after handoff.

### Phase 3 — provider parity

- DTHoomans: validate nearby materialization, remote dematerialization, body
  lease recovery, physical position authority, and one-time arrival forwarding.
- DTAbstract: validate no-Hoomans loading, permanent abstract projection, route
  interpolation, waits, pause, arrival, and save/reload.
- Make disabled-provider behavior fail closed without breaking Core or the
  remaining provider.

Gate: both profiles produce the same actor-map marker contract; only presence
mode differs.

### Phase 4 — settlement and discovery reconciliation

- Expose one Core settlement/site projection.
- Let Hoomans and Dynamic Trading contribute metadata through adapters.
- Replace ambiguous `Unknown signal` labels with kind, phase, and known identity
  when available.
- Explicitly distinguish discovery knowledge from confirmed settlement geometry.

Gate: settlement signals, sites, traders, and abstract groups cannot be
mistaken for one another in the map or diagnostics.

### Phase 5 — measured performance work

- Instrument overlay time, marker counts, route segments, label counts, snapshot
  sizes, and request counts.
- Add revision-based projection caches and visible-bounds filtering.
- Apply label level-of-detail and bounded route rendering for dense maps.
- Verify that disabled debug layers perform no work.

Gate: dense-map profiling shows bounded work and no provider causes duplicate
actor markers or unbounded refreshes.

## Validation matrix

- Core only.
- Project Hoomans only.
- Project Hoomans + DTHoomans, nearby materialized trader.
- Project Hoomans + DTHoomans, remote abstract trader.
- Core + standalone DTAbstract with Hoomans disabled.
- Both provider packages present but only one owns a trader record.
- Save/reload during travel.
- Arrival and rebase during materialization handoff.
- Repeated map open, Debug open/close, pan, zoom, hover, and tracking.
- Dense populated map with each debug layer disabled and enabled.

## Evidence status

- `CODE_VERIFIED`: Core owns the canonical actor-map engine and exposes the
  provider-neutral travel primitives.
- `CODE_VERIFIED`: Hoomans abstract traversal and DTAbstract use Core travel
  primitives.
- `CODE_VERIFIED`: DTHoomans is registered as a physical provider and routes
  commercial movement through Hoomans mobile-group services.
- `STATIC_ONLY`: physical DTHoomans materialization parity and native map
  performance have not been verified in a live Project Zomboid session.
- `RECORDED_NOT_RERUN`: existing focused and full harness results recorded in
  `PROGRESS.md`.

## Phase 1 implementation result — 2026-11-09

- Core Debug close now clears both the menu and window singleton; `Open` closes
  stale invisible instances before creating or reusing a modal.
- Core `MapMarkerDiagnostics` normalizes bounded provider rows and summarizes
  kind, source, presence, and integration errors. The authorized map Debug menu
  opens a throttled inspector with explicit `MARKER DIAGNOSTICS: ON/OFF` state.
- Core actor diagnostics classify provider lease state as `materialized` or
  `abstract` and retain actor, trader, body, group, community, journey, and
  route fields. Hoomans and DTAbstract register their non-actor marker types
  through the same Core registry.
- Focused implementation tests passed: Core Debug/diagnostics/actor **4/4**,
  Hoomans map **5/5**, and DynamicTrading DTAbstract map/host **4/4**.
- `luac -p`, PZ Kahlua verification, and `git diff --check` passed for the
  changed Lua surfaces. Runtime materialization and dense-map performance are
  still `STATIC_ONLY`.

## Audit execution — 2026-11-09

The architecture scanner covered the Project Hoomans repository with health
80.2, coverage 76.9, confidence 62.5, and pressure 100. Its broad findings
include pre-existing Director/Communities dependency cycles and large domain
functions. Those are not being treated as blockers for this map vertical slice;
the migration will use narrow public contracts rather than refactor unrelated
domains.

Graph and source verification established:

- Core `ActorMap.BuildMarkers` is the canonical marker assembly point. It
  prefers Core actors, deduplicates optional sources by actor ID, and applies
  provider decorators before rendering.
- Core actor rendering is called from the Core map host every map render. The
  actor data and network roster are cached, but screen transforms, hover tests,
  labels, dots, and eligible routes remain per-render work.
- DTCommon joins trader records to Core actor projections and carries journey,
  route, provider state, and body ID into the trader view. A trader without a
  Core actor projection cannot receive the canonical trader marker.
- DTHoomans reads the live Hoomans body position while materialized; otherwise
  it uses the Core abstract world projection. Dematerialization captures the
  body position and rebases the remaining Core journey before provider release.
- DTHoomans starts commercial movement through Hoomans mobile-group services;
  Hoomans' traversal bridge commits the resulting group journey through Core.
  DTAbstract starts and advances its abstract journey directly through Core.

Focused audit tests passed: Hoomans map/travel **7/7**, DynamicTrading
provider/map **9/9**, and Core map/travel/debug **5/5**. These are harness
results, not native UI or FPS proof. Core and Dynamic Trading graph coverage was
partly marked metadata-changed/not-tracked, and several Hoomans map files were
missing coverage records; those findings were verified by direct source reads.

No native game launch, save mutation, Workshop publication, or profiler-setting
change is part of this implementation slice.
