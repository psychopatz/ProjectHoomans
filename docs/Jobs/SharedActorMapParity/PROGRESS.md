# Shared actor map and travel parity — current progress

**Status:** Core actor-map consolidation, the first provider-neutral travel
seam, and the first shared map-diagnostics slice are developer-verified. The
physical Hoomans controller migration, native restart validation, and measured
performance acceptance remain.

## Current developer state

- PsychopatzCore is the sole actor-map engine for canonical actor markers,
  optional sources, deduplication, decorators, caches, overlap handling,
  dots/icons, labels, hover, selection, tracking, hit tests, and routes.
- Core owns the provider-neutral group-journey contract and its lifecycle
  events. DTAbstract uses it directly. Hoomans abstract traversal reaches it
  through the Core group-traversal bridge.
- DTHoomans is the physical provider: it owns Hoomans body/materialization
  hooks and commercial mobile-group execution, but must preserve the same Core
  actor and journey while nearby bodies materialize or remote bodies disappear.
- DTAbstract is permanently abstract and must remain usable without Project
  Hoomans loaded.
- Hoomans still owns the complete Project Zomboid physical travel controller:
  route providers, live pathing, handoff/watchdog behavior, arrival handlers,
  and the public Hoomans travel API. This is the next migration surface, not a
  second permitted map or identity authority.
- Core now exposes one bounded marker-diagnostics registry. Actor rows include
  provider, provider state, body/trader/group/community IDs, presence mode,
  journey state, and route availability. Hoomans registers abstract-group,
  discovery-signal, and settlement-site adapters; DTAbstract registers its
  discovery projection through the same contract.
- The map Debug window now clears both singleton references on close and
  discards stale invisible instances before reopening. An authorized Debug
  entry opens a bounded marker inspector and explicitly reports ON/OFF state.

## Verification

- Core travel contract smoke: **PASS**.
- Core actor-map/presentation/host smokes: **3/3**.
- DynamicTrading abstract provider and handoff focus: **2/2**; full suite:
  **84/84**.
- Hoomans traversal/map focus: **3/3**; full suite: **1009/1011**.
- The two Hoomans failures are the recorded public-function-count boundary
  expectations in `pnc_community_service_presence_boundary_smoke.lua` and
  `pnc_faction_service_presence_boundary_smoke.lua`.
- Kahlua/syntax checks and `git diff --check` passed for the recorded Core,
  Hoomans, and Dynamic Trading travel/map changes.
- Latest focused audit harnesses passed: Hoomans map/travel **7/7**, Dynamic
  Trading provider/map **9/9**, and Core map/travel/debug **5/5**.
- First implementation-slice tests passed: Core Debug lifecycle **2/2**,
  Core marker diagnostics **1/1**, Core actor map **1/1**, Hoomans map focus
  **5/5**, and DTAbstract map/host focus **4/4**.
- `luac -p`, PZ Kahlua verification, and `git diff --check` passed for all
  changed Lua files. The diagnostics inspector refreshes at a 500 ms cadence
  while open and is otherwise inert.
- A fresh whole-Hoomans sweep also stopped on the two recorded public-function
  count boundaries plus an unrelated dirty-tree translation fallback assertion
  (`RAW HOOMANS OVERLAYS` versus the current translation key). The focused map
  suite is the relevant gate for this slice and remains **5/5**.
- Native DTHoomans nearby materialization, remote dematerialization, restart
  faction persistence, and dense-map FPS remain **STATIC_ONLY**.

## Next Chunk

Phase A actor-identity foundation has started in PsychopatzCore. The Core
registry now maintains a canonical/alias resolver, projection entries carry
canonical ID, aliases, presence state, body ID, and capabilities, and active
ungrouped actors are eligible for the shared SurvivorWorld projection. Core
projection mutations also expose a dirty signal for provider-neutral publish
integration. Focused identity, save/reload, projection, transport, map, and
journey tests pass.

Next: wire Project Hoomans and DTHoomans records into the Core identity
extension at adoption/load, then migrate the shared Dynamic Trading
conversation path to resolve aliases before exact projection lookup. Keep the
DTAbstract path on the same resolver with no Hoomans dependency.

## Safety and scope

No Workshop upload, save mutation, native gameplay automation, or profiler
setting change is implied. Existing unrelated worktree changes remain user or
agent-owned and must be preserved.

## Latest implementation slice

The first provider-neutral identity/adoption slice is now implemented and
developer-verified. PsychopatzCore exposes resolver-backed `AttachIdentity` and
`AttachExtension` seams; DTCommon trader presets carry the shared actor identity
extension, conversation capability, and projection hint; DTAbstract's Core
bootstrap and DTHoomans' canonical-actor path preserve that metadata. DTHoomans
also carries the shared SurvivorWorld faction affiliation onto the Core actor,
so its projection does not depend on a provider-specific `dt...` marker lookup.
DynamicTrading conversation now resolves aliases before projection lookup and
permits trade through `dynamictrading.trade`, independent of the actor role.
The common trader-world runtime publishes when Core actor projection state is
dirty, closing the registration/projection race that produced invisible or
untalkable traders.

Focused verification: Core identity/bootstrap/presentation/projection set
**8/8**; DynamicTrading shared identity/conversation/provider/runtime set
**12/12**; `luac -p`, PZ Kahlua verification, and `git diff --check` pass.
Native restart/faction persistence, nearby Hoomans materialization, and dense
map performance remain explicit user-owned acceptance gates. The Hoomans Core
provider now reconciles persisted records that already carry a Core reference
on global-data/server startup, restoring aliases, provider metadata, and
faction affiliation without rewriting IDs. Ordinary existing Project Hoomans
colonists/companions with no stable Core identity still require the planned
explicit adoption pass; this slice does not manufacture duplicate actors.

## Latest implementation slice: shared trader/guard landing

The first conversation vertical slice is now implemented across the sibling
Core and Dynamic Trading repositories. PsychopatzCore owns the new generic
`ActorLanding` builder: it selects a registered semantic greeting, collects
capability-gated actions, and composes one stable `start`/`nodes` landing
definition without naming a provider. DTCommon now consumes that builder for
both trader and guard conversations; DTHoomans and DTAbstract remain access
and presence adapters and still converge on the same DTCommon opener.

The DT semantic pack no longer gates the entire pack behind trade capability.
Trade remains capability-gated, while guard referral and road-rumor actions
are available to the shared landing. This prevents a guard from losing the
Core greeting/conversation surface merely because it cannot open a market.
The old handwritten `nodes.root` landing was removed from the active build
path, and tests now assert stable semantic choice IDs instead of array order.

Focused verification: Dynamic Trading conversation **8/8**, Dynamic Trading
trader suite **19/19**, Core landing smoke **PASS**, PZ Kahlua checks for the
changed Lua files, and `git diff --check` all pass. The package-neutral
semantic harness migration, native guard/trader conversation, and live
performance/restart gates remain open. The pending projection resume
coordinator is now implemented and covered by a dedicated smoke test.

The new Core landing contract is intentionally small. It does not yet replace
the PNC-specific semantic harness generator or generate a DTCommon pack; the
package-neutral CodeBuilder migration is now the next bounded slice. No native
game launch, save mutation, or Workshop publication was performed.

## Latest audit: package-neutral CodeBuilder

The CodeBuilder audit found that the original conversation generator was only
partially owner-aware. Phase 0 now rejects unknown owners and defines Core,
Project Hoomans, and DTCommon descriptors. The first Phase 1 slice routes
generated modules, cleanup, aggregate registry/manifest paths, translations,
CLI configuration, and Semantic Lab preview/write targets through those
descriptors. Compiler prefixes, package-local registry namespaces, capability
catalogs, and DTCommon source-pack generation remain gated for Phase 2 onward.

The detailed findings and phased migration gates are recorded in
`docs/Jobs/SharedActorMapParity/CODEBUILDER_PACKAGE_NEUTRAL_AUDIT_AND_PLAN_2026-11-10.md`.
The existing focused CodeBuilder/compiler baseline was **18/18**. Phase 0 is
now implemented: package descriptors cover Core, Project Hoomans, and DTCommon;
owner normalization rejects unknown values; DTCommon requires explicit
repository configuration; and the manifest records explicit default and
registry ownership. Focused CodeBuilder/compiler verification is **22/22**.

The first Phase 1 routing slice is now implemented: generated modules, cleanup,
aggregate paths, translations, CLI configuration, and Semantic Lab authoring
previews/writes use descriptor routing; a synthetic DTCommon writer fixture
passes. Phase 2 is now implemented: compiler runtime-plan/index prefixes,
registry namespaces, manifest metadata, behavior/beat ownership, and content
preview module labels are descriptor-driven. A DTCommon temporary registry
fixture writes only to the DynamicTrading package-local destination.

Phase 2 verification is green: affected CodeBuilder/authoring **39/39**;
ownership plus continuation **19/19**; context-health **8/8**; semantic
definition **2/2**; content authority **5/5**; C7F precision **2/2**; and
F4/observatory/pragmatic **9/9**. Python compilation, `git diff --check`, and
the architecture-audit diff passed with **0 introduced findings**.

Phase 3 compiler work is implemented: package descriptors now declare
translation-manifest locations and capability catalogs; capability discovery
accepts explicit optional package repositories; and translation bundles and
manifests are partitioned by owning package. Temporary package-neutral
generation/preview passes with **196 artifacts unchanged**, and the focused
ownership/compiler/capability set is **51/51**.

Checked-in artifact regeneration is intentionally pending because Project
Zomboid is currently running and the repository policy forbids in-place writes
under watched `media/` trees during a live session. Next: stop the game,
regenerate Conversation artifacts, rerun modular authoring previews, and run
the Hoomans/Core/Dynamic Trading package matrix.
