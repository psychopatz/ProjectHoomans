# Project Hoomans Refactor

## Monolith Decoupler Addendum (2026-09-30)

### Chunk 15 — Semantic response catalog split

The first separately requested Monolith Decoupler migration extracts the
authored deterministic response pools from
`PNC_SemanticDialogueResponseCatalog.lua`. The catalog entry remains the
canonical public seam and continues to own validation, bounded limits,
condition matching, deterministic selection, selection history, text fallback
registration, generated-dialogue extension, and the
`PNC.Semantics.ResponseCatalog` table.

The authored pools now load through three ordered spokes:

- `SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Situational.lua`
  owns greeting and offer pools.
- `SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Questions.lua`
  owns identity, activity, wellbeing, self-state, and relationship-status
  pools.
- `SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Social.lua`
  owns thanks, compliment, acceptance, refusal, gossip, self-reflection,
  identity-evasion, hostile-remark, and threat pools.

The original require path and public API remain unchanged. Generated response
data still extends the built-in pools only after all three spokes load. No
parser, policy, network, persistence, gameplay, translation, or response
selection contract changed.

### Evidence and validation

- The architecture audit identified the original catalog as a 910-code-line
  large-module finding.
- The entry is now 351 physical lines. The three spokes are 101, 310, and 249
  physical lines.
- The response-catalog smoke passed.
- Inventory dialogue smoke passed.
- Clean `HEAD` and the refactored worktree both report the same six failures
  out of 66 semantic tests. The failures concern existing fuzzy parsing,
  generated wellbeing variants, and profanity-pattern expectations.
- Clean `HEAD` and the refactored worktree both report 35 failures out of 783
  full-suite tests. The failures are outside this catalog migration and
  include existing UI, runtime, dependency, persistence, and unrelated
  semantic harness issues.
- `luac -p` passed for the entry and all three spokes.
- `pz_verify` reported zero Kahlua errors for the entry and all three spokes.
- `git diff --check` passed.

### Chunk 16 — Puppet Opera built-in definitions split

The Puppet Opera blueprint entry now owns normalization, runtime validation,
track and timeline access, capability checks, and the public
`PNC.PuppetOpera.Blueprints` registry. Declarative built-in scene definitions
load through
`PNC_PuppetOpera_Blueprints_Builtins.lua` after those APIs are defined.
The existing blueprint require path, registry table, built-in IDs, and runtime
validation behavior remain unchanged.

Validation:

- `luac -p` passed for the entry and built-ins module.
- `pz_verify` reported zero Kahlua errors for both files.
- `git diff --check` passed.

The next safe seam is the companion command registry. It combines registry
mechanics, ownership and permission checks, relay policy, command effects,
group-camp behavior, and protocol-facing execution, so it requires a broader
boundary audit before any split.

### Chunk 17 — Companion command group-camp boundary

Group-camp authority is now isolated in
PNC_CompanionCommandRegistry_GroupCamp.lua. It owns site validation,
recipient admission, bounded diagnostics, group-camp IDs, and group-camp
application. The registry entry retains general eligibility, relay policy,
attack-type application, single-command application, and execution.

Commands.Internal makes the three camp services needed by single-command camp
application explicit without changing the public PNC.CompanionCommands API.
The companion command matrix passed 9/9, client authority passed, group-camp
coordination passed, colony-management section validation passed, and both
command files passed syntax and Kahlua checks.

The remaining command-registry surface requires a separate authority and
protocol audit before further splitting.

### Chunk 18 — Performance diagnostics settings boundary

Central debug-settings registration and startup hydration are now isolated in
`PNC_PerformanceScalingDiagnostics_Settings.lua`. The diagnostics entry retains
counters, timing, logging, gauges, export, and the inventory audit extension.
Settings IDs, disabled-path behavior, optional PsychopatzCore integration,
registration order, and the public diagnostics table remain unchanged.

Validation passed for the performance diagnostics smoke, follower presence
diagnostics smoke, inventory server audit smoke, Lua syntax, Kahlua checks, and
`git diff --check`. The remaining diagnostics runtime and logging surface needs
event-consumer and hot-path ownership mapping before another split.

### Chunk 19 — Companion command registry boundary

Command registration, group registration, lookup, ordered listing, attack-type
normalization, and command-specific eligibility now load through
`PNC_CompanionCommandRegistry_Registry.lua`. The parent entry retains identity
and ownership checks, proximity and radio authority, follow-order preparation,
attack application, group-camp integration, command application, and protocol
execution.

The original registry require path and public `PNC.CompanionCommands` methods
remain unchanged. The 9/9 companion command matrix, client authority, group-camp
integration, colony-management sections, syntax, Kahlua, and diff checks pass.
The remaining authority and execution surface requires a protocol-aware audit.

### Chunk 20 — Companion command authority boundary

Companion identity, ownership, live-position resolution, proximity eligibility,
and radio relay policy now load through
`PNC_CompanionCommandRegistry_Authority.lua`. The parent entry retains order
preparation, equipment and attack application, command application, group-camp
integration, and protocol execution. Live-position access is exposed through
the existing internal command seam for the closest-target path.

The original public authority methods and their signatures remain unchanged.
The companion matrix, client authority, group-camp, colony-management, syntax,
Kahlua, and diff checks pass. The remaining command application and execution
surface needs a protocol-aware audit before another boundary.

### Chunk 21 — Companion command execution boundary

Target selection, scope handling, closest-target resolution, group dispatch, and
result shaping now load through
`PNC_CompanionCommandRegistry_Execution.lua`. The parent entry retains the
single-record application pipeline and its order, equipment, network, and
runtime mutation effects. The original `Commands.Execute` entry point and
return shapes remain unchanged.

The 9/9 companion matrix, client authority, group-camp, colony-management,
syntax, Kahlua, and diff checks pass. The command entry is now limited to
application orchestration; no further split is planned until the protocol and
late-callback paths receive a broader runtime audit.

### Chunk 22 — Companion command application boundary

Single-record command application, follow-order preparation, attack-type
effects, equipment refresh, runtime command metadata, and network broadcast
now load through `PNC_CompanionCommandRegistry_Application.lua`. The original
registry file is now a 25-line composition root that initializes the public
namespace and loads registry, authority, application, group-camp, and execution
providers in order.

`Commands.Apply` keeps its original signature, return values, authority guard,
side-effect order, and public namespace. The 9/9 companion matrix, client
authority, group-camp, colony-management, syntax, Kahlua, and diff checks pass.
The remaining group-camp implementation is intentionally retained as its own
larger provider pending a separate protocol and bounded-directory audit.

### Chunk 23 — Group-camp details boundary

Primitive-only group-camp response serialization now loads through
`PNC_CompanionCommandRegistry_GroupCampDetails.lua`. It owns bounded text and
number normalization, compact site details, task-lease snapshots, and the
target detail list. Group-camp validation, recipient admission, coordinator
fallback, order installation, and network effects remain in the group-camp
provider.

The `CampCommandDetails` internal seam preserves the existing response shape
and bounds. Group-camp integration, the 9/9 companion matrix, syntax, Kahlua,
and diff checks pass. The remaining provider is retained until its coordinator
and bounded-directory paths receive a broader runtime audit.

### Chunk 24 — Group-camp recipient admission boundary

Bounded group-camp recipient selection now loads through
`PNC_CompanionCommandRegistry_GroupCampRecipients.lua`. It owns ownership
verification, materialized-live checks, explicit target-ID normalization,
legacy registry fallback, duplicate suppression, radius eligibility, and stable
ID ordering. Site validation, coordinator fallback, order installation, and
network effects remain in the group-camp provider.

The internal recipient seam preserves the existing admission rules and the
maximum 32-target bound. Group-camp integration, the 9/9 companion matrix,
syntax, Kahlua, and diff checks pass.

### Chunk 25 — Group-camp application boundary

Coordinator invocation, compatibility fallback, group-camp ID generation,
order installation, runtime mutation, and network broadcast now load through
`PNC_CompanionCommandRegistry_GroupCampApplication.lua`. The group-camp entry
retains site validation and the shared internal seams; details and recipient
admission remain separate providers.

`Commands.ApplyGroupCamp` keeps its original signature, return shapes, authority
guard, coordinator fallback, and bounded response behavior. Group-camp
integration, the 9/9 companion matrix, syntax, Kahlua, and diff checks pass.

### Chunk 26 — Performance diagnostics runtime boundary

Runtime metric sampling, bounded runtime summaries, frame and path breakdown
recording, gauge refresh, profiler export, and snapshots now load through
`PNC_PerformanceScalingDiagnostics_Runtime.lua`. The diagnostics entry retains
persistent state initialization, counter and timing primitives, opt-in event
logging, and the inventory audit extension. `Diagnostics.Internal.TimingNow`
preserves the existing timing source without expanding the public namespace.

The original diagnostics require path and every `Diagnostics.*` method remain
unchanged. Performance diagnostics, follower presence, and inventory audit
smokes pass; `luac -p`, Kahlua validation, and `git diff --check` pass. The
full suite remains at the clean-worktree baseline of 35 failures out of 783.

### Chunk 27 — Performance diagnostics audit logging boundary

Opt-in network, seating, sleep, zombie aggro, NPC threat, firearm, needs,
follower, and build audit formatting now load through
`PNC_PerformanceScalingDiagnostics_AuditLogging.lua`. The provider also owns
seating and sleep snapshots plus build trace correlation. Channel state and
startup registration remain in the diagnostics entry and settings provider;
the public diagnostics table and existing runtime overrides are unchanged.

The focused audit matrix passed 11 of 12 selected tests; the remaining
`pnc_zombie_aggro_stimulus_smoke` failure is the same known baseline harness
failure seen in the full suite. Syntax, Kahlua validation, and diff checks pass.

### Chunk 28 — Facility behavior arrival and scene boundary

Facility behavior positioning, seat or sleep surface preparation, scene
admission, and animation request startup now load through ordered Arrival and
SceneStart providers. The reduced Tick provider retains activity admission,
water source resolution, camp safety, and retry handling, then delegates the
arrival and scene phases through existing internal seams. The public behavior
entry path and `Internal.Tick` contract remain unchanged.

The facility behavior focused matrix passed 9/9 before the service slice and
8/8 after it; syntax, Kahlua validation, and diff checks passed. The full suite
returned to the clean-worktree baseline of 35 failures out of 783 after the
server inventory guard was reviewed for the new provider.

### Chunk 29 — Facility service durable state boundary

Durable facility activity state creation, normalized executor order
installation, live-object bookkeeping, and start diagnostics now load through
`PNC_FacilityJobs_Service_StartState.lua`. The Start provider retains authority
checks, facility and activity acquisition, target normalization, and the public
`Jobs.Start` and `Jobs.StartForFacility` entry points. The provider loads before
Start from the existing server service composition root and is gated by the
server runtime role.

The service API, persisted field names, order shape, return values, and load
order remain unchanged. The facility and service focused matrix passed 8/8;
syntax, Kahlua validation, and diff checks passed. The server-only inventory
guard was reviewed from 759 to 760 Lua files for this provider.

### Chunk 30 — Facility service manual-start orchestration boundary

Manual activity command orchestration for food, hydration, sleep, world water,
and water refill now loads through
`PNC_FacilityJobs_Service_ManualStart.lua`. The existing ManualTargets provider
retains personal-supply checks, live-position assignments, home and camp
acquisition, and route-level resource resolution. `H.ManualStart` keeps its
existing arguments, result shapes, and four direct callers. The composition
root loads the new provider before the manual toggle consumer.

The focused matrix passed 8/8, the full suite remained at the established
35-failure baseline out of 783, and syntax, Kahlua validation, and diff checks
passed. The reviewed server Lua inventory advanced from 760 to 761 files.

### Chunk 31 — Facility service manual water boundary

World hydration and container-refill route acquisition now load through
`PNC_FacilityJobs_Service_ManualWater.lua`. The provider owns route selection,
hydration-plan validation, refill assignment, and the legacy
`H.ManualNearbyWaterActivity` compatibility alias. ManualStart keeps the same
internal calls and result behavior.

The focused matrix passed 10/10, the full suite remained at 35 failures out of
783, and syntax, Kahlua validation, and diff checks passed. The reviewed server
Lua inventory advanced from 761 to 762 files.

### Chunk 32 — Facility service manual sleep boundary

Home and camp sleep acquisition now load through
`PNC_FacilityJobs_Service_ManualSleep.lua`. It owns the camped-NPC branch,
bounded nearby sleep acquisition, home fallback, and sleep policy metadata.
ManualTargets retains personal-supply checks and local-position assignments;
the public and internal activity contracts remain unchanged.

The focused matrix passed 10/10, the full suite remained at 35 failures out of
783, and syntax, Kahlua validation, and diff checks passed. The reviewed server
Lua inventory advanced from 762 to 763 files.

### Chunk 33 — Facility resources seating boundary

Seating geometry, live-object rehydration, and the seat detector now load
through `PNC_FacilityResources_Seating.lua`. The resource entry retains world
scanning, bed and sofa detectors, capacity and selection behavior. A small
`Resources.Internal` seam supplies descriptor-key and object-iteration helpers;
public resource methods and detector order remain unchanged.

The seating/resource focused matrix passed 6/6. The isolated
`pnc_facility_resources_smoke` and `pnc_composition_bootstrap_smoke` failures
match the established baseline. The full suite remained at 35 failures out of
783; syntax, Kahlua validation, and diff checks passed. The reviewed server Lua
inventory advanced from 763 to 764 files.

### Chunk 34 — Facility resources scan boundary

World scanning and facility cache lifecycle now load through
`PNC_FacilityResources_Scan.lua`. The provider owns detector ordering,
descriptor-key normalization, `ScanRegion`, `Refresh`, `Invalidate`,
`GetScan`, and `GetResources`; detector registration remains on the root
resource table. It loads before the seating provider, preserving the public
resource namespace and detector order. The root is now 616 lines, the scan
provider is 217 lines, and the seating provider is 340 lines.

The resource provider matrix passed 7/7 targeted consumer checks. The
facility-resource smoke retains its established sofa-detector baseline
failure. Full suite remained 35 failures out of 783; syntax, Kahlua
validation, coverage, and diff checks passed. Server Lua inventory advanced
from 764 to 765 files.

### Chunk 35 — Facility resources capacity and selection boundary

Capacity normalization, detected capacity, sleep capacity, reservation-aware
slot checks, sleep-target validation, physical selection, and virtual-resource
fallbacks now load through
`PNC_FacilityResources_CapacitySelection.lua`. The provider preserves the
public resource capacity, binding, and selection methods. Snapshot activity
rehydration uses two internal virtual-resource helpers; scan, capacity, and
seating providers load in dependency order. The resource root is now 301
lines; the scan provider is 217 lines; the capacity and selection provider is
341 lines; the seating provider is 340 lines.

The targeted resource consumer matrix passed 7/7. The facility-resource
smoke retains its established sofa-detector baseline failure. Full suite
remained 35 failures out of 783; syntax, Kahlua validation, coverage, and
diff checks passed. Server Lua inventory advanced from 765 to 766 files.

### Chunk 36 — Command hub child branch boundary

The command hub child controller now keeps lifecycle policy in
`PNC_CommandHub_ChildController.lua` and loads the ten concrete window
adapters from `PNC_CommandHub_ChildController_Branches.lua`. The root retains
the public child-controller methods, close ordering, active branch state,
opacity propagation, and position synchronization. The branch provider owns
each child window's open, close, focus, visibility, and sync contract. A small
`Controller.Internal` table carries only the UI helpers across the provider
boundary. The root is now 334 lines and the branch provider is 286 lines.

The command hub UI matrix passed 13/13. Syntax, Kahlua validation, coverage,
and diff checks passed. The next safe seam remains the remaining UI
service-executor surface.

### Chunk 37 — Command hub registry category boundary

Command category ordering, category definitions, zone actions, and stockpile
bootstrap presentation now load through
`PNC_CommandHub_Registry_Categories.lua`. The registry root retains client
gate calculations, child and window action adapters, tracing, and the public
`PNC.CommandHub.Registry` and `PNC.CommandHub.Gates` namespaces. A small
`RegistryInternal` seam supplies the category provider's resolved actions and
gate functions. The root is now 477 lines and the category provider is 245
lines.

The command hub UI matrix remained 13/13. The full suite remained 35 failures
out of 783, matching the established baseline. Syntax, Kahlua validation,
coverage, and diff checks passed. The next safe seam is command hub gate and
action-adapter policy.

### Chunk 38 — Command hub gate policy boundary

Eligibility snapshots, stockpile material checks, colony/base/stockpile gates,
disabled-tooltip policy, and radio detection now load through
`PNC_CommandHub_Registry_Gates.lua`. The registry root retains action adapters,
tracing, and the public `PNC.CommandHub.Gates` namespace. Public gate methods
and return shapes are unchanged. The root is now 276 lines; the gate provider
is 215 lines; the category provider remains 245 lines.

The latest command hub/UI matrix passed 16/16. The full suite remained 35
failures out of 783, matching the established baseline. Syntax, Kahlua
validation, coverage, and diff checks passed. The next safe seam is the
remaining command hub action-adapter policy.

### Chunk 39 — Command hub action adapter boundary

Optional child, work, zone, journal, colonist, storage, research, base, and
scavenge routing now load through
`PNC_CommandHub_Registry_Actions.lua`, together with the stockpile bootstrap
callbacks. The root retains composition and the public registry tables; the
provider writes the existing `RegistryInternal` callbacks consumed by category
registration. The root is now 26 lines; the action provider is 266 lines.

The latest command hub/UI matrix passed 16/16. The full suite remained 35
failures out of 783, matching the established baseline. Syntax, Kahlua
validation, coverage, and diff checks passed. The next safe seam is the
remaining UI service executor surface.

### Chunk 40 — Zone window state service boundary

Colony snapshot reads, revision tracking, action-result translation, request
timing, and deferred selector startup now load through
`PNC_CommandHub_ZoneWindow_Service.lua`. The zone window retains rendering,
input, public `ZoneUI.Open`/`Close`/`CloseAll`/`SyncPositions` methods, and
window lifecycle behavior. The root is now 401 lines; the service provider is
123 lines.

The latest command hub/UI matrix passed 16/16. The full suite remained 35
failures out of 783, matching the established baseline. Syntax, Kahlua
validation, coverage, and diff checks passed. The next safe seam is the
remaining UI service executor surface.

### Chunk 41 — Command hub settings action boundary

Settings reset, theme cycling, action-panel branch changes, apply handling,
and cross-window opacity propagation now load through
`PNC_CommandHub_SettingsWindow_Actions.lua`. The settings window retains field
creation, population, rendering, and the public `SettingsUI` lifecycle. A
small `SettingsInternal` seam carries only the settings dependencies and
presentation helpers. The root is now 488 lines; the action provider is 138
lines.

The latest command hub/UI matrix passed 16/16. The full suite remained 35
failures out of 783, matching the established baseline. Syntax, Kahlua
validation, coverage, and diff checks passed. The next safe seam is the
remaining UI service executor surface.

### Chunk 42 — Facility build catalog boundary

Facility option normalization, cost availability, recipe metadata, technology
prerequisites, stockpile state, and production skill selection now load through
`PNC_SettlementManagement_FacilityBuildCatalog.lua`. The modal retains card
rendering, window layout, input handling, snapshot refresh, and the public
`PNC.FacilityBuildUI.BuildOptions` entry point. The modal root is now 769 lines;
the catalog provider is 336 lines.

The latest facility build/catalog matrix passed 23/23. The full suite remained
35 failures out of 783, matching the established baseline. Syntax, Kahlua
validation, coverage, and diff checks passed. The next safe seam is the
facility build card rendering boundary.

### Chunk 43 — Facility build card boundary

The reusable facility card, native multi-tile preview compositor, text fitting,
and card rendering now load through
`PNC_SettlementManagement_FacilityBuildCard.lua`. The modal keeps window
interaction and consumes the existing `BuildUI.FacilityCard` and
`BuildUI.DrawNativePreview` exports. The modal root is now 484 lines; the card
provider is 306 lines.

The latest facility build/card matrix passed 22/22. The full suite remained 35
failures out of 783, matching the established baseline. Syntax, Kahlua
validation, coverage, and diff checks passed. The next safe seam is the
facility build window interaction boundary.

### Chunk 44 — Facility build interaction boundary

Build confirmation, debug-material requests, build-error presentation, snapshot
refresh, and the public `BuildUI.Open`/`Reopen` lifecycle now load through
`PNC_SettlementManagement_FacilityBuildInteraction.lua`. The modal retains
class setup, responsive layout, card composition, category selection, and the
public `PNC.FacilityBuildUI` table. The modal root is now 365 lines; the
interaction provider is 150 lines.

The latest facility build interaction matrix passed 22/22. The full suite
remained 35 failures out of 783, matching the established baseline. Syntax,
Kahlua validation, coverage, and diff checks passed. The next safe seam is the
remaining facility window presentation/state surface.

### Chunk 45 — Facility build presentation boundary

Child-control construction, responsive layout, category navigation, selection
state, and description rendering now load through
`PNC_SettlementManagement_FacilityBuildPresentation.lua`. The modal root keeps
only namespace setup, class lifecycle, and composition requires. The modal root
is now 97 lines; the presentation provider is 302 lines.

The latest facility build/presentation matrix passed 24/24. The full suite
remained 35 failures out 783, matching the established baseline. Syntax, Kahlua
validation, coverage, and diff checks passed. The next safe seam is the Base
building catalog data/presentation boundary.

### Chunk 46 — Base building recipe state boundary

Facility recipe filtering, native recipe identity and favorite state, local
catalog reconstruction, stockpile pricing, and the public recipe catalog
wrappers now load through `PNC_BaseBuildingCatalog_Recipes.lua`. The Buildings
tab keeps its list controls, preview, layout, row presentation, placement, and
queue behavior. The catalog root is now 896 lines; the recipe provider is 156
lines.

The focused recipe/building matrix passed 12/12. The full suite remained 35
failures out of 783, matching the established baseline. Syntax, Kahlua
validation, coverage, and diff checks passed. The next safe seam is Puppet
Opera normalization internals.

### Chunk 47 — Puppet Opera normalization boundary

Blueprint input normalization, actor and anchor validation, track lowering, and
timeline-node compilation now load through
`PNC_PuppetOpera_Blueprints_Normalization.lua`. The public blueprint entry keeps
registry composition, runtime capability checks, lookup, listing, and the
`Registry.Normalize`/`Register` contracts. The registry root is now 253 lines;
the cohesive normalization provider is 571 lines.

The Puppet Opera focused matrix passed 18/18. Full suite remained 35 failures
out of 783, matching the established baseline. Syntax, Kahlua validation,
coverage, and diff checks passed. The next safe seam is the Puppet Opera
authority runtime boundary.

### Chunk 48 — Puppet Opera authority guard boundary

Distance and range checks, unsafe NPC action-state guards, actor admission
validation, and movement ownership validation now load through
`PNC_PuppetOpera_Authority_Guards.lua`. The authority root retains session
state, composition wiring, and the public authority contract. Existing
`Authority.Internal` guard names remain unchanged. The authority root is now
114 lines; the guard provider is 257 lines.

The Puppet Opera focused matrix passed 18/18. The full suite remained 35
failures out of 783, matching the established baseline. Syntax, Kahlua
validation, coverage, and diff checks passed. The lifecycle extraction is
recorded in the next chunk.

### Chunk 49 — Puppet Opera authority lifecycle boundary

Client delivery, phase transitions, session indexing, actor release, close,
and abort now load through
`PNC_PuppetOpera_Authority_Lifecycle.lua`. The authority root retains the
session tables, public API, and ordered composition requires. The root is
114 lines, the guard provider is 257 lines, and the lifecycle provider is
197 lines. Existing `Authority.Internal` lifecycle keys remain unchanged.

Puppet Opera and MP server-file guard focused tests passed 19/19. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The runtime
timeline extraction is recorded in the next chunk.

### Chunk 50 — Puppet Opera runtime timeline boundary

Timeline lookup, node selection, animation ownership, and per-node animation
observation now load through
`PNC_PuppetOpera_Authority_Runtime_Timeline.lua`. The runtime root retains
phase progression and session pumping. The root is 232 lines and the timeline
provider is 238 lines. Its `Authority.Internal` handoff is loaded by the
guarded runtime provider.

Puppet Opera and MP server-file guard focused tests passed 19/19. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the Puppet Opera phase pump/transition boundary.

### Chunk 51 — Puppet Opera runtime phase boundary

Movement, facing, beat preparation, and playback phase handlers now load
through `PNC_PuppetOpera_Authority_Runtime_Phases.lua`. The runtime root keeps
safety checks, override maintenance, session dispatch, and the public pump
entry. The runtime root is 232 lines, the timeline provider is 238 lines, and
the phase provider is 271 lines. Existing phase pump handoffs remain under
`Authority.Internal`.

Puppet Opera and MP server-file guard focused tests passed 19/19. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the Puppet Opera runtime safety/session dispatch boundary.

### Chunk 52 — Puppet Opera runtime safety boundary

Active actor safety, movement and action-state validation, ownership checks,
and lease renewal now load through
`PNC_PuppetOpera_Authority_Runtime_Safety.lua`. The runtime root keeps
override maintenance, phase dispatch, timeout handling, and the public pump
entry. The root is 113 lines and the safety provider is 144 lines.

Puppet Opera and MP server-file guard focused tests passed 19/19. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the Puppet Opera runtime override maintenance/session dispatch
boundary.

### Chunk 53 — Puppet Opera runtime dispatch boundary

Override maintenance, phase dispatch, timeout handling, and the public pump
entry points now load through
`PNC_PuppetOpera_Authority_Runtime_Dispatch.lua`. The runtime root is a 25
line dependency-ordered composition entry; the dispatch provider is 111
lines. Existing `Authority.Pump`, `Authority.PumpSession`, and internal
handoffs remain unchanged.

Puppet Opera and MP server-file guard focused tests passed 19/19. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the Puppet Opera authority admission boundary.

### Chunk 54 — Puppet Opera authority admission boundary

NPC and blueprint resolution, actor readiness, and preflight planning now
load through `PNC_PuppetOpera_Authority_Admission_Preflight.lua`. Session
construction, NPC lease acquisition, movement startup, and authoritative
start requests now load through
`PNC_PuppetOpera_Authority_Admission_Session.lua`. The admission root is a
21 line composition entry; the providers are 347 and 297 lines. The original
admission require path and `Authority.Internal` contracts remain unchanged.

Puppet Opera and MP server-file guard focused tests passed 19/19. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the Puppet Opera authority request boundary.

### Chunk 55 — Corpse haul work adapter diagnostics boundary

Durable operation diagnostics, throttled logging, and failure metadata now
load through
`PNC_CorpseHaulService_WorkAdapter_Diagnostics.lua`. The work adapter keeps
the existing `Service.Internal` diagnostic handoff and task failure behavior.
The diagnostics provider is 104 lines.

Corpse haul focused tests and the MP server-file guard passed 5/5. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The targeting
extraction is recorded in the next chunk.

### Chunk 56 — Corpse haul work adapter targeting boundary

Live and abstract target selection, drop-point validation, world wait state,
and work-scene status observation now load through
`PNC_CorpseHaulService_WorkAdapter_Targeting.lua`. The work adapter keeps
transfer effects, cleanup, and tick orchestration. The work adapter root is
875 lines; the targeting provider is 145 lines.

Corpse haul focused tests and the MP server-file guard passed 5/5. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the corpse haul work adapter state/transfer boundary.

### Chunk 57 — Corpse haul work adapter cleanup boundary

Live route reset, carried-corpse preservation, marker cleanup, runtime index
release, and work-sequence reset now load through
`PNC_CorpseHaulService_WorkAdapter_Cleanup.lua`. These effects remain one
boundary so a terminal operation cannot release only part of its ownership.
The work adapter root is 741 lines; the cleanup provider is 152 lines.

Corpse haul focused tests and the MP server-file guard passed 5/5. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the corpse haul work adapter transfer/completion boundary.

### Chunk 58 — Corpse haul work adapter transfer boundary

Live corpse movement, durable completion, cancellation recovery, deferred
world effects, and completion retry handling now load through
`PNC_CorpseHaulService_WorkAdapter_Transfer.lua`. The work adapter keeps
worker tick progression and service registration. The work adapter root is
443 lines; the transfer provider is 342 lines.

Corpse haul focused tests and the MP server-file guard passed 5/5. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the corpse haul work adapter tick/registration boundary.

### Chunk 59 — Corpse haul work adapter tick boundary

Live phase advancement, abstract progress, worker release, interaction
timeouts, carry progression, and transfer handoff now load through
`PNC_CorpseHaulService_WorkAdapter_Tick.lua`. The work adapter root remains
the ordered composition point for provider loading, public registration,
cancellation wiring, and world effect registration. The root is now 227
lines; the tick provider is 257 lines. Existing `Service.Internal` handoffs
and Work registration names remain unchanged.

Corpse haul focused tests and the MP server-file guard passed 5/5. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the corpse haul service composition/reconciliation boundary.

### Chunk 60 — Corpse haul dispatch boundaries

Automatic corpse selection and background order creation now load through
`PNC_CorpseHaulService_Dispatch_Assignment.lua`. Manual request validation,
order reuse, immediate reevaluation, and request diagnostics now load through
`PNC_CorpseHaulService_Dispatch_Manual.lua`. The original `Dispatch.lua`
require path remains the composition point and keeps terminal-order pruning;
its root is 56 lines, with 135 line assignment and 385 line manual providers.
The existing `Internal` functions and public `Service.RequestManual` entry
remain unchanged.

Corpse haul focused tests and the MP server-file guard passed 5/5. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the corpse haul reconciliation candidate and active-order boundary.

### Chunk 61 — Corpse haul reconciliation candidate boundary

Corpse discovery, identity scoring, reservation rebinding, duplicate cleanup,
and reservation marker cleanup now load through
`PNC_CorpseHaulService_Reconciliation_Candidates.lua`. The original
`Reconciliation.lua` path remains the active reconciliation composition point
and keeps pending world-effect handling, legacy completion recovery, order
retirement, and bounded active scanning. The root is now 352 lines; the
candidate provider is 366 lines. Existing reconciliation `Internal` entry
points remain unchanged.

Corpse haul focused tests and the MP server-file guard passed 5/5. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the active corpse haul reconciliation boundary.

### Chunk 62 — Corpse haul active reconciliation boundary

Pending world effects, legacy completion recovery, durable retirement,
reconciliation diagnostics, and bounded active-order scans now load through
`PNC_CorpseHaulService_Reconciliation_Active.lua`. The original
`Reconciliation.lua` path remains a 14 line composition root that loads the
candidate provider before the active provider. The active provider is 356
lines; the candidate provider remains 366 lines. Existing pending-effect and
active-order `Internal` entry points remain unchanged.

Corpse haul focused tests and the MP server-file guard passed 5/5. The full
suite remains 35 failures out of 783, matching the established baseline.
Syntax, Kahlua validation, coverage, and diff checks passed. The next safe
seam is the Puppet Opera authority request boundary.

### Chunk 63 — Puppet Opera authority request boundary

Session lifecycle actions now load through
`PNC_PuppetOpera_Authority_Requests_Session.lua`. Preflight, snapshot, and
trace actions now load through
`PNC_PuppetOpera_Authority_Requests_Readonly.lua`. The original Requests
module keeps authorization, response dispatch, acknowledgement fallback, and
the public `Authority.HandleRequest` entry. The root is 106 lines; session
and read-only providers are 121 and 79 lines. Existing request action names
and error response contracts remain unchanged.

Puppet Opera request, multi-actor, transport, and MP server-file guard tests
passed 4/4. The full suite remains 35 failures out of 783, matching the
established baseline. Syntax, Kahlua validation, coverage, and diff checks
passed. The next safe seam is the Puppet Opera authority bootstrap boundary.

### Chunk 64 — Puppet Opera authority response boundary

Server/client command delivery, state snapshots, and structured error
responses now load through
`PNC_PuppetOpera_Authority_Lifecycle_Response.lua`. The lifecycle module
keeps phase transitions, session indexes, actor release, and close behavior;
its root is 158 lines and the response provider is 66 lines. Existing
`Authority.Internal` response helpers and command payloads remain unchanged.

Puppet Opera request, multi-actor, transport, and MP server-file guard tests
passed 4/4. The full suite remains 35 failures out of 783, matching the
established baseline. Syntax, Kahlua validation, coverage, and diff checks
passed. The next safe seam is the Puppet Opera public pump/registration boundary.

### Chunk 65 — Puppet Opera authority context boundary

Shared authority time, tracing, owner identity, and debug authorization now
load through `PNC_PuppetOpera_Authority_Context.lua`. The authority root keeps
namespace setup, ordered provider loading, and final event/router
registration. The root is 78 lines and the context provider is 60 lines;
existing `Authority.Internal` context handoffs remain unchanged.

Puppet Opera request, multi-actor, transport, and MP server-file guard tests
passed 4/4. The full suite remains 35 failures out of 783, matching the
established baseline. Syntax, Kahlua validation, coverage, and diff checks
passed. The next safe seam is the Puppet Opera public pump/registration
boundary.

### Chunk 66 — Facility resources activity boundary

Activity resource-key resolution and authoritative live-body materialization
now load through `PNC_FacilityResources_Activity.lua`. The provider preserves
`Resources.ResolveActivityTarget` and `Resources.ApplyMaterializationTarget`,
while the 208-line resource root remains the public composition entry and
loads scan, capacity, seating, and activity providers in dependency order.

The facility resources, roaming-floor-seat, semantic-camp-site, and MP
server-file guard gates ran 3/4: the facility resource smoke retains its
established sofa-detector baseline failure, and the other three gates passed.
The full suite remains 35 failures out of 783. Whole-tree Lua parsing,
Kahlua validation for the five FacilityResources Lua files, and
`git diff --check` passed. The next safe seam is the Facility Jobs service
durable start-state provider.

### Chunk 67 — Facility Jobs durable activity-state boundary

The durable facility activity start path now delegates state construction to
`PNC_FacilityJobs_Service_StartState_Activity.lua` and normalized executor
order construction to `PNC_FacilityJobs_Service_StartState_Order.lua`.
`PNC_FacilityJobs_Service_StartState.lua` is now a 72-line composition
provider that keeps record mutation, live-object bookkeeping, diagnostics, and
the existing `H.InstallActivity` return contract.

The facility activity ownership, recovery, debug-work, manual-command, camp
sleep, sleep-placement, sleep-transition, hydration, service presence, and MP
server-file guard gates passed 10/10. The full suite remains 35 failures out of
783. Whole-tree Lua parsing, Kahlua validation for the FacilityJobs service
providers, coverage review, and `git diff --check` passed. The next safe seam
is the FacilityResources snapshot and registration boundary.

### Chunk 68 — Facility resources snapshot and detector boundary

Read-only facility component snapshots now load through
`PNC_FacilityResources_Snapshot.lua`, and bed/sofa detector registration now
loads through `PNC_FacilityResources_Detectors.lua`. The public resource root
is now 95 lines and retains `CopyDescriptor`, `Register`, `GetDetector`, the
shared object-iteration seam, and ordered provider loading.

The resource, roaming-floor-seat, semantic-camp-site, and MP server-file guard
gates ran 3/4: the resource smoke retains its established sofa-detector
baseline failure, and the other three gates passed. The full suite remains 35
failures out of 783. Whole-tree Lua parsing, Kahlua validation for the new
providers, coverage review, and `git diff --check` passed. The next safe seam
is the Puppet Opera public pump and registration boundary.

### Chunk 69 — Facility service start-targeting boundary

Target normalization, live-object lookup, approach-candidate copying, sleep
target validation, and start-context construction now load through
`PNC_FacilityJobs_Service_Start_Targeting.lua`. The public Start provider is
now 101 lines and retains authority checks, facility acquisition, activity
replacement, `Jobs.Start`, and `Jobs.StartForFacility`; the targeting provider
is 165 lines and returns the existing context fields to `H.InstallActivity`.

The focused facility activity, manual-command, sleep, hydration, service
presence, and MP server-file guard gates passed 10/10. The full suite remains
35 failures out of 783. Whole-tree Lua parsing, Kahlua validation for the
FacilityJobs service providers, coverage review, and `git diff --check` passed.
The next safe seam is the Puppet Opera public pump and registration boundary.

### Chunk 70 — Puppet Opera NPC ownership adapter boundary

`PNC_PuppetOpera_OverrideAdapter.lua` is now a composition root for the
stable `PNC.PuppetOpera.Override` contract. Shared ownership facts and
reservation discovery load through `PNC_PuppetOpera_Override_Context.lua`;
readiness and safety checks through `PNC_PuppetOpera_Override_Readiness.lua`;
reservation heartbeat through `PNC_PuppetOpera_Override_Maintenance.lua`;
and acquire/release restoration through
`PNC_PuppetOpera_Override_Lifecycle.lua`. The public methods
`IsOwned`, `GetState`, `GetReadiness`, `CanAcquire`, `Maintain`, `Acquire`,
and `Release`, the `puppetOperaOverride` runtime field, reservation timing,
continuation fields, and server-only guard remain unchanged.

The focused Puppet Opera and MP server-file guard matrix passed 6/6. The full
suite remains 35 failures out of 783, matching the established baseline.
Whole-tree Lua parsing, Kahlua validation for the Puppet Opera server tree,
coverage review, and `git diff --check` passed. The next ranked seam is the
Lumber execution provider, pending a bounded call-graph review.

### Chunk 71 — Lumber execution boundary

The 1,128-line `PNC_LumberService_Execution.lua` is now a 21-line
composition root. `PNC_LumberService_Execution_OutputCapture.lua` owns
durable output-effect creation and world-item capture;
`PNC_LumberService_Execution_OutputDelivery.lua` owns abstract inventory
delivery, live pickup, and stockpile deposit;
`PNC_LumberService_Execution_TreeWork.lua` owns live and abstract tree
progression; and `PNC_LumberService_Execution_Dispatch.lua` owns target
selection, tick dispatch, and bounded runtime diagnostics. The original
`Service.TickJob` entry point and the LumberService `Internal` handoff remain
stable, with providers loaded in capture, delivery, tree-work, dispatch order.

The Lumber service, executor, WorkAdapter, and MP server-file guard matrix
passed 4/4. The full suite remains 35 failures out of 783, matching the
established baseline. Whole-tree Lumber Lua parsing, Kahlua validation,
coverage review, and `git diff --check` passed. The next ranked seam is the
Lumber WorkAdapter and deferred world-effect bridge.

### Chunk 72 — Lumber WorkAdapter boundary

`PNC_LumberWorkAdapter.lua` is now a 25-line composition root for the stable
work contract. Live and abstract target execution, completion, cancellation,
and worker state transitions load through
`PNC_LumberWorkAdapter_Lifecycle.lua`; durable order creation, cancellation,
reconciliation, and Work registration load through
`PNC_LumberWorkAdapter_OrderBridge.lua`; and deferred tree removal plus the
`LUMBER` and `TREE_REMOVE` world-effect providers load through
`PNC_LumberWorkAdapter_WorldEffects.lua`. The original public methods
`Target`, `Execute`, `Complete`, `Cancel`, `EnsureOrder`, `CancelOrder`, and
`Reconcile`, Work registration names, and world-effect contracts remain
unchanged.

The WorkAdapter root and providers total 504 lines after the split. The
Lumber service, executor, WorkAdapter, and MP server-file guard matrix passed
4/4. The full suite remains 35 failures out of 783, matching the established
baseline. Whole-tree Lua parsing, Kahlua validation, coverage review, and
`git diff --check` passed. The next ranked seam is the Lumber deferred
world-effect authority boundary.

### Chunk 73 — World-effect service boundary

The 638-line `PNC_WorldEffectService.lua` is now a 41-line composition root.
Shared time, world lookup, persistence, and effect-shape access load through
`PNC_WorldEffectService_Context.lua`; provider and handler registration plus
durable indexes load through `PNC_WorldEffectService_Registry.lua`; bounded
retry and loaded-square reconciliation load through
`PNC_WorldEffectService_Reconciliation.lua`; debug rows and bounded snapshots
load through `PNC_WorldEffectService_Snapshot.lua`; and the work-order provider
and event hooks load last through `PNC_WorldEffectService_Bootstrap.lua`.
The public `PNC.WorldEffectService` methods, provider and handler tables,
schema fields, load-square retry behavior, optional husk diagnostics, and
original require path remain unchanged.

The world-effect, Lumber, corpse-haul, and MP server-file guard matrix passed
10/10. The full suite remains 35 failures out of 783, matching the established
baseline. Whole-tree Lua parsing, Kahlua validation, coverage review, and
`git diff --check` passed. The next ranked seam is the Puppet Opera
acknowledgement delivery boundary.

### Chunk 74 — WorkService queue and claim boundary

`PNC_WorkService_QueueAndClaims.lua` is now a 21-line composition root.
Durable order creation and operation-default location policy application load
through `PNC_WorkService_Queue.lua`; worker/station claim release, order
recovery lookup, and safe restoration checks load through
`PNC_WorkService_Claims.lua`. The original `PNC.WorkService.Commands.Queue`
signature remains available through thin root wiring, while the internal
`releaseClaim`, `assignedOrderForRecord`, and `restoreOrderIsSafe` handoffs
remain stable for command, scheduler, progress, and worker-reconciliation
consumers. The original WorkService require path and provider order remain
unchanged.

The focused production and WorkService matrix passed 14/14. The full suite
remains 35 failures out of 783, matching the established baseline. Whole-tree
Lua parsing, Kahlua validation, coverage review, and `git diff --check` passed.
The next ranked seam is the Puppet Opera acknowledgement delivery boundary.

### Chunk 75 — WorkService scheduler boundary

`PNC_WorkService_Scheduler.lua` is now a 25-line composition root. Durable
order processing, quarantine guards, worker location transitions, and live or
abstract execution handoff load through
`PNC_WorkService_Scheduler_Orders.lua`; bounded reconciliation, priority
ordering, terminal-history pruning, diagnostics, and the scheduler pump load
through `PNC_WorkService_Scheduler_Pump.lua`. The original `Service.Tick`
entry point remains available through thin root wiring, the OnTick hook stays
at the composition boundary, and the WorkService require path and internal
handoffs remain unchanged.

The focused production, WorkService presence, recovery, and MP guard matrix
passed 9/9. The full suite remains 35 failures out of 783, matching the
established baseline. Whole-tree Lua parsing, Kahlua validation, coverage
review, and `git diff --check` passed. The next ranked seam is the Puppet
Opera acknowledgement delivery boundary.

### Chunk 76 — WorkService progress and completion boundary

`PNC_WorkService_Progress.lua` is now a 37-line composition root. Input
collection and assignment load through
`PNC_WorkService_Progress_Inputs.lua`; ordinary progress and elapsed-time
accounting load through `PNC_WorkService_Progress_Accounting.lua`; ordinary
completion and deferred world-effect finalization load through
`PNC_WorkService_Progress_Completion.lua`. The public `CollectInputs`,
`Assign`, `AddProgress`, `AddElapsed`, and `CompleteDeferred` command
signatures remain available through thin root wiring. The internal completion
handoff remains available to accounting, and existing WorkService consumers
continue to use the same public commands and load order.

The focused production, WorkService, corpse-haul, Lumber, and MP guard matrix
passed 12/12. The full suite remains 35 failures out of 783, with zero new or
resolved failures against the established scheduler baseline. Whole-tree Lua
parsing, Kahlua validation, coverage review, and `git diff --check` passed.
The next ranked seam is the Puppet Opera acknowledgement delivery boundary.

### Chunk 77 — WorkTaskProvider execution boundary

`PNC_WorkTaskProvider.lua` is now a 19-line composition root. Shared fatigue,
assignment, and lease-phase policy loads through
`PNC_WorkTaskProvider_Context.lua`; candidate discovery and assignment load
through `PNC_WorkTaskProvider_Assignment.lua`; lease cancellation, completion,
and recovery snapshots load through `PNC_WorkTaskProvider_Lease.lua`; and the
live or abstract execution handler dispatch loads through
`PNC_WorkTaskProvider_Execution.lua`. The original provider table, callback
names, watchdog recovery contract, `work` registration, and server-only guard
remain at the original require path.

The focused tasking, WorkService, Lumber, corpse-haul, and MP guard matrix
passed 12/12. The full suite remains 35 failures out of 783, with zero new or
resolved failures against the established baseline. Whole-tree Lua parsing,
Kahlua validation, coverage review, and `git diff --check` passed. The next
ranked seam is the Puppet Opera acknowledgement delivery boundary.

### Chunk 78 — TaskRequest command and snapshot boundary

`PNC_TaskRequestService.lua` is now a 15-line composition root. Player task
mutation and authorization commands load through
`PNC_TaskRequestService_Commands.lua`; the unified work, medical, lease, and
facility activity read model loads through
`PNC_TaskRequestService_Snapshots.lua`. The original `Commands` and `Queries`
tables, cancellation and pause/resume/retry command names, snapshot shape,
and server-only guard remain at the original require path.

The focused TaskRequest, colony snapshot, semantic task, and MP guard matrix
passed 8/8. The full suite remains 35 failures out of 783, with zero new or
resolved failures against the established baseline. Whole-tree Lua parsing,
Kahlua validation, coverage review, and `git diff --check` passed. The next
ranked seam is the Puppet Opera acknowledgement delivery boundary.

### Chunk 79 — Tasking recovery boundary

`PNC_Tasking_Recovery.lua` is now a 37-line composition root. Watchdog state,
provider refresh, movement recovery observation, and recovery snapshots load
through `PNC_Tasking_Recovery_Context.lua`; retry and quarantine policy loads
through `PNC_Tasking_Recovery_Retry.lua`; stalled-lease recovery loads through
`PNC_Tasking_Recovery_Stall.lua`; and executor-failure recovery loads through
`PNC_Tasking_Recovery_Executor.lua`. The existing internal recovery methods,
watchdog domains, retry counters, quarantine behavior, and load path remain
unchanged.

The focused Tasking recovery, budget, priority, event, cancellation, sleep,
and MP guard matrix passed 8/8. The full suite remains 35 failures out of
783, with zero new or resolved failures against the established baseline.
Whole-tree Lua parsing, Kahlua validation, coverage review, and
`git diff --check` passed. The next ranked seam is the Tasking pump
orchestration boundary.

### Chunk 80 — Tasking pump orchestration boundary

`PNC_Tasking_Pump.lua` is now a 68-line composition root. Shared timing and Puppet ownership helpers load through `PNC_Tasking_Pump_Context.lua`; orphan activity reconciliation loads through `PNC_Tasking_Pump_Reconciliation.lua`; bounded event inbox reevaluation loads through `PNC_Tasking_Pump_Evaluation.lua`; bounded executor and recovery dispatch loads through `PNC_Tasking_Pump_Execution.lua`. The original `Tasking.Commands.Pump` entry point, interval and budget behavior, initialization events, Puppet suspension and materialization behavior, recovery ordering, semantic ActionPlan pump, diagnostics, load path, and server-only guards remain unchanged. The focused pump, recovery, presence, priority, event inbox, cancellation, sleep, Puppet Opera transport, and MP guard matrix passed 9/9. The full suite remains 35 failures out of 783 with no new or resolved failures against the established baseline. Whole-tree Lua parsing, Kahlua validation, graph coverage review, and `git diff --check` passed. The next ranked seam is Tasking lease lifecycle ownership.

### Chunk 81 — Task lease lifecycle boundary

`PNC_TaskLeaseService.lua` is now a 42-line composition root. Phase normalization and transition policy load through `PNC_TaskLeaseService_Context.lua`; creation and active-index ownership load through `PNC_TaskLeaseService_Creation.lua`; lookup and invariant queries load through `PNC_TaskLeaseService_Queries.lua`; cancellation policy loads through `PNC_TaskLeaseService_Cancellation.lua`; reservation release and terminal cleanup load through `PNC_TaskLeaseService_Release.lua`. The original `PNC.TaskLeaseService` table, public Create, RequestCancellation, Get, ForNPC, SetPhase, Release, CheckInvariants, and Count methods, phase transitions, cancellation deferral, reservation cleanup, active indexes, events, and server-only loading remain unchanged. The focused lease, Tasking, work-pipeline, recovery, Puppet Opera, and MP guard matrix passed 13/13. The full suite remains 35 failures out of 783 with no new or resolved failures against the established baseline. Whole-tree Lua parsing, Kahlua validation, graph coverage review, and `git diff --check` passed. The next ranked seam is Tasking operation-adapter handoff.

### Chunk 82 — WorkService operation registry boundary

`PNC_WorkService_OperationRegistry.lua` is now a 61-line provider loaded explicitly by the WorkService composition root and by the Core compatibility path. It owns the eight registration methods for completion, completion recovery, preparation, collection, target providers, live execution, abstract execution, and reconciliation. Core retains eligibility, worker selection, shared internal helpers, and handler-map initialization. The original WorkService registration methods, handler tables, direct Core load path, dependency order, and server-only loading remain unchanged. The focused WorkService presence, production, construction, crafting, research, lumber, workstation, corpse, camp, and MP guard matrix passed 12/12. The full suite remains 35 failures out of 783 with no new or resolved failures against the established baseline. Whole-tree Lua parsing, Kahlua validation, graph coverage review, and `git diff --check` passed. The next ranked seam is WorkService target/provider handoff.

### Chunk 83 — WorkService target/provider boundary

`PNC_WorkService_Targets.lua` is now a 12-line composition root. Target-provider and collection handoff loads through `PNC_WorkService_Targets_Providers.lua`; station and worker claim orchestration loads through `PNC_WorkService_Targets_Claim.lua`. The original `WorkService.Internal` target helpers, target-provider selection, collection behavior, station claims, live order projection, direct target-service load path, dependency order, and server-only loading remain unchanged. The focused WorkService presence, target, location, production, construction, crafting, research, lumber, workstation, corpse, camp, and MP guard matrix passed 13/13. The full suite remains 35 failures out of 783 with no new or resolved failures against the established baseline. Whole-tree Lua parsing, Kahlua validation, graph coverage review, and `git diff --check` passed. The next ranked seam is WorkService worker reconciliation.

### Chunk 84 — WorkService worker reconciliation boundary

`PNC_WorkService_WorkerReconciliation.lua` is now a 22-line composition root. Durable worker and station claim index rebuilding loads through `PNC_WorkService_WorkerReconciliation_Claims.lua`; stale NPC runtime and order-state recovery loads through `PNC_WorkService_WorkerReconciliation_State.lua`. The original `WorkService.ReconcileWorkerState` entry point, repository reload, claim ordering and repair behavior, stale worker cleanup, registry events, direct reconciliation load path, dependency order, and server-only loading remain unchanged. The focused WorkService presence, production lifecycle, target, location, production, construction, crafting, research, lumber, workstation, corpse, camp, and MP guard matrix passed 13/13. The full suite remains 35 failures out of 783 with no new or resolved failures against the established baseline. Whole-tree Lua parsing, Kahlua validation, graph coverage review, and `git diff --check` passed. The next ranked seam is WorkService worker reconciliation follow-up only if a separate release-policy boundary emerges; otherwise the next safe scope is the Puppet Opera acknowledgement delivery boundary.

### Chunk 85 — Social damage adapter boundary

`PNC_SocialEventHooks_DamageAdapter.lua` is now a 14-line composition root. Shared combat event context and delivery helpers load through `PNC_SocialEventHooks_DamageAdapter_Context.lua`; social damage and witness recorders load through `PNC_SocialEventHooks_DamageAdapter_Recorders.lua`; vanilla damage snapshots and polling load through `PNC_SocialEventHooks_DamageAdapter_Polling.lua`. The original `SocialEventHooksInternal` damage callbacks, relationship event payloads, witness delivery, vanilla marker state, engine callback registration, direct adapter load path, dependency order, and server-only loading remain unchanged. The focused social damage, faction attack, Puppet Opera transport, Puppet Opera authority, and MP guard matrix passed 5/5. The full suite remains 35 failures out of 783 with no new or resolved failures against the established baseline. The existing social-event-hooks presence smoke remains a baseline mismatch of 14 expected public functions versus 16 declared functions. Whole-tree Lua parsing, Kahlua validation, graph coverage review, and `git diff --check` passed. The next ranked seam is the Social combat adapter.

### Chunk 86 — Social combat adapter boundary

`PNC_SocialEventHooks_CombatAdapter.lua` is now a 13-line composition root. Zombie awareness emission and public horde/stamina hooks load through `PNC_SocialEventHooks_CombatAdapter_Awareness.lua`; player-kill witness attribution and engine callbacks load through `PNC_SocialEventHooks_CombatAdapter_Witnesses.lua`. The original `SocialEventHooksInternal` callback names, public awareness hooks, relationship memory updates, core-detector integration, direct adapter load path, dependency order, and server-only loading remain unchanged. The focused combat damage, player-kill witness, zombie-kill audit boundary, Puppet Opera transport, Puppet Opera authority, and MP guard matrix passed 6/6. The full suite remains 35 failures out of 783 with no new or resolved failures against the established baseline. The social-event-hooks presence smoke remains a baseline mismatch of 14 expected public functions versus 16 declared functions. Whole-tree Lua parsing, Kahlua validation, graph coverage review, and `git diff --check` passed. The next ranked seam is SocialEvents.Process.

### Chunk 87 — Social event downstream bridge boundary

`PNC_SocialEventService_Process_Bridges.lua` now owns post-transaction faction incident recording, faction telemetry, processed-event diagnostics, and knowledge evidence recording. `SocialEvents.Process` keeps validation, observer preflight, relationship mutation, and conduct transaction ownership while preserving the original output object and bridge ordering. The SocialEventService presence and MP loader checks passed 2/2; the existing social-events smoke remains a baseline mismatch of 21 expected definitions versus 24 present definitions. The full suite remains 35 failures out of 783 with no new or resolved failures against the established baseline.

### Chunk 88 — Social event transaction boundary

`PNC_SocialEventService_Process.lua` is now a 118-line orchestration provider.
Relationship and conduct preparation, mutation, commit, and transaction failure
fields load through `PNC_SocialEventService_Process_Transaction.lua`.
Downstream faction, diagnostics, and knowledge bridges remain in
`PNC_SocialEventService_Process_Bridges.lua`. The original `SocialEvents.Process`
signature, validation and observer ordering, mutation detail payloads, conduct
commit behavior, rejection reasons, bridge ordering, direct service load path,
dependency order, and server-only loading remain unchanged.
SocialEventService presence and MP loader checks passed 2/2; the existing
social-events smoke remains the same baseline mismatch. The full suite remains
35 failures out of 783 with no new or resolved failures against the established
baseline. Whole-tree Lua parsing, Kahlua validation, graph coverage review,
and `git diff --check` passed.

### Chunk 89 — Social teammate damage delivery boundary

`PNC_SocialEventHooks_DamageAdapter_TeammateDelivery.lua` now owns the
262-line teammate witness scan and ambient flavor delivery provider.
`PNC_SocialEventHooks_DamageAdapter_Recorders.lua` is now a 469-line recorder
provider that keeps the original `RecordNPCDamagedByZombie` and
`RecordNPCDamagedByNPC` callbacks behind the exported internal handoff.
The original damage payloads, authority guards, throttle state, witness filtering,
player delivery radius, event IDs, treatment context, transport calls, audit
phases, direct adapter load path, dependency order, and server-only loading
remain unchanged. Focused combat, faction attack, and MP guard matrix passed
3/3. The full suite remains 35 failures out of 783 with no new or resolved
failures against the established baseline. Whole-tree Lua parsing, Kahlua
validation, graph coverage review, and `git diff --check` passed. The next
ranked seam is Conversation `Presentation.Receive`.

### Chunk 90 — Conversation ambient receive boundary

`PNC_SocialFlavorPresentation.lua` now keeps shared identity, medical-request,
speech, safety, and delivery helpers while loading the 222-line
`PNC_SocialFlavorPresentation_Receive.lua` provider for the authoritative
`Presentation.Receive` queue boundary. The internal helper handoff preserves
NPC and player identity shaping, relationship context, medical supply state,
queue payloads, presentation state, immediate pumping, logging, and the
existing public presentation namespace and load path. Whole-tree Lua parsing,
Kahlua validation, and `git diff --check` passed. The affected conversation
smokes reproduce their established harness failures, and the full suite
remains 35 failures out of 783 with no new or resolved failures.
The next ranked seam is `Composer.ReceiveGiftResult`.

### Chunk 91 — Conversation gift-result boundary

`PNC_ConversationComposer_Gifts.lua` is now a 10-line composition root.
Gift lifecycle, authoritative relationship refresh, group-session routing,
dialogue append, preference-aware replies, failure replies, and diary
recording load through the 295-line
`PNC_ConversationComposer_Gifts_Receive.lua` provider. The original
`Composer.ReceiveGiftResult` contract, duplicate handling, lifecycle
cleanup, semantic gift context, inventory close, text loading, and
conversation progression remain unchanged. The gift matrix passed 6/7; the
remaining `pnc_conversation_smoke` failure is the established missing
`Memory` harness setup. The full suite remains 35 failures out of 783 with
no new or resolved failures. Whole-tree Lua parsing, Kahlua validation,
graph coverage review, and `git diff --check` passed. The next ranked seam
is `Model.BuildSandboxDefinition`.

### Chunk 92 — Conversation sandbox-definition boundary

`PNC_ConversationDebugModel.lua` now keeps context defaults, listing,
inspection, sandbox execution, and OpenSandbox while loading the 330-line
`PNC_ConversationDebugModel_Sandbox.lua` provider for sandbox text, node,
choice, relationship-panel, and definition construction. The public
`Model.BuildSandboxDefinition` and `Model.OpenSandbox` contracts, cloned
context behavior, graph navigation, choice execution, relationship preview,
and debug namespace remain unchanged. The debug initialization/menu checks
passed 2/3; the remaining conversation smoke retains its Memory harness
failure. The full suite remains 35 failures out of 783 with no new or
resolved failures. Whole-tree Lua parsing, Kahlua validation, graph coverage
review, and `git diff --check` passed. The next ranked seam is
Composer `BuildRootNode`.

### Chunk 93 — Conversation root-menu boundary

`PNC_ConversationComposer_Menu.lua` now keeps category diagnostics and
greeting construction while loading the 279-line
`PNC_ConversationComposer_Menu_Root.lua` provider for category choices,
debug choice, and root-menu construction. The original root and menu node
contracts, category selection, hostile ceasefire, recruitment, settlement
admission, departure, goodbye, debug, translation, and preview behavior
remain unchanged. The affected client-command and conversation smokes
reproduce their established harness failures. The full suite remains 35
failures out of 783 with no new or resolved failures. Whole-tree Lua parsing,
Kahlua validation, graph coverage review, and `git diff --check` passed.
The next ranked seam is server `Authority.HandleChoice`.

### Chunk 94 — Conversation authority choice boundary

`PNC_ConversationAuthority_Choice.lua` is now an 11-line composition root.
The 171-line `PNC_ConversationAuthority_Choice_Handle.lua` provider owns
authoritative choice validation, replay handling, context construction,
effect application, history commits, state progression, and outcome
transport. The original `Authority.HandleChoice` contract, rejection
reasons, relationship payloads, processed-request state, close behavior,
direct authority load path, dependency order, and server-only guard remain
unchanged. Authority presence and MP loader checks passed 2/3; the
remaining behavior smoke retains its established Memory harness failure.
The full suite remains 35 failures out of 783 with no new or resolved
failures. Whole-tree Lua parsing, Kahlua validation, graph coverage review,
and `git diff --check` passed. The next ranked seam is
client `Group.Fanout`.
### Chunk 95 — Conversation group fanout boundary

`PNC_ConversationGroup.lua` now keeps group state, participant selection,
addressed filtering, public group-session access, and audit helpers while
loading the 136-line `PNC_ConversationGroup_Fanout.lua` provider for
per-member delivery, shared-session routing, response queues, and fallback
handling. The original `Group:Fanout` contract, participant ordering,
primary-session behavior, gift and camp routes, addressed delivery, and audit
payloads remain unchanged. The semantic group smoke passed 1/1; the full
suite remains 35 failures out of 783 with no new or resolved failures.
Whole-tree Lua parsing, Kahlua validation, graph coverage review, and
`git diff --check` passed. The next ranked seam is
client `Lifecycle.Create`.

### Chunk 96 — Conversation lifecycle creation boundary

`PNC_ConversationLifecycle.lua` now keeps lifecycle state, begin/update/
finish transitions, ceasefire requests, heartbeat, cleanup, farewell, and
transport helpers while loading the 160-line
`PNC_ConversationLifecycle_Create.lua` provider for conversation creation,
nameplate fallback and grace handling, safety admission, initial context,
and session startup. The original `Lifecycle.Create` contract, context
shape, safety checks, nameplate behavior, pending-request state, memory
cleanup, and client/server load boundaries remain unchanged. The focused
conversation safety smoke passed 1/1 after restoring the internal
`IsNameplateConversation` handoff. The full suite remains 35 failures out
of 783 with no new or resolved failures. Whole-tree Lua parsing, Kahlua
validation, graph coverage review, and `git diff --check` passed. The next
ranked seam is client `Composer.ReceiveRecruitOutcome`.

### Chunk 97 — Conversation recruitment result boundary

`PNC_ConversationComposer_Recruitment.lua` is now a small client
composition root. The 154-line
`PNC_ConversationComposer_Recruitment_Receive.lua` provider owns
recruitment result validation, relationship refresh, rejection diary and
reply handling, menu reopening, accepted recruitment presentation, and
session close behavior. The original `Composer.ReceiveRecruitOutcome`
contract, request matching, failure routing, dialogue payloads, diary
entries, relationship deltas, and close state remain unchanged. The two
recruitment debug smokes passed; the affected conversation smokes retain
their established `Memory` harness failures. The full suite remains 35
failures out of 783 with no new or resolved failures. Whole-tree Lua parsing,
Kahlua validation, graph coverage review, and `git diff --check` passed.
The next ranked seam is server `Authority.HandleRecruit`.

### Chunk 98 — Conversation recruitment authority boundary

`PNC_ConversationAuthority_Recruit.lua` is now a guarded server composition
root. The 168-line
`PNC_ConversationAuthority_Recruit_Handle.lua` provider owns recruitment
request validation, lease and replay checks, context admission, recruitment
service execution, relationship effects, history commits, and result
transport. The original `Authority.HandleRecruit` contract, rejection
payloads, replay state, history policy, relationship updates, close state,
facade load order, and server-only guard remain unchanged. Authority
presence, MP server-file guard, server command-handler, and recruitment
debug checks passed 5/5. The full suite remains 35 failures out of 783
with no new or resolved failures. Whole-tree Lua parsing, Kahlua validation,
graph coverage review, and `git diff --check` passed. The next candidate is
client `Composer.ReceiveOutcome`, pending a fresh bounded graph and source
review.

### Chunk 99 — Conversation outcome result boundary

`PNC_ConversationComposer_Outcomes.lua` now keeps block-result handling and
shared composer setup while loading the 154-line
`PNC_ConversationComposer_Outcomes_Receive.lua` provider for authoritative
outcome validation, relationship and diary updates, effect routing, response
queueing, territory setup, gift-window transitions, and next-node state.
The original `Composer.ReceiveOutcome` contract, request matching, failure
routes, payload construction, relationship deltas, effect handling, session
close behavior, and menu or block progression remain unchanged. The Base UI
source-boundary smoke passed after including the provider, the focused
conversation checks retain their established baseline failures, and the full
suite remains 35 failures out of 783 with no new or resolved failures.
Whole-tree Lua parsing, Kahlua validation, graph coverage review, and
`git diff --check` passed. The next candidate will be selected after a
fresh architecture scan and bounded source review.

### Chunk 100 — Companion player-emote result boundary

`PNC_CompanionCommandPresentation.lua` now keeps shared command flavor,
speech, acknowledgement, and command presentation helpers while loading the
257-line `PNC_CompanionCommandPresentation_PlayerEmoteResult.lua` provider
for deduplicated player-emote results, per-NPC relationship updates, diary
entries, reply flavor, legacy delta compatibility, and relationship-debug
synchronization. The original
`Presentation.HandlePlayerEmoteInteractionResult` contract, result cache
limit, public presenter namespace, router handoff, and relationship payloads
remain unchanged. The vanilla-emote presentation and interaction smokes,
nameplate feedback, and LLM diary checks passed 4/4. The full suite remains
35 failures out of 783 with no new or resolved failures. Whole-tree Lua
parsing, Kahlua validation, graph coverage review, and
`git diff --check` passed. The next ranked seam is
client `Presentation.HandleSocialGreeting`.

### Chunk 101 — Companion social-greeting boundary

`PNC_CompanionCommandPresentation.lua` now loads the 180-line
`PNC_CompanionCommandPresentation_SocialGreeting.lua` provider for
deduplicated greeting results, corpse-reaction gossip rendering, ambient
social-flavor queueing, NPC fallback speech, and diary recording. The
original `Presentation.HandleSocialGreeting` contract, event cache limit,
corpse and companion-dog routes, social-flavor payloads, public presenter
namespace, and router handoff remain unchanged. The social-greeting,
greeting-presentation, vanilla-emote, interaction, and nameplate focused
checks passed; the corpse-awareness smoke retains its established baseline
failure. The full suite remains 35 failures out of 783 with no new or
resolved failures. Whole-tree Lua parsing, Kahlua validation, graph coverage
review, and `git diff --check` passed. The next candidate will be selected
after a fresh architecture scan and bounded source review.

### Chunk 102 — Social greeting transaction boundary

`PNC_SocialGreetingService.lua` now keeps proximity scanning, per-player
presence edges, pump cadence, abandonment ordering, and greeting budgets while
loading the 194-line
`PNC_SocialGreetingService_TryGreet.lua` provider for meeting validation,
relationship eligibility, canonical relationship mutation, animation
requests, relationship transport, and social-greeting payload delivery. The
original `Service.TryGreet` contract, event identity, daily-greeting guard,
relationship deltas, network payloads, and authority behavior remain
unchanged. The focused social greeting, presentation, MP loader, nameplate,
and abandonment checks passed 5/5. The full suite remains 35 failures out of
783 with no new or resolved failures. Whole-tree Lua parsing, Kahlua
validation, graph coverage review, and `git diff --check` passed. The next
candidate will be selected after a fresh architecture scan and bounded source
review.

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

### Chunk 103 — Presence payload boundary

`PNC_NetworkSnapshots_PresencePayload.lua` remains the dependency-ordered
composition root while loading
`PNC_NetworkSnapshots_PresencePayload_Build.lua`. The provider owns the
158-line `Network.BuildPresenceDelta` assembly path: presence throttling,
combat and diagnostics fields, equipment and stamina summaries, medical and
vehicle state, visual/path/camp/seating debug state, and travel information.
The root passes these dependencies through `Network.Internal.PresencePayload`
so the public `Network.BuildPresenceDelta` contract, payload shape, field
ordering, optional integrations, and serialization behavior remain unchanged.

The focused presence-delta, network-scale, and profiler marker matrix passed
5/5. The full suite remains at 35 failures out of 783 with no new or resolved
failure names. Whole-tree Lua parsing, the NetworkSnapshots Kahlua scan,
architecture coverage review, and `git diff --check` passed.

### Chunk 104 — Detailed snapshot boundary

`PNC_NetworkSnapshots_DetailedPayloads.lua` now retains the dependency
handoff and ordered composition role while loading
`PNC_NetworkSnapshots_DetailedPayloads_Build.lua`. The provider owns the
220-line `Network.BuildSnapshot` assembly and its needs summary helper.
Detailed identity, ownership, inventory, medical, stamina, combat, visual,
travel, equipment, character-window, and debug fields keep their existing
payload keys, copy behavior, optional-module guards, and public method
signature.

The focused detailed snapshot, presence, authority, activity, and profiler
matrix passed 7/7. The full suite remains at 35 failures out of 783 with no
new or resolved failure names. Whole-tree Lua parsing, the NetworkSnapshots
Kahlua scan, architecture coverage review, and `git diff --check` passed.

### Chunk 105 — Client inventory-delta boundary

`PNC_ClientInventoryCommands.lua` keeps client command registration,
character-payload application, result delivery, and the local inventory helper
handoffs while loading
`PNC_ClientInventoryCommands_Delta.lua`. The provider owns the 157-line
`Internal.ApplyInventoryDelta` transaction: revision and gap guards, add,
remove, move, update, replace, equip, and wear operations, resync requests,
equipment cache rebuilding, audit diagnostics, and inventory-window
invalidation. The `InventoryDelta` command route and internal state contracts
remain unchanged.

The isolated inventory recovery, state roundtrip, and network scale matrix
passed 3/3. The client-command smoke reproduces its established legacy
pursuit failure. Both changed files pass syntax and Kahlua checks; the full
suite remains at 35 failures out of 783 with no new or resolved failure names.
Whole-tree Lua parsing, architecture coverage review, and `git diff --check`
passed.

### Chunk 106 — LLM social reaction authority boundary

`PNC_ServerLLMSocialReactionCommandHandler.lua` now retains policy loading,
request reservation and release callbacks, shared authority helpers, and
ordered command registration while loading
`PNC_ServerLLMSocialReactionCommandHandler_Handle.lua`. The provider owns the
237-line `Authority.HandleLLMSocialReaction` transaction: request validation,
lease ownership, idempotency, target identity, policy evaluation, canonical
relationship mutation, result construction, relationship transport, and
optional integration degradation. The public authority method and command
routes remain unchanged. The provider has the same server-only early return
so pure multiplayer clients do not initialize server state.

The PBrainZ social reaction, policy, tool catalog, result diary, nameplate,
server router, and MP server-file guard matrix passed 7/7. The full suite
remains at 35 failures out of 783 with no new or resolved failure names.
Whole-tree Lua parsing, changed-file Kahlua validation, architecture coverage
review, and `git diff --check` passed.

### Chunk 107 — Semantic social authority boundary

`PNC_ServerSemanticSocialInteractionCommandHandler.lua` retains server-only
initialization, semantic event definitions, relationship summary helpers, and
the ordered command registration while loading
`PNC_ServerSemanticSocialInteractionCommandHandler_Handle.lua`. The provider
owns the 162-line `Authority.Handle` transaction: authority and player
validation, conversation lease validation, NPC and target identity checks,
semantic event emission, relationship delivery, and result shaping. The
`PNC.SemanticDialogueSocialAuthority` namespace and command route remain
unchanged, and the provider preserves the pure-client early return.

Server-router and MP guard checks passed 2/2. Adjacent semantic chat, group,
and world-target authority checks passed 3/3. The direct semantic social smoke
retains its established profanity-pattern baseline failure. The full suite
remains at 35 failures out of 783 with no new or resolved failure names.
Whole-tree Lua parsing, changed-file Kahlua validation, architecture coverage
review, and `git diff --check` passed.

### Chunk 108 — Relationship mutation transaction boundary

`PNC_RelationshipService_EventMutation.lua` remains the composition root for
the relationship mutation adapter while loading
`PNC_RelationshipService_EventMutation_Apply.lua`. The provider owns the
174-line `Relationships.ApplyEventMutation` atomic persistent mutation:
authority and target validation, duplicate, cooldown, and saturation guards,
memory pruning, relationship recalculation, bounded event state, commit, and
optional journal projection. `ApplyConversationEffect` remains in the root as
the conversation adapter. Public `Relationships` and `Personal.Commands`
aliases, load order, and return shapes remain unchanged.

Relationship-service presence, foundation, and faction-toll checks passed 3/3.
The social-event smoke retains its established definition-count baseline
failure (`21` expected, `24` actual). The MP server-file guard was updated for
the new guarded provider. The full suite remains at 35 failures out of 783
with no new or resolved failure names. Whole-tree Lua parsing passed for 2,409
files; changed-file Kahlua validation, architecture coverage review, and
`git diff --check` passed.

### Chunk 109 — Semantic context-question catalog boundary

`PNC_SemanticCatalog_QuestionPatterns.lua` retains catalog bootstrap and the
location/seen question registrations while loading
`PNC_SemanticCatalog_QuestionPatterns_ContextQuestions.lua`. The provider owns
the unchanged 344-line `Internal.RegisterWorldFactQuestions` registration
block for time, date, weather, identity, activity, wellbeing, and gift
preference questions. The existing internal function contract,
`registerPattern` dependency, catalog registration order, and semantic
pattern definitions remain unchanged.

Semantic fact, topic, and dialogue checks passed 3/3. The local response,
local route, and NLU wellbeing checks retain their established baseline
failures. The full suite remained at 35 failures out of 783 with no failure
name delta. Whole-tree Lua parsing passed for 2,410 files; changed-file
Kahlua validation, architecture coverage review, and `git diff --check`
passed.

### Chunk 110 — Inventory transfer authority boundary

`PNC_ServerInventory_Transfer.lua` retains inventory helper ownership,
medical bandage transfer, idempotency cache ownership, and the ordered handoff
while loading `PNC_ServerInventory_Transfer_Handle.lua`. The provider owns the
unchanged 172-line `Service.Transfer` server transaction: gift replay
handling, authority and revision validation, medical-supply admission,
direction dispatch, gift effects, medical completion, notification, and audit
projection. The public `Service.Transfer` contract and existing client/server
command route remain unchanged.

Inventory transaction, rollback, gift-idempotency, semantic give-item, server
audit, and MP loader checks passed 6/6. The inventory presence boundary smoke
now passes; its previous function-count failure is the one resolved baseline
failure. The full suite is 34 failures out of 783, with no new failure names.
Whole-tree Lua parsing passed for 2,411 files; all four changed production
files passed Kahlua validation. The final architecture audit reports 2,540
production files, 355,037 scored LOC, and 256 findings; `git diff --check`
passed.

### Chunk 111 — Movement halt contract boundary

`PNC_Behavior_Common.lua` retains shared combat, owner, and movement-intent
helpers while loading `PNC_Behavior_Common_MovementHalt.lua`. The provider owns
the unchanged 50-line `Common.HaltMovement` contract: move-intent holds,
engine-path invalidation, live path reset, and abstract fallback reset. The
`Common.HaltMovement` public entry point and all existing callers remain
unchanged; `MoveRecord` stays in the root because its broader navigation and
presentation responsibilities need a separate boundary.

Movement, combat, seating, follow, lumber, threat, camp, corpse-haul, and
ranged checks passed 10/11. `pnc_seated_threat_smoke` retains its established
`SetCombatDebug` baseline failure. The full suite remains at 34 failures out
of 783, with the inventory presence boundary as the one resolved baseline
failure and no new failures. Whole-tree Lua parsing passed for 2,412 files;
both movement files passed Kahlua validation, and `git diff --check` passed.
The final architecture audit reports 2,541 production files, 355,055 scored
LOC, and 256 findings.

### Chunk 112 — Stationary movement hold boundary

`PNC_Behavior_Common.lua` retains `MoveRecord` orchestration while loading
`PNC_Behavior_Common_StationaryMovementHold.lua`. The provider owns the
stationary presentation guard for seat and sleep ownership: presentation
resolution, seated diagnostics, presentation movement release, and the
existing movement halt handoff. The `MoveRecord` entry point, return values,
caller surface, fallback seat detection, and load order remain unchanged.

The focused movement and presentation matrix passed 12/12. The full suite
remains 34 failures out of 783 with no failure-name delta against the
movement-halt baseline. Whole-tree Lua parsing passed 2,412 files; both
changed Lua files passed Kahlua validation, `git diff --check` passed. The
architecture audit reports 2,542 production files, 355,084 scored production
LOC, and 256 findings. The new provider is not server-only and introduces no
network, persistence, or optional-integration changes.

### Chunk 113 — Movement request dispatch boundary

`PNC_Behavior_Common.lua` now retains movement preparation and loads
`PNC_Behavior_Common_MovementDispatch.lua`. The provider owns the live
`MoveIntent.RequestMove` preference, the `PathService.MoveToward` fallback,
and the `PathService.AdvanceAbstract` path for abstract records. The
`MoveRecord` signature, return values, live and abstract behavior, caller
surface, and load order remain unchanged.

The focused movement, navigation, and abstract-path matrix passed 18/18. The
full suite remains 34 failures out of 783 with no failure-name delta against
the movement-routing baseline. Whole-tree Lua parsing passed 2,412 files; all
four movement files passed Kahlua validation, `git diff --check` passed. The
architecture audit reports 2,544 production files, 355,200 scored production
LOC, and 256 findings.

### Chunk 114 — Companion FollowOwner combat and vehicle handoff boundaries

`PNC_BehaviorCompanion.lua` remains the ordered composition root. It now loads
`PNC_BehaviorCompanion_FollowOwner_CombatHandoff.lua` and
`PNC_BehaviorCompanion_FollowOwner_VehicleHandoff.lua` before the existing
`PNC_BehaviorCompanion_FollowOwner.lua` coordinator. The combat provider owns
the live follow-owner retreat, owner-priority combat, urgent threat, horde
retreat, and owner-leash threat handoff. The vehicle provider owns boarding,
passenger maintenance, disembark handling, and the full-vehicle wait path.

`BehaviorCompanion.Tick`, `Internal.TickFollowOwner`, the existing internal
handoff names, return values, load order, owner authority, and optional vehicle
integration remain unchanged. The coordinator retains owner resolution,
formation, hazard, and movement orchestration and calls the new providers in
their original order.

The focused companion matrix passed 16/16 after both handoffs. The established
`pnc_follow_horde_steering_smoke` stationary-owner failure remains unchanged.
The full suite remains 34 failures out of 783 with no failure-name delta.
Whole-tree Lua parsing passed for 2,417 files; the composition root, follow
coordinator, combat handoff, and vehicle handoff passed Kahlua validation and
`luac`, and `git diff --check` passed. The architecture audit reports 2,546
production files, 355,274 scored production LOC, 257 findings, and a Behaviors
subsystem of 36 files and 6,302 LOC. `Internal.TickFollowOwner` is now 249
lines. Live singleplayer, hosted-MP, dedicated-server, reconnect, and
save/reload runtime gates remain required.

### Chunk 115 — Companion abstract and live movement handoff boundaries

`PNC_BehaviorCompanion_AbstractFollowOwner.lua` now owns the complete
bodyless follow-owner branch: durable owner identity recovery, unresolved-owner
retry, abstract catch-up speed, bounded long-range convergence, anchor fallback,
and follower-presence diagnostics. The original `FollowOwner.lua` path keeps a
guarded compatibility require so direct consumers of that path still receive
`Internal.TickAbstractFollowOwner`.

`PNC_BehaviorCompanion_FollowOwner_MovementHandoff.lua` owns live stationary
owner holding, formation-slot sampling, personal-space correction, horde
steering, stealth move-mode selection, move-intent gating, combat-target clear,
and the final `MoveRecord` request. The existing `Internal.TickFollowOwner`
entry point and return behavior remain unchanged; its root now sequences owner
state, vehicle, hazard, combat, and movement handoffs.

Abstract, formation, navigation, and traversal checks passed 5/5 after
excluding the established `pnc_follow_horde_steering_smoke` stationary-owner
failure. The full suite remains 34 failures out of 783 with no failure-name
delta. Whole-tree Lua parsing passed for 2,419 files; changed companion files
passed Kahlua validation and `luac`, and `git diff --check` passed. The
architecture audit reports 2,548 production files, 355,329 scored production
LOC, 258 findings, and a Behaviors subsystem of 38 files and 6,357 LOC.
`Internal.TickFollowOwner` is now 144 lines. Live runtime gates remain
required.

### Chunk 116 — Companion FollowOwner owner-state handoff boundary

`PNC_BehaviorCompanion_FollowOwner_StateHandoff.lua` now owns live owner
identity persistence, owner motion and combat state refresh, and the animation
scene interruption that occurs when the owner starts moving. The provider
returns the same `followState` and `ownerEngaged` values used by the existing
`Internal.TickFollowOwner` sequence. Registry dirty marking, diagnostics,
animation interruption, load order, and owner authority remain unchanged.

The affected companion matrix passed 6/6 after excluding the established
`pnc_follow_horde_steering_smoke` stationary-owner failure. The full suite
remains 34 failures out of 783 with no failure-name delta. Whole-tree Lua
parsing passed for 2,420 files; changed companion files passed Kahlua
validation and `luac`, and `git diff --check` passed. The architecture audit
reports 2,549 production files, 355,355 scored production LOC, 257 findings,
and a Behaviors subsystem of 39 files and 6,383 LOC. The live
`Internal.TickFollowOwner` coordinator is now 133 physical lines and no longer
appears as a large-function finding.

### Chunk 117 — Companion horde-steering boundary

`PNC_BehaviorCompanion_FollowHazardSteering.lua` now owns the short-lived
`ResolveHordeAwareFollowTarget` calculation and its traversal-safe candidate
selection. `PNC_BehaviorCompanion_FollowHazards.lua` retains shared zombie
sensing, bounded per-owner candidate caching, hazard aggregation, and horde
observation. The original `Internal.ResolveHordeAwareFollowTarget` contract,
direct `FollowHazards.lua` load path, movement consumer, and profiler marker
remain unchanged.

The affected hazard, steering, formation, navigation, traversal, abstract, and
profiler checks passed 7/7 after excluding the established
`pnc_follow_horde_steering_smoke` stationary-owner failure. The full suite
remains 34 failures out of 783 with no failure-name delta. Whole-tree Lua
parsing passed for 2,421 files; changed hazard files passed Kahlua validation
and `luac`, and `git diff --check` passed. The architecture audit reports
2,550 production files, 355,380 scored production LOC, 257 findings, and a
Behaviors subsystem of 40 files and 6,408 LOC. The steering provider is 166
physical lines; abstract follow remains a cohesive deferred provider.

### Chunk 118 — Companion abstract owner-resolution and movement boundaries

`PNC_BehaviorCompanion_AbstractFollowOwner_Resolution.lua` now owns durable
owner recovery, unresolved-owner retry budgeting, presence wake-up, and the
unresolved diagnostic. `PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff.lua`
owns abstract catch-up speed, long-range bounded convergence, `MoveRecord`,
facility-held movement reporting, and abstract follow telemetry. The original
`Internal.TickAbstractFollowOwner` entry point, state modes, owner identity
fields, diagnostic event names, and direct `FollowOwner.lua` compatibility
path remain unchanged.

The affected abstract, hazard, formation, navigation, traversal, and profiler
checks passed 7/7 after excluding the established
`pnc_follow_horde_steering_smoke` stationary-owner failure. The full suite
remains 34 failures out of 783 with no failure-name delta. Whole-tree Lua
parsing passed for 2,423 files; changed abstract files passed Kahlua validation
and `luac`, and `git diff --check` passed. The architecture audit reports
2,552 production files, 355,490 scored production LOC, 257 findings, and a
Behaviors subsystem of 42 files and 6,518 LOC. The abstract coordinator is now
124 physical lines.

### Chunk 119 — Self-treatment tick boundary

`PNC_Behavior_Treatment.lua` retains treatment state helpers, wound and supply
policy, abstract cadence, bandage planning, snapshot shaping, and the original
load path. `PNC_Behavior_Treatment_Tick.lua` now owns the public
`BehaviorTreatment.Tick` orchestration for live and abstract treatment,
including threat admission, bandaging continuation, interruption, tactical
lease cleanup, and completion effects. Its injected helper table preserves the
existing local ownership and direct test loading behavior.

The self-treatment and combat-commitment checks passed 2/2. The full suite
remains 34 failures out of 783 with no failure-name delta. Whole-tree Lua
parsing passed for 2,424 files; both treatment files passed Kahlua validation
and `luac`, and `git diff --check` passed. The architecture audit reports
2,553 production files, 355,529 scored production LOC, 257 findings, and a
Behaviors subsystem of 43 files and 6,557 LOC. Live multiplayer and save/reload
runtime gates remain required.

## Current Chunk

Chunk 119 — Self-treatment tick boundary (`[x]`).

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
- [x] Chunk 70 — Puppet Opera NPC ownership adapter boundary
- [x] Chunk 71 — Lumber execution boundary
- [x] Chunk 72 — Lumber WorkAdapter boundary
- [x] Chunk 73 — World-effect service boundary
- [x] Chunk 74 — WorkService queue and claim boundary
- [x] Chunk 75 — WorkService scheduler boundary
- [x] Chunk 76 — WorkService progress and completion boundary
- [x] Chunk 77 — WorkTaskProvider execution boundary
- [x] Chunk 78 — TaskRequest command and snapshot boundary
- [x] Chunk 79 — Tasking recovery boundary
- [x] Chunk 80 — Tasking pump orchestration boundary
- [x] Chunk 81 — Task lease lifecycle boundary
- [x] Chunk 82 — WorkService operation registry boundary
- [x] Chunk 83 — WorkService target/provider boundary
- [x] Chunk 84 — WorkService worker reconciliation boundary
- [x] Chunk 85 — Social damage adapter boundary
- [x] Chunk 86 — Social combat adapter boundary
- [x] Chunk 87 — Social event downstream bridge boundary
- [x] Chunk 88 — Social event transaction boundary
- [x] Chunk 89 — Social teammate damage delivery boundary
- [x] Chunk 90 — Conversation ambient receive boundary
- [x] Chunk 91 — Conversation gift-result boundary
- [x] Chunk 92 — Conversation sandbox-definition boundary
- [x] Chunk 93 — Conversation root-menu boundary
- [x] Chunk 94 — Conversation authority choice boundary
- [x] Chunk 95 — Conversation group fanout boundary
- [x] Chunk 96 — Conversation lifecycle creation boundary
- [x] Chunk 97 — Conversation recruitment result boundary
- [x] Chunk 98 — Conversation recruitment authority boundary
- [x] Chunk 99 — Conversation outcome result boundary
- [x] Chunk 100 — Companion player-emote result boundary
- [x] Chunk 101 — Companion social-greeting boundary
- [x] Chunk 102 — Social greeting transaction boundary
- [x] Chunk 103 — Presence payload boundary
- [x] Chunk 104 — Detailed snapshot boundary
- [x] Chunk 105 — Client inventory-delta boundary
- [x] Chunk 106 — LLM social reaction authority boundary
- [x] Chunk 107 — Semantic social authority boundary
- [x] Chunk 108 — Relationship mutation transaction boundary
- [x] Chunk 109 — Semantic context-question catalog boundary
- [x] Chunk 110 — Inventory transfer authority boundary
- [x] Chunk 111 — Movement halt contract boundary
- [x] Chunk 112 — Stationary movement hold boundary
- [x] Chunk 113 — Movement request dispatch boundary
- [x] Chunk 114 — Companion FollowOwner combat and vehicle handoff boundaries
- [x] Chunk 115 — Companion abstract and live movement handoff boundaries
- [x] Chunk 116 — Companion FollowOwner owner-state handoff boundary
- [x] Chunk 117 — Companion horde-steering boundary
- [x] Chunk 118 — Companion abstract owner-resolution and movement boundaries
- [x] Chunk 119 — Self-treatment tick boundary

## Current Goal

The Monolith Decoupler pass remains active. Completed slices cover catalog
boundaries, Puppet Opera authority and NPC ownership, companion commands,
diagnostics, facility behavior and service boundaries, corpse haul, Lumber
execution and WorkAdapter boundaries, the shared world-effect service, and the
WorkService queue, claim, scheduler, progress, and completion boundaries.
The WorkTaskProvider assignment, lease, recovery, and live or abstract
execution boundaries are also split behind the original provider contract.
The TaskRequest command and unified snapshot boundaries are split behind the
original service contract.
Tasking watchdog context, retry/quarantine, stalled-lease, and executor-failure
recovery are split behind the original `Tasking.Internal` contract.
Static isolated-harness
validation remains at the established full-suite baseline. Hosted-MP,
dedicated-server, reconnect, and save/reload validation remain mandatory
runtime gates and are not represented as passed. Conversation
`Presentation.Receive`, `Composer.ReceiveGiftResult`,
`Model.BuildSandboxDefinition`, `Composer.BuildRootNode`, server
`Authority.HandleChoice`, client `Group.Fanout`, `Lifecycle.Create`,
`Composer.ReceiveRecruitOutcome`, and server `Authority.HandleRecruit`
and client `Composer.ReceiveOutcome` are split behind their helper and
composition handoffs. Companion command
`HandlePlayerEmoteInteractionResult` and `HandleSocialGreeting` are also
split behind the original presenter namespace and router contracts. The next
server `SocialGreeting.TryGreet` transaction is split behind its internal
handoff while the pump and proximity ownership remain in the service root.
The relationship mutation transaction, semantic context-question catalog,
inventory transfer authority transaction, and movement halt contract are now
split behind providers while their composition roots retain the original
contracts. Puppet Opera acknowledgement delivery and the networking
combat-debug state builder remain cohesive and were audited without artificial
splits. The next candidate will be selected after a fresh architecture scan
and bounded source review.

### Next safe seam

The networking combat-debug state provider remains deferred because its
diagnostic builder is cohesive. `Common.MoveRecord` remains the next
high-value review target, but its broad movement, navigation, animation,
seating, and diagnostics coupling requires a narrower ownership boundary
before extraction.

## Contracts Being Preserved

- Existing shared, server, and client public namespaces and function
  signatures.
- Explicit dependency-ordered `require(...)` calls in composition roots;
  no implementation module depends on alphabetical filename order.
- Shared, server, and client `00_*Init.lua` files remain thin early-loading
  anchors.
- Network command names, payload fields, validation, responses, snapshots,
  and event-registration timing.
- Server authority direction in multiplayer and singleplayer.
- ModData keys, serialized fields, migration behavior, dirty tracking, save
  timing, and retry behavior.
- Optional integrations remain nil-safe and contract-validated.
- Bounded scheduler, pathing, presence, combat, Needs, and Director work.

## SP / MP Risks

- `PNC_Server.lua` remains the server authority composition and routing
  boundary; extracted providers must preserve its command contract.
- `PNC_Client.lua` and the client command router remain the client delivery
  boundary; shared code must not silently move into one runtime layer.
- Live-body, pathing, combat, inventory, settlement, and world simulation
  changes require explicit SP and MP validation.

## Persistence Risks

- `PNC_PersistenceCoordinator` owns the save commit boundary and must retain
  domain save ordering and dirty-flag behavior.
- Registry, identity, faction, community, knowledge, storage, settlement,
  abstract-world, world-discovery, and conversation stores retain their own
  load and schema ownership.
- Future changes must avoid duplicate event registration, reordered hydration,
  lost dirty state, or serialized schema changes.

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

### Chunk 120 — BehaviorSystem tick composition boundary

`PNC_BehaviorSystem.lua` now retains the shared helper definitions and publishes
an explicit `Behavior.Internal.Tick` dependency bundle. The ordered
`PNC_BehaviorSystem_Tick.lua` provider owns the public `Behavior.Tick` loop,
preserving the existing order of treatment, committed combat, threat safety,
animation, task, companion, and recovery paths. This keeps the composition root
small while preserving the public namespace and direct compatibility load path.

The combat commitment and tasking recovery source-contract checks now inspect
the provider that owns those calls. The focused BehaviorSystem matrix passed
4/4. Whole-tree Lua parsing passed 2,425 files; both BehaviorSystem files passed
Kahlua validation and `luac`; `git diff --check` passed. The full suite remains
at the established 34 failures out of 783 with no new failure-name delta.
The architecture audit reports 2,554 production files, 355,579 scored
production LOC, and 257 findings.

### Chunk 121 — Common movement-record coordinator boundary

`PNC_Behavior_Common.lua` now retains the shared movement namespace,
`ResolveCombatApproachMode`, and dependency wiring while
`PNC_Behavior_Common_MoveRecord.lua` owns the public `Common.MoveRecord`
implementation. The provider receives the existing `Const`, `PathService`,
`ActorControl`, and diagnostics dependencies through `Common.Internal.MoveRecord`
and preserves the stationary-hold, live-routing, dispatch, and abstract-motion
branches.

The movement caller matrix passed 22/23 executed checks; the remaining failure
is the established `SetCombatDebug` baseline. Whole-tree Lua parsing passed
2,425 files; both Common files
passed Kahlua validation and `luac`; `git diff --check` passed. The full suite
remains at the established 34 failures out of 783 with no new failure-name
delta. The architecture audit reports 2,555 production files, 355,598 scored
production LOC, and 257 findings; the Behaviors subsystem is 45 files and
6,626 LOC.

### Chunk 122 — Abstract follow movement advance provider

`PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff.lua` now remains a
13-line composition boundary. The 143-line `H.Advance` implementation lives in
`PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff_Advance.lua` with
the existing Core, Const, Common, and diagnostics dependencies. The direct
`AbstractFollowOwner` path now guards the provider load so compatibility loads
retain the same movement behavior as the ordered companion root.

The abstract movement matrix passed 6/6. All four changed companion files pass
Kahlua validation; whole-tree Lua parsing passed 2,427 files; `luac` and
`git diff --check` passed. The full suite remains at the established 34
failures out of 783 with no new failure-name delta. The architecture audit
reports 2,556 production files, 355,612 scored production LOC, and 257
findings.

### Chunk 123 — ThreatGuard tick provider boundary

`PNC_BehaviorThreatGuard_Lifecycle.lua` now owns the compact lifecycle helpers,
`IsActive`, and the dependency bundle. The 122-line public `ThreatGuard.Tick`
implementation lives in `PNC_BehaviorThreatGuard_Tick.lua`; it receives the
existing Core, Common, timing, and lifecycle helper dependencies and preserves
the existing transition-provider calls and threat-state ownership.

The focused ThreatGuard matrix passed 2/4 checks; the two remaining failures
are the established `SetCombatDebug` baseline path. Whole-tree Lua parsing
passed 2,428 files; both ThreatGuard files passed Kahlua validation and `luac`,
and `git diff --check` passed. The full suite remains at the established 34
failures out of 783 with no new failure-name delta. The architecture audit
reports 2,557 production files, 355,637 scored production LOC, and 257
findings.

### Chunk 124 — World-target refresh provider boundary

`PNC_Behavior_Targeting.lua` now retains live-facing and target-resolution APIs,
the shared `sameTarget` helper, and an explicit dependency bundle. The
169-line `Targeting.UpdateTargetFromWorld` implementation lives in
`PNC_Behavior_Targeting_UpdateTargetFromWorld.lua`, preserving visibility
memory, player/NPC/zombie resolution, compatibility-target resolution, and
target-threat checks.

The target refresh matrix passed 4/4. Both targeting files passed Kahlua
validation and `luac`; whole-tree Lua parsing passed 2,429 files; and
`git diff --check` passed. The full suite remains at the established 34
failures out of 783 with no new failure-name delta. The architecture audit
reports 2,558 production files, 355,664 scored production LOC, and 257
findings.

### Chunk 125 — FollowOwner tick coordinator boundary

`PNC_BehaviorCompanion_FollowOwner.lua` now retains direct-load compatibility,
the abstract-follow and state-handoff provider guards, and explicit dependency
wiring. The 109-line `Internal.TickFollowOwner` coordinator now lives in
`PNC_BehaviorCompanion_FollowOwner_Tick.lua` and receives Core, Const, Stealth,
BehaviorCommon, and CompanionVehicle through `Internal.FollowOwnerTick`.
Owner-missing recovery, state preparation, vehicle handoff, hazard assessment,
combat handoff, movement handoff, ordering, and the original
`Internal.TickFollowOwner` contract are unchanged.

The focused FollowOwner matrix passed 7/8 executed checks; the remaining
`pnc_follow_horde_steering_smoke` stationary-owner assertion reproduces the
established baseline failure. Whole-tree Lua parsing passed 2,429 files; both
changed Lua files passed `pz_verify` and `luac`; `git diff --check` passed. The
full suite remains 34 failures out of 783 with no failure-name delta. The
architecture audit reports 2,559 production files, 355,684 scored production
LOC, and 257 findings; the Behaviors subsystem is 49 files and 6,712 LOC with
an 83.8 health score.

### Chunk 126 — Roaming area-mode provider boundary

`PNC_Behavior_Roaming.lua` now retains shared roaming helpers, mode registration,
normalizer and job wiring, and the public `Roaming.Tick` contract. The complete
area roaming state machine now lives in
`PNC_Behavior_Roaming_AreaMode.lua` as `Roaming.Internal.AreaMode.Run`, with
explicit Core, Const, Common, BehaviorCombat, goal, pause, passage, and threat
dependencies. Area pause and threat handling, ambient and floor-seat callbacks,
goal selection, blocked-path recovery, movement requests, player-mode fallback,
and mode registration order are preserved.

The focused roaming matrix passed 7/7 checks. Whole-tree Lua parsing passed
2,431 files; both changed files passed `luac`, and Kahlua compatibility checks
reported zero issues. `pz_verify` still reports the remaining 4,922-token bloat
warning on the 559-line roaming composition root. `git diff --check` passed. The
full suite remains 34 failures out of 783 with no new roaming failure. The
architecture audit reports 2,560 production files, 355,716 scored production
LOC, and 257 findings; Behaviors is 50 files and 6,744 LOC with an 83.8 health
score.

### Chunk 127 — Behavior tick sleep dependency repair

`PNC_BehaviorSystem_Tick.lua` now receives the root-owned
`tickPendingSleepWake` helper through `Behavior.Internal.Tick`, removing an
unresolved global lookup introduced by the earlier provider extraction. The
sleep teardown ordering and public `Behavior.Tick` contract remain unchanged.
The focused sleep and recovery matrix passed 5/5 checks. Whole-tree Lua parsing
passed 2,431 files; changed files passed `luac` and Kahlua compatibility checks
reported zero issues. `git diff --check` passed. The full suite remains 34
failures out of 783.

### Chunk 128 — Behavior tick dispatch provider boundary

`PNC_BehaviorSystem_Tick.lua` now keeps authority, safety-gate ordering,
presentation leases, treatment, and semantic action-plan ownership in the main
coordinator. Job selection, reselection diagnostics, registry dispatch,
companion and hostile fallback, follower reconciliation, and idle presentation
now live in `PNC_BehaviorSystem_Tick_Dispatch.lua` as
`Behavior.Internal.TickDispatch.Run`. The original `Behavior.Tick` entry point,
return behavior, ordering, and dependency wiring remain intact.

The focused behavior matrix passed 10/10 checks. Whole-tree Lua parsing passed
2,432 files; changed files passed `luac`, and Kahlua compatibility checks
reported zero issues. `git diff --check` passed. The full suite remains 34
failures out of 783. The graph coverage check at generation
`2026-09-30T23:25:13Z` reported `metadata_changed` for edited roots and
`not_tracked` for the new dispatch provider; no uncovered ranges were reported
and the changed source was read directly. The architecture audit reports 2,561
production files,
355,750 scored production LOC, and 257 findings; Behaviors is 51 files and
6,778 LOC with an 83.8 health score. `Behavior.Tick` is now 196 lines.

### Chunk 129 — Roaming player-mode provider boundary

`PNC_Behavior_Roaming.lua` now retains shared roaming helpers, area/road/shelter
mode ownership, registry wiring, and the public `Roaming.Tick` contract. Player
target refresh, visibility checks, mobile-group transition handling, no-player
holding, and movement now live in `PNC_Behavior_Roaming_PlayerMode.lua` as
`Roaming.Internal.PlayerMode.Run` with explicit Core, Const, Common, and
Perception dependencies. Player-mode registration and the area fallback remain
ordered through the original mode registry.

The focused player/mobile matrix passed 8/8 checks. Whole-tree Lua parsing
passed 2,433 files; changed files passed `luac`, and Kahlua compatibility checks
reported zero issues. `git diff --check` passed. The full suite remains 34
failures out of 783. Coverage at graph generation `2026-09-30T23:25:13Z`
reported `metadata_changed` for the edited root and `not_tracked` for the new
player provider; no uncovered ranges were reported and the changed source was
read directly. `pz_verify` reports the remaining roaming root bloat at
3,840 estimated tokens across 426 lines. The architecture audit reports 2,562
production files, 355,769 scored production LOC, and 257 findings; Behaviors is
52 files and 6,797 LOC with an 83.8 health score.

### Chunk 130 — Roaming road-mode provider boundary

`PNC_Behavior_Roaming.lua` now retains shared pacing helpers, area/player/shelter
mode ownership, registry wiring, and the public `Roaming.Tick` contract. Road
bounds tracking, bounded goal selection, blocked-path recovery, threat handling,
pause transitions, and road movement now live in
`PNC_Behavior_Roaming_RoadMode.lua` as `Roaming.Internal.RoadMode.Run`, with
explicit Core, Const, Common, BehaviorCombat, area fallback, pause, threat, and
random-goal dependencies. Road-mode registration order and area fallback are
preserved.

The focused roaming matrix passed 8/8 checks. Whole-tree Lua parsing passed
2,434 files; changed files passed `luac`, and Kahlua compatibility checks
reported zero issues. `git diff --check` passed. The full suite remains 34
failures out of 783. Coverage at graph generation `2026-09-30T23:25:13Z`
reported `metadata_changed` for the edited root and `not_tracked` for the new
road provider; no uncovered ranges were reported and the changed source was
read directly. `pz_verify` reports the remaining roaming root bloat at 3,029
estimated tokens across 336 lines. The architecture audit reports 2,564
production files, 355,911 scored production LOC, and 257 findings; Behaviors is
54 files and 6,939 LOC with an 83.8 health score.

### Chunk 131 — Roaming shelter-mode provider boundary

`PNC_Behavior_Roaming.lua` now retains shared pacing and normalization helpers,
all mode registry wiring, job registration, and the public `Roaming.Tick`
contract. Shelter target tracking, threat handling, shelter arrival state,
mobile-shelter ambient callbacks, halting, and movement now live in
`PNC_Behavior_Roaming_ShelterMode.lua` as `Roaming.Internal.ShelterMode.Run`,
with explicit Core, Const, Common, BehaviorCombat, and threat-resolution
dependencies. Optional `AmbientVisitService` resolution remains dynamic.

The focused shelter/mobile matrix passed 8/8 checks. Whole-tree Lua parsing
passed 2,435 files; changed files passed `luac`, and Kahlua compatibility checks
reported zero issues. `git diff --check` passed. The full suite remains 34
failures out of 783. Coverage at graph generation `2026-09-30T23:25:13Z`
reported `metadata_changed` for the edited root and `not_tracked` for the new
shelter provider; no uncovered ranges were reported and the changed source was
read directly. `pz_verify` reports the remaining roaming root bloat at 2,500
estimated tokens across 276 lines. The architecture audit reports 2,565
production files, 355,932 scored production LOC, and 257 findings; Behaviors is
55 files and 6,960 LOC with an 83.8 health score.

### Chunk 132 — Shared roaming context provider boundary

`PNC_Behavior_Roaming_Context.lua` now owns the shared roaming context helpers:
random goal selection, area-bound synchronization, area-state change detection,
active-passage detection, pause initialization, and roaming-threat resolution.
The provider receives explicit `Core`, `Const`, `Targeting`, and `Common`
dependencies through `Roaming.Internal.Context`. Area, road, and shelter mode
providers consume the exported helper references; the root retains order
normalization, public `Roaming.Tick`, mode registration, and job wiring.

The focused all-roaming matrix passed 8/8 checks. Whole-tree Lua parsing passed
2,436 files; changed files passed `luac` and Kahlua compatibility checks with
zero issues. `git diff --check` passed. The full suite remains at 34 failures
out of 783, matching the established baseline. Graph coverage at generation
`2026-09-30T23:25:13Z` reports `metadata_changed` for the edited root and
`not_tracked` for the edited or new roaming providers; focused tests are
`metadata_match`, no uncovered ranges were reported, and the changed source
was read directly. `pz_verify` reports no bloat warning for the 155-line root
or 159-line context provider. The architecture audit reports 2,566 production
files, 355,959 scored production LOC, 257 findings; Behaviors is 56 files and
6,987 LOC with an 83.8 health score.

### Chunk 133 — Roaming order normalization provider boundary

`PNC_Behavior_Roaming_Order.lua` now owns the roaming order schema adapter and
receives only `Const` through `Roaming.Internal.Order`. The composition root
retains the public `Roaming.Tick` contract, mode registration, job wiring, and
normalizer registration while both roaming order kinds use the provider’s
explicit `Order.Normalize` export.

The focused all-roaming matrix passed 8/8 checks. Whole-tree Lua parsing passed
2,437 files; changed files passed `luac` and Kahlua compatibility checks with
zero issues. `git diff --check` passed. The full suite remains at 34 failures
out of 783, matching the established baseline. Graph coverage at generation
`2026-09-30T23:25:13Z` reports `metadata_changed` for the edited root and
`not_tracked` for edited or new roaming providers; focused tests are
`metadata_match`, no uncovered ranges were reported, and changed source was
read directly. `pz_verify` reports no bloat warning for the 112-line root,
58-line order provider, or 159-line context provider. The architecture audit
reports 2,567 production files, 355,972 scored production LOC, 257 findings;
Behaviors is 57 files and 7,000 LOC with an 83.8 health score.

### Chunk 134 — World-target resolver provider boundary

`PNC_Behavior_Targeting_WorldTargetResolver.lua` now owns native NPC, player,
zombie, and optional foreign-NPC target resolution. It keeps the shared
visibility probe, visual-memory retention, target distance/visibility marking,
threat classification, and foreign-body compatibility handling together.
`Targeting.UpdateTargetFromWorld(record, target)` remains the public entry
point and now only computes the visual-memory window before dispatching to the
private resolver provider. The composition root supplies explicit `Core`,
`Const`, `Registry`, `Perception`, and `CompatibilityAPI` dependencies
and loads the resolver before the public wrapper.

The targeting caller matrix passed 7/10 checks. The three failures are the
existing ThreatGuard harness failures caused by missing `SetCombatDebug`;
target reassessment, profiler markers, compatibility, Project Alife, roaming,
and player tests passed. Whole-tree Lua parsing passed 2,438 files; changed
files passed `luac` and Kahlua compatibility checks with zero issues.
`git diff --check` passed. The full suite remains at 34 failures out of 783,
matching the established baseline. Graph coverage at generation
`2026-09-30T23:25:13Z` reports `metadata_changed` for the edited targeting
root and wrapper and `not_tracked` for the new resolver; no uncovered ranges
were reported and changed source was read directly. The architecture audit
reports 2,568 production files, 356,015 scored production LOC, 256 findings;
Behaviors is 58 files and 7,043 LOC with an 85.6 health score.

### Chunk 135 — ThreatGuard active-state tick provider boundary

`PNC_BehaviorThreatGuard_TickActive.lua` now owns continuation of an active
threat lease: retarget refresh, alert and avoidance transitions, attack
eligibility, engagement handoff, reacquisition grace, and threat release.
`ThreatGuard.Tick` retains input normalization, initial scanning, state
creation, and the public tick contract. The lifecycle provider supplies the
active tick’s explicit transition, targeting, combat, and timing dependencies
and loads the active provider before the main tick provider.

The focused ThreatGuard matrix passed 3/6 checks. The three failures are the
existing harness failures caused by missing `SetCombatDebug`; no new failure
appeared. Whole-tree Lua parsing passed 2,439 files; changed files passed
`luac` and Kahlua compatibility checks with zero issues. `git diff --check`
passed. The full suite remains at 34 failures out of 783, matching the
established baseline. Graph coverage at generation
`2026-09-30T23:25:13Z` reports `metadata_changed` for the lifecycle and
main tick providers and `not_tracked` for the new active provider; no
uncovered ranges were reported and changed source was read directly. The
architecture audit reports 2,569 production files, 356,039 scored production
LOC, 255 findings; Behaviors is 59 files and 7,067 LOC with an 87.4 health
score.

### Chunk 136 — Behavior tick ownership-gate provider boundary

`PNC_BehaviorSystem_Tick_Ownership.lua` now owns the ordered live-behavior
lease gates between abstract-follow/recovery handling and ordinary job
dispatch: grounded recovery, committed combat, ThreatGuard, presentation
safety, Puppet Opera, roaming ambience and seating, animation scenes, medical
leases, and treatment. The public `Behavior.Tick` coordinator retains
authority, death, sleep-wake, Puppet safety boundaries, stalled-order recovery,
facility repair, incapacitation, abstract-follow routing, action-plan ownership,
and final dispatch ordering. The source-level priority markers remain in the
coordinator for the existing combat-commitment contract check.

The focused ownership matrix passed 16/19 checks. The three failures are the
existing ThreatGuard harness failures caused by missing `SetCombatDebug`;
`pnc_combat_commitment_smoke` passed after preserving its source-order
assertions. Whole-tree Lua parsing passed 2,440 files; changed files passed
`luac` and Kahlua compatibility checks with zero issues. `git diff --check`
passed. The full suite remains at 34 failures out of 783, matching the
established baseline. Graph coverage at generation
`2026-09-30T23:25:13Z` reports `metadata_changed` for the behavior-system
root and tick provider and `not_tracked` for the new ownership provider; no
uncovered ranges were reported and changed source was read directly. The
architecture audit reports 2,570 production files, 356,068 scored production
LOC, 255 findings; Behaviors is 60 files and 7,096 LOC with an 87.4 health
score.

### Chunk 137 — FollowOwner movement-plan provider boundary

`PNC_BehaviorCompanion_FollowOwner_MovementPlan.lua` now owns the live
FollowOwner movement plan: formation-slot resolution, personal-space
enforcement, horde-aware target selection, formation holding, movement-mode
selection, follow-move command issuance, combat-target clearing, and the
shared movement record update. `FollowOwner_MovementHandoff.TryHandle` keeps
the stationary-owner hold branch and delegates the remaining plan to the
provider. The companion composition root loads the provider before the
handoff and passes explicit Core, Const, Stealth, and Common dependencies.

The focused companion matrix passed 9/9 checks after excluding the known
pre-existing `pnc_follow_horde_steering_smoke.lua` stationary-owner failure.
The full focused command still reports only that same baseline failure.
Whole-tree Lua parsing passed 2,441 files; changed files passed `luac` and
Kahlua compatibility checks with zero issues. `git diff --check` passed. The
full suite remains at 34 failures out of 783, matching the established
baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the companion root and movement handoff and
`not_tracked` for the new movement-plan provider; no uncovered ranges were
reported and changed source was read directly. The architecture audit now
reports 2,571 production files, 356,095 scored production LOC, and 254
findings; Behaviors is 61 files and 7,123 LOC with an 89.2 health score.

### Chunk 138 — FollowHazard steering target-resolver provider boundary

`PNC_BehaviorCompanion_FollowHazardSteering_TargetResolver.lua` now owns
short-lived horde avoidance target generation: direction blending, tangent
fallback, traversal checks, candidate placement, expiry, and avoidance target
state. `FollowHazardSteering.lua` retains
`Internal.ResolveHordeAwareFollowTarget` as the compatibility entry point and
delegates to the provider. The companion composition root loads the resolver
before the wrapper with explicit Core, Const, TraversalQuery, and direction
normalization dependencies. The direct-load fallback in `FollowHazards.lua`
uses the same wiring.

The focused companion matrix passed 9/9 checks after excluding the known
pre-existing `pnc_follow_horde_steering_smoke.lua` stationary-owner failure.
The full focused command still reports only that same baseline failure.
Whole-tree Lua parsing passed 2,442 files; changed files passed `luac` and
Kahlua compatibility checks with zero issues. `git diff --check` passed. The
full suite remains at 34 failures out of 783, matching the established
baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the companion root, steering wrapper, and hazard
scanner and `not_tracked` for the new resolver; no uncovered ranges were
reported and changed source was read directly. The architecture audit now
reports 2,572 production files, 356,129 scored production LOC, and 254
findings; Behaviors is 62 files and 7,157 LOC with an 89.2 health score.

### Chunk 139 — FollowOwner combat-retreat provider boundary

`PNC_BehaviorCompanion_FollowOwner_CombatRetreat.lua` now owns the locked
combat-retreat phase of live FollowOwner ticks: retreat-state acquisition,
retreat continuation, retreat completion handoff, and combat movement mode.
`FollowOwner_CombatHandoff.TryHandle` retains horde-priority calculation,
immediate self-defense, horde attack-retreat checks, and owner-leash threat
scanning. The companion root loads the retreat provider before the handoff and
passes explicit Const, CombatTactics, BehaviorCombat, and SetFollowMode
dependencies.

The focused companion matrix passed 9/9 checks after excluding the known
pre-existing `pnc_follow_horde_steering_smoke.lua` stationary-owner failure.
The full focused command still reports only that same baseline failure.
Whole-tree Lua parsing passed 2,443 files; changed files passed `luac` and
Kahlua compatibility checks with zero issues. `git diff --check` passed. The
full suite remains at 34 failures out of 783, matching the established
baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the companion root and combat handoff,
`not_tracked` for the new retreat provider, and no uncovered ranges. Changed
source was read directly. The architecture audit now reports 2,573 production
files, 356,170 scored production LOC, and 254 findings; Behaviors is 63 files
and 7,198 LOC with an 89.2 health score.

### Chunk 140 — Abstract-follow movement audit provider boundary

`PNC_BehaviorCompanion_AbstractFollowOwner_MovementAudit.lua` now owns the
presence-audit payloads emitted by abstract FollowOwner movement: held-motion
diagnostics and per-tick displacement telemetry. `H.Advance` retains target
distance, catch-up speed, long-range convergence, movement requests, arrival,
and displacement decisions. The companion root loads the audit provider
before the advance provider and passes explicit Core and Diagnostics
dependencies; the direct-load abstract-follow path wires the same provider.

The focused abstract-follow matrix passed 5/5 checks. Whole-tree Lua parsing
passed 2,444 files; changed files passed `luac` and Kahlua compatibility
checks with zero issues. `git diff --check` passed. The full suite remains at
34 failures out of 783, matching the established baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the companion root, abstract-follow root, and advance
provider and `not_tracked` for the new audit provider; no uncovered ranges
were reported and changed source was read directly. The architecture audit
now reports 2,574 production files, 356,235 scored production LOC, and 254
findings; Behaviors is 64 files and 7,263 LOC with an 89.2 health score.

### Chunk 141 — Behavior tick preflight provider boundary

`PNC_BehaviorSystem_Tick_Preflight.lua` now owns early behavior-tick gates:
dead-state cleanup, sleep-wake ownership, Puppet safety ownership, stalled
order recovery, stale facility repair, incapacitation, and abstract-follow
routing. `Behavior.Tick` retains authority and decision metrics, the source
visible preflight order marker, ordered tactical ownership, semantic action
plan ownership, and ordinary dispatch. The composition root loads Preflight
with explicit Animation, Common, OrderSystem, Incapacitated, Companion, and
AnimationScenes dependencies plus its lifecycle helpers.

The focused behavior matrix passed 8/8 checks, including combat commitment,
abstract follow, dead-state gating, grounded recovery, incapacitation,
tasking recovery, client authority, and abstract catch-up. Whole-tree Lua
parsing passed 2,445 files; changed files passed `luac` and Kahlua
compatibility checks with zero issues. `git diff --check` passed. The full
suite remains at 34 failures out of 783, matching the established baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the behavior-system root and tick provider and
`not_tracked` for the new preflight provider and existing ownership/dispatch
providers; no uncovered ranges were reported and changed source was read
directly. The architecture audit now reports 2,575 production files, 356,236
scored production LOC, and 253 findings; Behaviors is 65 files and 7,264 LOC
with a 91.0 health score.

### Chunk 142 — Area roaming movement-plan provider boundary

`PNC_Behavior_Roaming_AreaMovement.lua` now owns area-mode goal progression
and movement: deferred passage handling, dwell transitions, ambient and seat
handoffs, area goal selection, arrival pause handling, and the final roaming
move. `AreaMode.H.Run` retains runtime/state setup, blocked-path recovery,
threat resolution, and stale-target cleanup, then delegates the movement plan.
The roaming composition root loads the movement provider before AreaMode with
explicit Core, Const, Common, and Context helper dependencies.

The focused roaming matrix passed 4/4 checks: area dwell, player roam,
roaming floor seating, and ambient roam. Whole-tree Lua parsing passed 2,446
files; changed files passed `luac` and Kahlua compatibility checks with zero
issues. `git diff --check` passed. The full suite remains at 34 failures out
of 783, matching the established baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the roaming composition root and `not_tracked` for the
AreaMode, movement provider, and Context paths; no uncovered ranges were
reported and changed source was read directly. The architecture audit now
reports 2,576 production files, 356,269 scored production LOC, and 252
findings; Behaviors is 66 files and 7,297 LOC with a 92.8 health score.

### Chunk 143 — Abstract-follow catch-up speed provider boundary

`PNC_BehaviorCompanion_AbstractFollowOwner_MovementSpeed.lua` now owns
abstract-follow speed policy: normal movement speed, distance-based catch-up,
long-range convergence, elapsed-time scaling, and the bounded speed cap.
`H.Advance` retains target distance, arrival checks, movement requests,
displacement, and audit delegation. The companion root and direct-load path
load the speed provider before the advance provider with an explicit Const
dependency.

The focused abstract-follow matrix passed 5/5 checks. Whole-tree Lua parsing
passed 2,447 files; changed files passed `luac` and Kahlua compatibility
checks with zero issues. `git diff --check` passed. The full suite remains at
34 failures out of 783, matching the established baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the companion root, abstract-follow root, and advance
provider and `not_tracked` for the new speed provider and existing audit
provider; no uncovered ranges were reported and changed source was read
directly. The architecture audit now reports 2,577 production files, 356,306
scored production LOC, and 251 findings; Behaviors is 67 files and 7,334 LOC
with a 94.6 health score.

### Chunk 144 — FollowOwner horde-combat policy provider boundary

`PNC_BehaviorCompanion_FollowOwner_CombatHorde.lua` now owns horde-count
policy and attack-retreat response for live FollowOwner ticks: cached combat
horde counting, count refresh, retreat trigger evaluation, immediate response,
and target engagement. `FollowOwner_CombatHandoff.TryHandle` retains locked
retreat delegation, owner-priority calculation, urgent self-defense, and
owner-leash threat scanning. The companion root loads the horde provider
before the handoff with explicit Const, CombatTactics, BehaviorCombat,
Perception, and response dependencies.

The focused companion matrix passed 9/9 checks after excluding the known
pre-existing `pnc_follow_horde_steering_smoke.lua` stationary-owner failure.
The full focused command still reports only that same baseline failure.
Whole-tree Lua parsing passed 2,448 files; changed files passed `luac` and
Kahlua compatibility checks with zero issues. `git diff --check` passed. The
full suite remains at 34 failures out of 783, matching the established
baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the companion root and combat handoff and
`not_tracked` for the new horde provider; no uncovered ranges were reported
and changed source was read directly. The architecture audit now reports
2,578 production files, 356,348 scored production LOC, and 250 findings;
Behaviors is 68 files and 7,376 LOC with a 96.4 health score.

### Chunk 145 — FollowHazard candidate-planner provider boundary

`PNC_BehaviorCompanion_FollowHazardSteering_CandidatePlanner.lua` now owns
horde avoidance candidate-vector policy: repel and owner direction blending,
tangent fallback, traversal validation, distance clamping, and alternate-side
selection. `FollowHazardSteering_TargetResolver.Resolve` retains runtime target
cache validation, expiry, and target-state writes, then delegates candidate
planning. The composition root and direct-load fallback load the planner
before the target resolver with explicit Const, TraversalQuery, and direction
normalization dependencies.

The focused companion matrix passed 9/9 checks after excluding the known
pre-existing `pnc_follow_horde_steering_smoke.lua` stationary-owner failure.
The full focused command still reports only that same baseline failure.
Whole-tree Lua parsing passed 2,450 files; changed files passed `luac` and
Kahlua compatibility checks with zero issues. `git diff --check` passed. The
full suite remains at 34 failures out of 783, matching the established
baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the companion root, hazard scanner, steering wrapper,
and target resolver and `not_tracked` for the target resolver and new
candidate planner; no uncovered ranges were reported and changed source was
read directly. The architecture audit now reports 2,580 production files,
356,437 scored production LOC, and 249 findings; Behaviors is 70 files and
7,465 LOC with a 98.2 health score.

### Chunk 146 — MoveRecord seating-audit provider boundary

`PNC_Behavior_Common_MoveRecord_SeatingAudit.lua` now owns the seating and
animation-scene diagnostic observation that previously lived inside
`Common.MoveRecord`. The composition root loads it before the movement-record
provider and passes the diagnostics dependency explicitly. `Common.MoveRecord`
keeps its public ten-argument signature, existing stationary-hold and owner
resolution order, routing and dispatch sequence, and return values; callers
did not need migration. The high-fan-in movement contract remains in place
while the cross-cutting audit concern has a separate owner.

Targeted movement checks passed for abstract follow, follow hazard cache and
mode, roaming floor seats, work progress, lumber behavior, and fishing. The
travel conversation check still fails at the established unrelated
`SetCombatDebug` baseline. The full suite remains `34/783`, matching the
baseline. Whole-tree Lua parsing passed 2,451 files; changed files passed
`luac` and Kahlua checks with zero compatibility findings. The common root
retains its pre-existing token-bloat warning. `git diff --check` passes after
the documentation update. Graph coverage generation
`2026-09-30T23:25:13Z` reports `metadata_changed` for the two edited existing
providers and `not_tracked` for the new provider; no uncovered ranges were
reported, and the changed source was read directly. The architecture audit
now reports 2,581 production files, 356,478 scored production LOC, 248
findings; Behaviors is 71 files, 7,506 LOC, health 100.0, with zero findings.

### Chunk 147 — combat-debug target adapter boundary

`PNC_NetworkSnapshots_CombatDebugTargetResolver.lua` now owns conversion from
engine and aggro-lease targets into the normalized combat-debug target fields.
The snapshot composition root loads it before observation collection and the
observation module has a direct-load fallback. `BuildCombatDebugObservations`
retains visibility enumeration, intent classification, ordering, and payload
shape; its target metadata contract is unchanged.

The focused network and snapshot checks passed after this migration. The
separate zombie aggro stimulus check retains its established locomotion-wrapper
baseline failure. The intermediate audit removed the observation hotspot and
reported Networking at 59.9 health with 14 findings.

### Chunk 148 — presence combat-debug cadence boundary

`PNC_NetworkSnapshots_PresencePayload_CombatDebug.lua` now owns combat-debug
refresh admission, transition detection, replicated timestamps, and debug
activity markers. `BuildPresenceDelta` keeps its public entry point and payload
schema while delegating that policy through the existing presence-payload
composition root. Direct loading of the builder also loads the cadence provider
when needed.

Nine focused network and snapshot checks pass. The full suite remains `34/783`,
matching the established baseline. Whole-tree Lua parsing passed 2,453 files;
the new and changed networking providers passed `luac` and Kahlua checks with
zero compatibility findings. Graph coverage generation
`2026-09-30T23:25:13Z` reports `metadata_changed` for edited networking files
and `not_tracked` for the two new providers; no uncovered ranges were reported,
and changed source was read directly. The architecture audit now reports 2,583
production files, 356,521 scored production LOC, and 246 findings. Networking
is 113 files, 14,412 LOC, health 60.5, with 13 findings; Behaviors remains at
100.0 health with zero findings.

### Chunk 149 — client inventory delta operation boundary

`PNC_ClientInventoryCommands_DeltaOperations.lua` now owns application of one
already-admitted inventory operation and returns bounded rejection reasons.
`ApplyInventoryDelta` retains revision admission, resync requests, copied
cache publication, equipment rebuilding, inventory auditing, and UI
notification. The public internal handler and all operation semantics remain
unchanged, including ignored malformed operations and the existing rejection
reasons.

Twelve focused inventory checks covering replication, recovery, equipment,
round trips, mutations, transactions, rollback, audit, UI, trade, and backpack
patching passed. The full suite remains `34/783`, matching the established
baseline. Whole-tree Lua parsing passed 2,454 files; the changed inventory
providers passed `luac` and Kahlua checks with zero compatibility findings.
The verified stale duplicate files under the repository-root `42.20/` tree
were removed; all canonical consumers resolve under
`Contents/mods/ProjectHoomans/42.20/`.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the edited command files and `not_tracked` for the new
operation provider; no uncovered ranges were reported, and changed source was
read directly. The architecture audit now reports 2,577 production files,
354,860 scored production LOC, and 240 findings. Networking is 112 files,
14,011 LOC, health 62.3, with 10 findings; Behaviors remains at 100.0 health
with zero findings.

### Chunk 150 — snapshot composition boundary review

Fresh graph evidence shows `Network.BuildSnapshot` has seven callers and 37
provider dependencies with low internal complexity; its source is a detailed
payload composition root that already delegates domain data to named providers.
`Parts.BuildVisualState` is a single visual-state serialization adapter with
movement, animation, scene, and native-traversal ownership. Both were read
directly after coverage checks. Splitting their one-consumer field mappings
would create additional fragments without a stable public or ownership
boundary, so they remain documented hotspots for a later contract-driven
migration.

### Chunk 151 — semantic social authority application boundary

`PNC_ServerSemanticSocialInteractionCommandHandler_ApplySocialEvent.lua` now
owns the admitted semantic social event application phase: event ID creation,
server-authoritative `SocialEvents.Emit`, relationship replication, and the
final response payload. `Authority.Handle` retains request normalization,
authority and lease validation, identity and definition admission, and the
public response contract. The composition root loads the application provider
before the handler, with a direct-load fallback for the handler module.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the edited root and handler and `not_tracked` for the
new provider; no uncovered ranges were reported and changed source was read
directly. The focused semantic/social selection retained five established
fixture or behavior failures; the social event service boundary check passed.
The full suite is `34/783`, matching the established baseline. Whole-tree Lua
parsing passed 2,455 files; changed files passed `luac` and Kahlua checks with
zero compatibility findings. The existing MP server file inventory gate was
updated from 856 to 857 for the new server module. Architecture audit now
reports 2,578 production files, 354,894 scored production LOC, and 239
findings. Networking is 113 files, 14,045 LOC, health 62.9, and 9 findings.

### Chunk 152 — optional LLM social authority effect and result boundaries

`PNC_ServerLLMSocialReactionCommandHandler_ApplyEffect.lua` now owns effect
lookup, cooldown calculation, and the authoritative relationship mutation.
`PNC_ServerLLMSocialReactionCommandHandler_BuildResult.lua` owns the
post-application relationship projection and result payload. The authority
handler retains request normalization, lease validation and idempotency,
policy admission, lease consumption, logging, and network delivery. Public
LLM command, relationship, and response contracts remain unchanged. The
composition root loads both providers before the handler, and direct handler
loading retains provider fallbacks.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the edited root and handler and `not_tracked` for both
new providers; no uncovered ranges were reported and changed source was read
directly. The focused LLM/social checks passed `4/4`; the optional closed-UI
delivery check remains blocked by its existing missing
`PsychopatzCore/UI/PsychopatzUI` fixture. The full suite is `34/783`, matching
baseline. Whole-tree Lua parsing passed 2,457 files; changed files passed
`luac` and Kahlua checks. The MP server inventory gate is now 859 files.
Architecture audit reports 2,580 production files, 354,991 scored production
LOC, and 239 findings. Networking is 115 files, 14,142 LOC, health 62.9, and
9 findings; the then-current `HandleLLMSocialReaction` large-function finding
was resolved by the effect/result slice. The remaining admission, lease, and
delivery orchestration was subsequently separated in Chunks 153 and 155.

### Chunk 153 — LLM reaction lease lifecycle and delivery boundary

`PNC_ServerLLMSocialReactionCommandHandler_LeaseLifecycle.lua` now owns
cached duplicate replay, idempotency-key initialization, and pending-request
lease consumption. `DeliverResult.lua` preserves the applied-reaction delivery
order: the LLM result is sent first, followed by the relationship snapshot.
Duplicate replay continues to send only its cached result. The authority
handler retains authorization, policy admission, and orchestration.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the edited root and handler and `not_tracked` for the
new lifecycle provider; no uncovered ranges were reported and changed source
was read directly. Focused LLM/social checks pass `4/4`. The full suite is
`34/783`, matching baseline. The MP server inventory gate is 861 files.
Whole-tree Lua parsing passed 2,459 files; changed files pass syntax and
Kahlua checks, with the handler’s remaining token warning documented as
composition overhead. Architecture audit reports 2,582 production files,
355,050 scored production LOC, and 239 findings. Networking is 117 files,
14,201 LOC, health 62.9, and 9 findings.

### Chunk 154 — combat-debug temporal projection boundary

`PNC_NetworkSnapshots_CombatDebugState_Temporal.lua` now owns expiry and
suppression projection for zombie attacker, stimulus, and alert diagnostics.
`Parts.BuildCombatDebugState` retains its public signature, timing scope, and
combat-debug payload schema while delegating only that temporal projection.
The composition root loads the provider before the serializer, and direct
serializer loading retains a fallback require.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the root and serializer and `not_tracked` for the new
provider; no uncovered ranges were reported and changed source was read
directly. Nine focused snapshot, presence, MP budget, attack, and stealth
checks pass. The full suite remains `34/783`, matching baseline. Whole-tree
Lua parsing passed 2,460 files; changed files pass syntax and Kahlua checks.
Architecture audit reports 2,583 production files, 355,078 scored production
LOC, and 239 findings. Networking is 118 files, 14,229 LOC, health 62.9, and
9 findings; the previous `BuildCombatDebugState` large-function finding is
resolved.

### Chunk 155 — LLM reaction admission boundary

`PNC_ServerLLMSocialReactionCommandHandler_Admission.lua` now owns request
normalization, basic request validation, lease authorization, duplicate replay,
player identity resolution, relationship snapshotting, receipt logging, and
policy availability checks. `HandleLLMSocialReaction` retains the explicit
effect, result, lease-recording, logging, and delivery sequence. Public LLM
request, rejection, idempotency, relationship, and network contracts remain
unchanged. The composition root loads the admission provider after the lease
lifecycle provider, and direct handler loading preserves the same dependency
order through fallbacks.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the edited root and handler and `not_tracked` for the
new admission provider and lifecycle provider; no uncovered ranges were
reported and changed source was read directly. Focused LLM/social checks pass
`4/4`, and the MP server inventory gate is now 862 files. The full suite
remains `34/783`, matching baseline. Whole-tree Lua parsing passed 2,461
files; the new provider and handler pass `luac` and Kahlua/i18n/token checks.
Architecture audit reports 2,584 production files, 355,163 scored production
LOC, and 239 findings. Networking is 119 files, 14,314 LOC, health 62.9, and
9 findings; `HandleLLMSocialReaction` is no longer a large-function finding.
The remaining ranked seams include `Network.BuildSnapshot` and other
contract-sensitive serializers, so they remain deferred until a stable provider
boundary is evidenced.

### Chunk 156 — detailed snapshot projection boundaries

`PNC_NetworkSnapshots_DetailedPayloads_State.lua` now owns the ordered
derived-state gathering phase. `PNC_NetworkSnapshots_DetailedPayloads_Identity.lua`
owns identity, trait, and ownership projection, while
`PNC_NetworkSnapshots_DetailedPayloads_PresentationProjection.lua` owns visual,
diagnostic, equipment, and character-window projection. The detailed serializer
keeps the public `Network.BuildSnapshot(record, inventorySummaryOverride)` entry
point and final field assembly. Existing evaluation order, payload keys, and
inventory-copy behavior remain unchanged.

The composition root loads State, Identity, PresentationProjection, then Build;
direct serializer loading retains matching fallback requires. Focused networking
and snapshot checks pass `9/9`. The full suite remains `34/783`, matching the
established baseline. Whole-tree Lua parsing passed 2,464 files, and changed
providers and serializer pass `luac` and Kahlua/i18n checks. Architecture audit
reports 2,587 production files, 355,259 scored production LOC, and 238 findings.
Networking is 122 files, 14,410 LOC, health 64.2, and 8 findings; the
`Network.BuildSnapshot` large-function finding is resolved. Remaining work stays
focused on contract-sensitive serializers and authority boundaries with fresh
graph evidence.

### Chunk 157 — LLM admission ownership boundaries

The LLM social reaction admission path now has three explicit providers:
`PNC_ServerLLMSocialReactionCommandHandler_AdmissionRequest.lua` owns request
normalization and registry lookup;
`PNC_ServerLLMSocialReactionCommandHandler_AdmissionLease.lua` owns lease
authorization, duplicate replay, and consumed-request rejection; and
`PNC_ServerLLMSocialReactionCommandHandler_AdmissionPolicy.lua` owns the
relationship snapshot and policy availability gate. `Admission.lua` now
coordinates those providers with player identity resolution and returns the
same normalized context to the effect and result pipeline.

The server composition root loads lifecycle, request, lease, policy, and
admission providers in that order. Public rejection reasons, idempotency
behavior, lease ownership, identity callback, policy capabilities, and LLM
result contracts remain unchanged. Focused LLM checks pass `4/4`, and the MP
server inventory gate is now 865 files. The full suite remains `34/783`,
matching baseline. Whole-tree Lua parsing passed 2,467 files; changed server
providers pass `luac` and Kahlua/i18n/token checks. Architecture audit reports
2,590 production files, 355,407 scored production LOC, and 237 findings.
Networking is 125 files, 14,558 LOC, health 66.0, and 7 findings;
`H.AdmitReaction` is no longer a large-function finding.

### Chunk 158 — visual-state context and payload boundaries

`PNC_NetworkSnapshots_VisualState_MotionContext.lua` now owns path movement,
facing, native traversal, motion hints, and attack activity calculation.
`PNC_NetworkSnapshots_VisualState_Context.lua` retains health, scene, and
attack overlay resolution, while
`PNC_NetworkSnapshots_VisualState_Payload.lua` owns the serialized visual-state
field projection. `Parts.BuildVisualState` remains the timed public coordinator
and preserves the existing payload schema and instrumentation.

The shared composition root loads MotionContext, Context, Payload, then the
timed coordinator; direct loading retains fallback requires. Focused networking
and snapshot checks pass `9/9`. The full suite remains `34/783`, matching the
established baseline. Whole-tree Lua parsing passed 2,470 files; changed visual
providers pass `luac` and Kahlua/i18n/token checks. Architecture audit reports
2,593 production files, 355,587 scored production LOC, and 236 findings.
Networking is 128 files, 14,738 LOC, health 67.8, and 6 findings; the visual
state large-function findings are resolved. Remaining Networking findings are
combat diagnostics and anonymous transport composition code.

## Chunk 159 — Combat-debug state context and payload ownership

`PNC_NetworkSnapshots_CombatDebugState_Context.lua` now owns the original
combat-debug gathering order: runtime references, identity, temporal state, and
bounded zombie observations. `PNC_NetworkSnapshots_CombatDebugState_TacticalPayload.lua`
owns target, pressure, defense, and temporal fields. `PNC_NetworkSnapshots_CombatDebugState_AttackPayload.lua`
owns aim, fire-lane, tactical-move, attack, firearm, and range fields.
`PNC_NetworkSnapshots_CombatDebugState_Payload.lua` composes those projections,
while `PNC_NetworkSnapshots_CombatDebugState.lua` remains the timed public
coordinator. The shared load order loads providers before the coordinator and
direct provider loading retains matching fallbacks. Public
`Parts.BuildCombatDebugState` and payload keys remain unchanged.

Focused networking, snapshot, nameplate, stealth, and combat checks pass
`11/11`; full-suite baseline remains `34/783`. Whole-tree Lua parsing passed
`2,474` files. The affected files pass PZ Kahlua, localization, and token
checks. Architecture audit reports `2,597` production files, `355,688` scored
production LOC, and `235` findings. Networking is `132` files, `14,839` LOC,
health `69.6`, and `5` findings; the combat-debug state large-function finding
is resolved. Graph generation remains `2026-09-30T23:25:13Z`; edited and new
files are metadata changed or not tracked, so source was read directly.

## Chunk 160 — Client knowledge bootstrap ownership

`PNC_ClientCommandRouter_KnowledgeBootstrap.lua` now owns player-bootstrap stream
validation, chunk accumulation, duplicate detection, character-scope replacement,
stale knowledge preservation, and final snapshot application. The Knowledge
router keeps its existing helper closures and command registration, passing those
dependencies into the named bootstrap handler. Bootstrap ordering, revision
guards, state errors, and completion markers remain unchanged.

The focused knowledge/bootstrap set passes `5/6`; the remaining
`pnc_client_commands_smoke` failure is the established legacy pursuit-directive
initialization baseline. The original Knowledge router remains over the local
token threshold because it also owns presentation, disclosure, memory, and
debug routes; those are separate follow-up seams.

## Chunk 161 — Semantic identity result ownership

`PNC_ClientCommandRouter_SemanticIdentityResult.lua` now separates authoritative
identity-result state application from dialogue response delivery. The original
router keeps diagnostics, pending-disclosure, active-view, and load-order wiring
and passes those helpers into the named handler. Knowledge mirroring, canonical
presentation application, relationship replication, translation fallback, and
conversation message metadata remain in their original order. Focused knowledge
and identity checks pass `5/5`.

## Chunk 162 — Companion command-result ownership

`PNC_ClientCommandRouter_CompanionCommandResult.lua` now owns camp diagnostics,
manual-activity feedback, companion-emote target resolution, command interaction
presentation, and camp rejection presentation. The interaction-results router
retains unrelated relationship, LLM, greeting, map, faction, and conversation
registrations. The companion provider owns its nameplate feedback dependency and
keeps the original early returns. Focused companion and presentation checks pass
`10/10`.

Combined validation: full suite remains `34/783`, matching baseline; whole-tree
Lua parsing passed `2,477` files. Architecture audit reports `2,600` production
files, `355,778` scored production LOC, and `232` findings. Networking is `135`
files, `14,929` LOC, health `75.0`, and `2` findings; the three anonymous client
router findings are resolved. Remaining router token-bloat warnings belong to
the still multi-route Knowledge and InteractionResults files.

## Chunk 163 — Relationship and optional LLM result ownership

`PNC_ClientCommandRouter_RelationshipResult.lua` now owns relationship
projection, optional social-flavor delivery, and bounded delta history.
`PNC_ClientCommandRouter_LLMSocialReactionResult.lua` owns LLM result
deduplication, capability caching, relationship projection, diary delivery, and
debug tracing. `PNC_ClientCommandRouter_InteractionResults.lua` retains the
remaining route registrations and loads the providers before the companion
result provider. The client router is now below the local token-bloat threshold.

The five route-focused LLM, relationship, and conversation checks pass; the
mixed six-test batch is `5/6` because the pre-existing
`pnc_social_event_hooks_presence_boundary_smoke` assertion fails. Full suite
remains `34/783`, matching baseline. Whole-tree Lua parsing passed `2,479`
files. Architecture audit remains at `2,602` production files, `355,788` scored
production LOC, and `232` findings. Networking is `137` files, `14,939` LOC,
health `75.0`, and `2` findings.

## Chunk 164 — Knowledge state and optional integration boundaries

`PNC_ClientCommandRouter_KnowledgeMemory.lua` now owns the optional PBrainZ
memory adapter and its snapshot primitive and first-meeting calls.
`PNC_ClientCommandRouter_KnowledgeState.lua` owns stale-revision checks,
identity mirror diagnostics, knowledge snapshot application, and the stable
state dependency callbacks consumed by bootstrap. `PNC_ClientCommandRouter_KnowledgePresentationState.lua`
owns identity-presentation merge and loading/error normalization.
`KnowledgeDisclosure.lua` and `KnowledgeDebug.lua` own their inbound routes,
while `Knowledge.lua` remains the ordered composition root. Existing
`Internal.ApplyNPCKnowledgeSnapshot`, `Internal.ApplyNPCPresentation`, optional
memory fallback, and command registration contracts remain unchanged.

Focused knowledge, bootstrap, PBrainZ, semantic identity, server handler, and
companion checks pass `6/6`. Full suite remains `34/783`, matching baseline.
Whole-tree Lua parsing passed `2,484` files; the stale duplicate `42.20/` tree
remains empty. Architecture audit reports `2,607` production files, `355,835`
scored production LOC, and `232` findings. Networking is `142` files, `14,986`
LOC, health `75.0`, and `2` findings. All Knowledge migration providers pass
PZ Kahlua, localization, and token checks.

## Chunk 165 — Social flavor receive boundary

`PNC_SocialFlavorPresentation_Receive_Context.lua` now owns receive input validation, normalized context construction, medical request updates, identity/player/victim resolution, downed and voice enrichment, and NPC seed/count derivation. `PNC_SocialFlavorPresentation_Receive_Payload.lua` owns exact enqueue payload construction. `PNC_SocialFlavorPresentation_Receive.lua` remains the public coordinator for enqueue, optional immediate pump, and existing delivery logging. Event IDs, flavor family/priority/text/speaker/voice/context, merge/presentation/source/TTL/hold fields, `pumpImmediately`, and return semantics remain unchanged.

Focused social flavor checks pass `8/8`; full suite remains `34/783`, matching baseline. Whole-tree Lua parsing passed `2,486` files; stale duplicate `42.20/` tree remains empty. Architecture audit reports `2,609` production files, `355,904` scored production LOC, `231` findings. Conversation is `227` files, `17,789` LOC, health `56.1`, `14` findings; Networking is `142` files, `14,986` LOC, health `75.0`, `2` findings. Affected files pass PZ Kahlua, localization, and token checks.

## Chunk 166 — Gift result lifecycle and presentation boundaries

`PNC_ConversationComposer_Gifts_Receive_Context.lua` now owns active view and session resolution, duplicate request and lifecycle handling, group primary-session selection, authoritative knowledge and relationship-delta projection, gift state clearing, and transfer-context recording. `PNC_ConversationComposer_Gifts_Receive_Presentation.lua` owns reaction and failure payloads, source and key resolution, relationship refresh, inventory close, ordered response append, diary recording, and conversation completion. `PNC_ConversationComposer_Gifts_Receive.lua` remains the public coordinator, while `PNC_ConversationComposer_Gifts.lua` loads providers before the coordinator. The existing `Composer.ReceiveGiftResult` contract, `GiftLifecycle` and `GiftContext` integrations, group delivery, semantic-auto behavior, fallback text, relationship refresh, and `block:gift` completion remain unchanged.

Focused gift checks pass `5/5`. The full suite remains `34/783`, matching the established baseline; `pnc_conversation_smoke` still fails before composer execution at the existing `PNC.Memory` memory-definition setup. Whole-tree Lua parsing passed `2,488` files; stale duplicate `42.20/` tree remains empty. Architecture audit now reports `2,611` production files, `355,972` scored production LOC, `230` findings. Conversation is `229` files, `17,857` LOC, health `56.7`, `13` findings. Affected coordinator, context, and presentation modules pass PZ Kahlua, localization, and token checks.

## Chunk 167 — Conversation root menu choice ownership

`PNC_ConversationComposer_Menu_Root.lua` now coordinates category diagnostics, greeting selection, and final root-node shape. `PNC_ConversationComposer_Menu_Root_Choices.lua` owns category, hostile ceasefire, optional dossier, goodbye, debug, and source-loading composition. `PNC_ConversationComposer_Menu_Root_Choices_Companion.lua` owns settlement admission, ambient visit, recruitment, departure, ownership resolution, and relationship preview callbacks. `PNC_ConversationComposer_Menu.lua` loads the companion provider and choice provider before the public root coordinator. `Composer.BuildRootNode`, `Composer.BuildMenuNode`, choice order, callback signatures, optional integration behavior, and public namespaces remain unchanged.

The standalone menu public API smoke passes. The full suite remains `34/783`, matching the established baseline; existing conversation-definition smoke failures still occur during the `PNC.Memory` setup before menu execution. Whole-tree Lua parsing passed `2,490` files; stale duplicate `42.20/` tree remains empty. Architecture audit now reports `2,613` production files, `355,990` scored production LOC, `229` findings. Conversation is `231` files, `17,875` LOC, health `57.2`, `12` findings. All four menu modules pass PZ Kahlua, localization, token, and syntax checks.

## Chunk 168 — Recruitment result context and presentation ownership

`PNC_ConversationComposer_Recruitment_Receive_Context.lua` now owns request correlation, pending-request clearing, authoritative relationship projection, rejected-result diagnostics, and accepted recruitment state. `PNC_ConversationComposer_Recruitment_Receive_Presentation.lua` owns recruitment diary entries, rejection notification and menu reopening, response payloads, portrait metadata, and accepted close-state delivery. `PNC_ConversationComposer_Recruitment_Receive.lua` remains the public coordinator, while `PNC_ConversationComposer_Recruitment.lua` loads providers before it. `Composer.ReceiveRecruitOutcome` keeps its existing request, response, relationship, diary, and close-state contracts.

The standalone recruitment success/rejection public API smoke passes. The full suite remains `34/783`, matching the established baseline. Whole-tree Lua parsing passed `2,492` files; stale duplicate `42.20/` tree remains empty. Architecture audit now reports `2,615` production files, `356,043` scored production LOC, `228` findings. Conversation is `233` files, `17,928` LOC, health `57.8`, `11` findings. All four recruitment modules pass PZ Kahlua, localization, token, and syntax checks.

## Chunk 169 — Group fanout member dispatch ownership

`PNC_ConversationGroup_Fanout_MemberDispatch.lua` now owns per-member request IDs, cloned semantic IR processing, member context recording, deterministic response queuing, action dispatch, and bounded success/failure audits. `PNC_ConversationGroup_Fanout.lua` remains the public fanout coordinator for availability gates, gift and fallback exclusions, primary response accounting, and active-turn counts. `PNC_ConversationGroup.lua` loads the member provider before the public fanout method. Group primary-recipient rules, named-member filtering, camp and gift exclusions, cloned IR behavior, response counts, and diagnostic event contracts remain unchanged.

Focused group and gift routing checks pass `2/2`. The full suite remains `34/783`, matching the established baseline. Whole-tree Lua parsing passed `2,493` files; stale duplicate `42.20/` tree remains empty. Architecture audit now reports `2,616` production files, `356,062` scored production LOC, `227` findings. Conversation is `234` files, `17,947` LOC, health `58.4`, `10` findings. Fanout coordinator and member-dispatch modules pass PZ Kahlua, localization, token, and syntax checks; the existing large `PNC_ConversationGroup.lua` remains a separate hotspot.

## Chunk 170 — Conversation outcome receive ownership

`PNC_ConversationComposer_Outcomes_Receive_Context.lua` now owns request correlation, pending-request clearing, block and choice resolution, relationship projection, and the client conversation delta. `PNC_ConversationComposer_Outcomes_Receive_Presentation.lua` owns rejection notification, dialogue and diary payloads, territory opener effects, response queueing, logging, gift handoff, and pending-close transitions. `PNC_ConversationComposer_Outcomes.lua` remains the composition root for block receipt and loads the outcome providers before the public `Composer.ReceiveOutcome` entry point. The public outcome signature and return reasons remain unchanged.

The existing Base UI source guard now includes the presentation provider. `pnc_base_ui_smoke` passes `1/1`; `pnc_conversation_smoke` still reaches the established `PNC.Memory` setup failure. The full suite remains `34/783`. Whole-tree Lua parsing passed `2,495` files; stale duplicate `42.20/` tree remains empty. Architecture audit now reports `2,618` production files, `356,091` scored production LOC, `226` findings. Conversation is `236` files, `17,976` LOC, health `58.9`, `9` findings. Both new outcome providers and the coordinator pass PZ Kahlua, localization, token, and syntax checks.

## Chunk 171 — Server conversation choice ownership

`PNC_ConversationAuthority_Choice_Handle_Context.lua` now owns lease and replay checks, registry and node freshness validation, authoritative context construction, choice eligibility, history lookup, and outcome selection. `PNC_ConversationAuthority_Choice_Handle_Effects.lua` owns interaction construction, effect validation and application, relationship snapshots, history commits, and processed-request payload construction. `PNC_ConversationAuthority_Choice_Handle_Response.lua` owns bounded rejection and success delivery plus terminal lease cleanup. The choice composition root loads these providers before the public `Authority.HandleChoice` coordinator; the top-level authority root no longer loads the handler through a duplicate path.

The authority presence boundary, MP server file guard, and server conversation command handler smoke checks pass `1/1`. The broader authority smoke still reaches the established `PNC.Memory` setup failure. The full suite remains `34/783`. Whole-tree Lua parsing passed `2,498` files; stale duplicate `42.20/` tree remains empty. Architecture audit now reports `2,621` production files, `356,196` scored production LOC, `225` findings. Conversation is `239` files, `18,081` LOC, health `59.5`, `8` findings. The new server choice providers and coordinator pass PZ Kahlua, localization, token, and syntax checks.

## Chunk 172 — Server conversation recruitment ownership

`PNC_ConversationAuthority_Recruit_Handle_Context.lua` now owns lease and replay checks, registry validation, authoritative context construction, hostile-audience gating, and recruitment evaluation. `PNC_ConversationAuthority_Recruit_Handle_Effects.lua` owns accepted interaction history, rejected relationship penalties, rejection history, and result details. `PNC_ConversationAuthority_Recruit_Handle_Response.lua` owns refusal payload variants, success payload construction, network delivery, and terminal lease cleanup. The recruitment composition root loads these providers before `Authority.HandleRecruit`; the top-level authority root no longer loads the handler through a duplicate path.

The authority presence boundary, MP server file guard, and server conversation command handler smoke checks remain `PASS 1/1`. The broader authority smoke still reaches the established `PNC.Memory` setup failure. The full suite remains `34/783`. Whole-tree Lua parsing passed `2,501` files; stale duplicate `42.20/` tree remains empty. Architecture audit now reports `2,624` production files, `356,302` scored production LOC, `224` findings. Conversation is `242` files, `18,187` LOC, health `60.1`, `7` findings. The new server recruitment providers and coordinator pass PZ Kahlua, localization, token, and syntax checks.

## Chunk 173 — Conversation lifecycle ownership

`PNC_ConversationLifecycle_Create_Begin.lua` now owns nameplate fallback, safety admission, lifecycle token creation, scene refresh, and initial state installation. `PNC_ConversationLifecycle_Create_Update.lua` owns bounded safety polling, nameplate grace handling, heartbeat refresh, and availability diagnostics. `PNC_ConversationLifecycle_Create_Finish.lua` owns safety feedback, farewell scheduling, scene closure, memory-topic delivery, and working-context cleanup. `PNC_ConversationLifecycle_Create.lua` remains the factory composition root and returns the same `begin`, `update`, and `finish` contract.

`pnc_conversation_safety_smoke` passes `1/1`; the safety-feedback smoke retains its established environment failure at the automatic danger warning assertion. The full suite remains `34/783`. Whole-tree Lua parsing passed `2,504` files; stale duplicate `42.20/` tree remains empty. Architecture audit now reports `2,627` production files, `356,342` scored production LOC, `223` findings. Conversation is `245` files, `18,227` LOC, health `60.7`, `6` findings. The lifecycle providers and factory pass PZ Kahlua, localization, syntax, and token checks; the larger `PNC_ConversationLifecycle.lua` helper root remains a separate bloat hotspot.

## Chunk 174 — Conversation sandbox definition ownership

`PNC_ConversationDebugModel_Sandbox_Context.lua` now owns selected-block lookup, sandbox defaults, authored/debug text helpers, node IDs, and relationship-panel updates. `PNC_ConversationDebugModel_Sandbox_Graph_Choices.lua` owns sandbox choice actions, responses, and next-node behavior. `PNC_ConversationDebugModel_Sandbox_Graph_Blocks.lua` owns block and node construction. `PNC_ConversationDebugModel_Sandbox_Graph_Categories.lua` owns category and block-browser construction. `PNC_ConversationDebugModel_Sandbox_Definition.lua` owns extensions, the fake entry, portrait/theme/background, and the final definition/lifecycle. The graph composition provider loads the three graph providers, and `PNC_ConversationDebugModel_Sandbox.lua` remains the public `Model.BuildSandboxDefinition` composition root. Sandbox defaults, authored definitions, validation, deterministic fallback behavior, and public model contracts remain unchanged.

The sandbox model is no longer a token-bloat monolith. Whole-tree Lua parsing passed `2,510` files; the stale duplicate `42.20/` tree remains empty. The full suite remains `34/783` failures, with `pnc_conversation_smoke` still stopping at the established `PNC.Memory` setup failure before the sandbox path. Architecture audit now reports `2,636` production files, `356,672` scored production LOC, `222` findings. Conversation is `254` files, `18,557` LOC, health `61.2`, `5` findings. The sandbox root, context, definition, and graph providers pass syntax and PZ checks; inherited debug fallback keys in the split graph providers retain the original static i18n warnings. Hosted-MP, dedicated-server, save/reload validation remain release gates.

## Chunk 175 — Conversation text loader bounded work

`PNC_ConversationTextLoader_Decode.lua` now owns finite-bounded whitespace scanning and strict flat-JSON decoding. `PNC_ConversationTextLoader_Source.lua` owns finite-bounded reader consumption, language marker replacement, language lookup, file loading, and cache access. `PNC_ConversationTextLoader.lua` remains the public fallback and registration coordinator. Translation input remains capped at `1 MiB`; reader input is capped at `1,048,576` lines. Oversized reader input returns a bounded error, while normal missing-file, JSON, cache, registration, and localization fallback contracts remain unchanged. Focused translation fallback and catalog checks pass `2/2`; the three loader files parse cleanly. The architecture audit no longer reports the Conversation text-loader unbounded-loop finding.

The audit now reports `2,638` production files, `356,693` scored production LOC, `221` findings. Conversation is `256` files, `18,578` LOC, health `63.2`, `4` findings. The full suite remains `34/783` failures. Hosted-MP, dedicated-server, and save/reload validation remain release gates.

## Chunk 176 — Conversation Memory and Social ownership boundary

`PNC_RelationshipService_EventMutation.lua` no longer hard-loads Conversation Memory. Its relationship mutation path keeps the compact Conversation Memory journal as an optional projection guarded by the existing runtime capability check. `PNC_ServerComposition.lua` now loads `PNC_ConversationMemory` explicitly before `PNC_RelationshipService`, preserving the authoritative server projection through composition-owned load order while allowing standalone Social tests and optional runtimes to degrade safely. Existing public relationship functions and mutation payloads remain unchanged.

The composition bootstrap and relationship presence boundary checks pass `2/2`. The social event smoke retains its established definition-count failure (`expected 21, actual 24`). The full suite is now `33/783` failures after correcting stale composition expectations. The audit reports `2,638` production files, `356,693` scored production LOC, `219` findings. Conversation is `256` files, `18,578` LOC, health `64.6`, `3` findings. The removed Conversation-to-Social cycle confirms the dependency moved to an explicit composition boundary.

## Chunk 177 — Conversation and Semantics composition boundary

`PNC_Conversation.lua` now owns only Conversation runtime dependencies. Semantic adapter loading and `RegisterConversation` wiring moved to the client runtime composition root, `PNC_ConversationRuntimeComposition.lua`. `PNC_ConversationClientComposition.lua` continues to own Conversation pump registration without importing the semantic subsystem. The public `PNC.ConversationSemantics` adapter, semantic input factory, group creation contract, and time resolver registration remain unchanged.

Composition bootstrap and semantic adapter checks pass. The full suite remains `33/783` failures; `pnc_conversation_smoke` still stops at the established Conversation Memory setup failure. Whole-tree Lua parsing passes `2,512` files. The audit reports `2,638` production files, `356,693` scored production LOC, `219` findings. Conversation is `256` files, `18,570` LOC, health `64.6`, `3` findings. The Conversation-to-ConversationSemantics cycle no longer appears in the audit.

## Chunk 178 — Conversation history and Persistence boundary

`PNC_ConversationHistory.lua` now consumes the Persistence Reset contract without importing Persistence itself. The server composition root loads `PNC_Persistence_Reset` before Conversation Memory, RelationshipService, and the server Conversation entry point. History’s repeat policy, ModData schema, reset behavior, save contract, and public namespace remain unchanged. Composition bootstrap and Persistence Reset checks pass; the authority smoke still stops at the established Conversation Memory setup failure before History execution.

The audit removed both Conversation-to-Persistence cycle findings. Production findings fell to `216`; Conversation reached `256` files, `18,566` LOC, health `76.3`, with two findings remaining. The full suite remains `33/783` failures.

## Chunk 179 — Conversation semantic gift boundary

`PNC_ConversationComposer_Gifts.lua` now owns only Conversation gift receive providers. Semantic Gift Lifecycle and Gift Context load from `PNC_ConversationRuntimeComposition.lua` before the Conversation client composition root. Gift result routing and composition bootstrap checks pass, and the semantic gift public contracts remain unchanged.

The audit removed the remaining Conversation-to-Semantics cycle findings. Production findings are now `214`; Conversation is `256` files, `18,564` LOC, health `88.2`, with one Commands and Compatibility cycle still crossing Conversation. The full suite remains `33/783` failures. Whole-tree Lua parsing passes `2,512` files and the stale duplicate `42.20/` tree remains empty.

## Chunk 180 — Client compatibility composition boundary

`PNC_SocialFlavorPresentation.lua` no longer imports Bandits or Necroa flavor definitions. The client Conversation runtime composition loads those compatibility vocabularies before the Conversation client composition, preserving registration order while removing the Conversation-to-Compatibility edge. `PNC_ProjectALife_EventPresenter.lua` no longer imports the command target resolver or Social Flavor presentation; the client composition supplies target resolution before Project A-Life event installation, and Conversation composition supplies the presentation service before events are handled. Project A-Life event routing, Social Flavor delivery, optional compatibility behavior, and public command contracts remain unchanged.

Composition, Social Flavor, social greeting, and Project A-Life checks pass `4/4`. The full suite remains `33/783` failures, with the established Conversation Memory setup and unrelated baseline failures unchanged. Lua parsing passes all `2,512` authoritative `42.20` runtime files; the stale duplicate `42.20/` tree remains empty. Architecture audit improves to `81.4/100` production health with `211` findings, and the Commands-to-Knowledge-to-Persistence-to-Conversation-to-Compatibility cycle is removed. The next refactor target is the remaining Composition and UI boundary pressure.

## Next Chunk

Review the remaining Composition and UI boundary pressure with fresh graph coverage evidence. Preserve client/server contracts, optional integrations, and authoritative routing while moving cross-domain loading into explicit composition boundaries.


## Chunk 181 — Inventory UI composition-owned initialization

Inventory transfer, tooltip options, and inventory model modules no longer import the shared runtime anchor themselves. `PNC_ClientComposition.lua` owns the anchor and loads the inventory dependency chain in its existing order. Inventory UI and rollback checks pass `4/4`; the removed UI-to-composition edge is reflected in the architecture audit.

## Chunk 182 — Scavenge and colony UI boundary

`PNC_ScavengeController.lua` now consumes the composition-owned scavenge UI capability instead of loading its window on demand. `PNC_BaseWindow.lua` consumes the composition-owned Colony Management client instead of importing networking from the UI base layer. Server and client composition order explicitly loads Colony Management before inventory and related windows. Focused Scavenge, colony UI, base UI, and composition checks pass `5/5`.

## Chunk 183 — Server inventory initialization boundary

`PNC_ServerInventory.lua` no longer imports the shared runtime anchor from inside the Server subsystem. Server composition already loads the anchor and now owns the inventory dependency order. Server inventory and composition checks pass `2/2`; the Server-to-composition cycle is removed.

## Chunk 184 — Needs and Production policy boundary

`PNC_NeedsEvaluator.lua` and `PNC_WorkService_Core.lua` no longer load Production policy or Needs fatigue modules during service initialization. The server composition loads `PNC_WorkFatigueGate` before Production. Standalone harnesses retain neutral compatibility fallbacks while the normal runtime uses the composition-owned implementations. Focused Needs, work policy, fatigue, production lifecycle, workstation, camp exclusion, provisioning, and specialization checks pass `10/10`.

## Chunk 185 — Production and Settlement definition boundary

Shared composition now loads WorkDefinitions before FacilityDefinitions. Workstation facility definitions consume the composition-owned WorkDefinitions table and use an empty station catalog for isolated legacy loads rather than importing Production from Settlement. Settlement foundation, facility definition, workstation metadata, building service, and composition checks pass `5/5`; the Production-to-Settlement cycle is removed.

## Chunk 186 — Colony presentation ownership

`PNC_ColonyPresentation.lua` moved from `UI/Shared` to `UI/Communities`, matching its community and colonist presentation dependencies. All client callers and source-contract checks use the new module path. Focused colony UI and payload checks pass `3/3`; the high-confidence core-domain dependency finding is removed.

Combined validation for Chunks 181–186: changed modules pass targeted PZ Kahlua verification and `git diff --check`. Whole-tree Lua parsing passes `2,620` files. The full suite remains `33/783`, matching the established baseline. The architecture audit reports `87.4/100` production health, `194` production findings, and no concrete cross-subsystem dependency cycles; the remaining composition self-cycle is the analyzer's expected grouping of the thin client bootstrap and client runtime entry point.

## Next Chunk Review

Review the remaining UI large-module and large-function hotspots, starting with the Base Building catalog and its layout/placement collaborators. Preserve public UI contracts, composition-owned initialization, and the established baseline failure set.


## Chunk 187 — Building catalog preview and layout ownership

`PNC_BaseBuildingCatalog_Preview.lua` now owns the native preview panel, preview texture fallback, facility preview integration, and preview status rendering. `PNC_BaseBuildingCatalog_Layout.lua` now owns compact and wide catalog layout geometry. `PNC_BaseBuildingCatalog.lua` remains the public catalog coordinator and preserves `Building.Layout`, `Building.Create`, recipe selection, queue, material, favorite, and control contracts. Focused building catalog, tab, favorites, placement, request feedback, workstation launch, area edit, and base UI checks pass `9/9`. The extracted modules and catalog pass PZ Kahlua verification.

Architecture audit remains `87.4/100` production health with `193` production findings. UI refactor pressure remains the active hotspot because the remaining work is distributed across placement and other UI modules. The full suite baseline remains `33/783`; whole-tree parsing remains clean.


## Chunk 188 — Building placement cursor ownership

`PNC_BaseBuildingPlacement_Cursor.lua` now owns native and fallback cursor classes, sprite discovery, ghost rendering, and cursor selection. The placement module supplies the boundary and engine validity callbacks and retains the public cursor fields and event behavior.

## Chunk 189 — Building placement lifecycle ownership

`PNC_BaseBuildingPlacement_Begin.lua` now owns placement startup and cursor configuration. `PNC_BaseBuildingPlacement_BeginCallbacks.lua` owns authoritative footprint revalidation, queue request construction, failure feedback, success cleanup, and native cancellation cleanup. `PNC_BaseBuildingPlacement.lua` remains the public lifecycle coordinator for `Begin`, `Cancel`, tooltip rendering, and world guides. Placement-focused checks pass, including fallback, feedback, policy, settlement-source, and catalog flows.

## Chunk 190 — Base building layout ownership

`PNC_BaseBuildingLayout_Controls.lua` owns category and footer control geometry plus vertical height budgeting. `PNC_BaseBuildingLayout_Panes.lua` owns facility cards, details, requirements, and blueprint queue pane geometry. `PNC_BaseBuildingLayout.lua` remains the public `LayoutModel.Apply` orchestrator. Building selection and placement checks pass `9/9`; all three layout modules pass PZ Kahlua verification.

The refreshed architecture audit reports `85.0` UI pressure, `191` production findings, and `87.4/100` production health. The remaining UI work is concentrated in Character Window, Nameplates, Relationships, Scavenge, Workshop, and other independent presentation modules. Full-suite baseline and whole-tree parser validation remain release gates.


## Next Chunk Review

The next safest seam is an independent UI provider with focused existing coverage, preferably Character Window health or Workshop catalog presentation. Preserve the current composition boundaries and keep the full-suite `33/783` baseline separate from new UI migrations.


## Chunk 191 — Character Window health debug ownership

`PNC_CharacterWindow_Health_Debug.lua` now owns the health context-menu provider: debug damage, infection, and bandage actions, body-part labels, and the debug text dependency used by those actions. `PNC_CharacterWindow_Health.lua` remains the health renderer and delegates `Tabs.OnHealthRightMouseUp` to the provider while preserving the existing fallback menu and world-hour behavior. The provider receives the body-part text table through a small setter so load order remains explicit without duplicating localization data.

Focused character health render, context, presence, interaction-title, and text checks pass `5/5`. Both health modules pass PZ Kahlua verification with zero errors.

## Chunk 192 — Character Window wound-row rendering ownership

The repeated wound-row presentation block is now a local `renderWoundRows` helper in `PNC_CharacterWindow_Health.lua`. `Tabs.RenderHealth` retains snapshot resolution, layout, body status, whole-body ailments, incapacitation messaging, and footer orchestration while the helper owns wound labels, bandage and bleeding details, debug healing text, infection indicators, and hit-region registration. The existing row order, colors, diagnostics, and hit targets remain unchanged.

The refreshed architecture audit no longer reports a finding for `PNC_CharacterWindow_Health`; production findings decreased from `191` to `190`, UI pressure from `85.0` to `83.2`, and overall production health remains `87.4/100`. The full suite remains `33/783`, matching the established baseline. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass.


## Next Chunk Review

Continue with an independent UI presentation seam with focused coverage, such as Workshop catalog presentation, Nameplates, Relationships, or Scavenge. Preserve the current Character Window public entry points, composition boundaries, and full-suite baseline while reducing the remaining UI pressure.


## Chunk 193 — Workshop catalog rebuild ownership

`PNC_WorkshopCatalog_Rebuild.lua` now owns Workshop subtab presentation, active queue projection, station and skill grouping, craft and salvage row construction, catalog-cell actions, and pause/cancel controls. `PNC_WorkshopCatalog.lua` remains the public catalog surface for creation, layout, visibility, and compatibility wrappers for `Workshop.Rebuild`, `Workshop.OnCatalogCell`, and `Workshop.OnControl`. The existing standalone catalog contract and controller delegation remain unchanged.

Focused Workshop catalog and Command Hub registry checks pass `2/2`. The catalog and rebuild provider pass PZ Kahlua verification and Lua syntax parsing. The refreshed architecture audit reports `189` production findings, `81.4` UI pressure, and `87.4/100` production health; no Workshop finding remains.

## Next Chunk Review

Continue with the next independent UI hotspot with focused coverage, preferably Relationships, Scavenge presentation, or Nameplates. Preserve public window and controller contracts, composition-owned initialization, and the established full-suite baseline.


## Chunk 194 — Relationship debug control ownership

`PNC_RelationshipDebugWindow_Controls.lua` now owns relationship-laboratory control definitions and construction: refresh and knowledge actions, social event triggers, pacification and context controls, baseline presets, direction swapping, section tabs, and synthetic baseline inputs. `PNC_RelationshipDebugWindow.lua` retains list, graph, lifecycle, layout, refresh, selection, rendering, and public `RelationshipDebugUI.Open`/`Toggle` behavior. `Controls.Create` receives the window class and UI dependencies, preserving callback identity and existing control order.

Focused relationship model, boundary, graph, conversation panel, preview, and foundation checks pass `6/6`. The window and controls provider pass PZ Kahlua verification and Lua syntax parsing. The refreshed architecture audit reports `187` production findings, `76.9` UI pressure, and `87.4/100` production health; the `createChildren` hotspot is resolved.

## Next Chunk Review

Review the remaining UI graph and model hotspots with focused coverage, starting with the relationship graph panel or another independent presentation module. Keep domain calculations and server relationship behavior separate from UI ownership, and preserve the established full-suite baseline.


## Chunk 195 — Relationship graph render ownership

`PNC_RelationshipGraphPanel.lua` now keeps `ISPNCRelationshipGraphPanel:render` as a small presentation coordinator. Local `drawGraphSurface` owns quadrants, success and departure overlays, grid, labels, and marker placement; local `drawGraphSummary` owns the non-graph-only axis and evaluation text. Existing hover explanations, graph-only mode, opacity handling, and public panel methods remain unchanged.

Focused graph, conversation relationship-panel edit, and relationship preview checks pass `3/3`. The graph panel passes PZ Kahlua and Lua syntax checks. The architecture audit reports `186` production findings and `75.1` UI pressure before the following catalog-layout slice.

## Chunk 196 — Building catalog layout ownership

`PNC_BaseBuildingCatalog_Layout.lua` now keeps `Layout.Apply` as a layout coordinator. Local toolbar, compact-layout, and wide-layout helpers own their respective geometry calculations while `Layout.Apply` preserves debug-button availability, list sizing, recipe-column selection, preview visibility, and the public layout signature.

Focused building footer, details, tab-selection, local-recipe, and base-UI checks pass `5/5`. The layout and catalog modules pass PZ Kahlua verification. The refreshed architecture audit reports `185` production findings, `73.3` UI pressure, and `87.4/100` production health; no `Layout.Apply` finding remains.

## Next Chunk Review

Continue with the highest-value remaining UI hotspot that has focused coverage, currently the relationship debug model or Scavenge status presentation. Preserve public panel APIs, client/server ownership, and the established full-suite baseline.


## Chunk 197 — Relationship debug row ownership

`PNC_RelationshipDebugModel.lua` now keeps `Model.BuildRows` as a coordinator and assigns row construction to bounded local section helpers for identity and faction context, graph evaluation, relationship state, personality, reverse and diagnostic data, memories, and action results. Row order, section labels, tones, conversation-delta projection, conduct and faction details, and the public `Model.BuildRows`/`Model.FilterRows` contracts remain unchanged.

Focused relationship model, graph, boundary, conversation panel, and preview checks pass `5/5`. The model passes PZ Kahlua verification and Lua syntax parsing. The refreshed architecture audit reports `184` production findings, `71.5` UI pressure, and `87.4/100` production health; the relationship model `BuildRows` finding is resolved.

## Next Chunk Review

Continue with the highest-value remaining UI hotspot with focused coverage, currently Scavenge status presentation or the remaining relationship/domain helpers. Preserve public model APIs, presentation ordering, client/server ownership, and the current full-suite failure set.


## Current validation checkpoint

The final broad run executes `783` tests with `28` failures. The current failing test-name set is a subset of the earlier `33`-failure baseline: no new failing test names appeared, and five earlier failures no longer reproduce. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass.


## Chunk 198 — Scavenge status presentation ownership

`PNC_ScavengeWindow.lua` now keeps `ISPNCScavengeWindow:rebuildStatus` as a coordinator. Local helpers own activity rows, live debug rows, and snapshot diagnostics while preserving notification state, status ordering, diagnostics text, and the public window lifecycle.

Focused Scavenge model, controller, notification, and context-provider checks pass `4/4`. The window passes PZ Kahlua verification and Lua syntax parsing. The refreshed architecture audit reports `183` production findings, `69.7` UI pressure, and `87.4/100` production health.

## Chunk 199 — Character Window interaction presentation ownership

`PNC_CharacterWindow_Interactions.lua` now keeps `Tabs.RenderInteractions` as a coordinator. Local helpers own established relationship context, current relationship context, the empty diary state, and diary entry rendering. Existing title mapping, relationship fallback resolution, text truncation, delta colors, row order, and public tab methods remain unchanged.

Focused character interaction title, text, and data checks pass `3/3`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `182` production findings, `67.9` UI pressure, and `87.4/100` production health.

## Chunk 200 — Command Hub settings construction ownership

`PNC_CommandHub_SettingsWindow.lua` now delegates slider field creation, opacity construction, supplemental controls, and widget installation to local helpers. `ISPNCCommandHubSettingsWindow:createChildren` remains the public lifecycle entry point and preserves field IDs, ranges, labels, callbacks, responsive layout inputs, and `SettingsUI` behavior.

Focused Command Hub child-controller, registry, base-territory, zone-overlay, and base-UI checks pass `5/5`. The settings module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `181` production findings, `66.1` UI pressure, and `87.4/100` production health.

## Chunk 201 — Debug context menu ownership

`PNC_ContextProvider_Debug.lua` now keeps `Provider.addOptions` as a small composition point. Local builders own base debug actions, infection controls, treatment controls, order controls, and combat controls. Authorization gating, lazy debugger loading, callback payloads, option availability, submenu ordering, and the provider registration contract remain unchanged.

Focused debug, inventory-access, and Scavenge context-provider checks pass `3/3`. The provider passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `180` production findings, `64.3` UI pressure, and `87.4/100` production health.

## Chunk 202 — Director debug detail-row ownership

`PNC_DirectorDebugModel.lua` now keeps `Model.DetailRows` as a coordinator. Local helpers own director metrics, population summary and collections, selected sectors, group summary/mobile/vitals/combat/scavenge diagnostics, locations, jobs, and encounters. Row order, formatting, mobile-model calls, authorization behavior, and the public model contract remain unchanged.

Focused Director debug model, abstract-director boundary, and Community Director checks pass `4/4`. The model passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `179` production findings, `62.5` UI pressure, and `87.4/100` production health.

## Chunk 203 — Community Inspector row ownership

`PNC_CommunityDebugModel.lua` now keeps `Model.BuildRows` as a coordinator. Local helpers own selected-faction lookup, overview and mobile diagnostics, community details, selected-NPC details, and validation rows. Authorization behavior, early return for no selected community, localization keys, row order, tones, and public item/model contracts remain unchanged.

Focused Community Inspector model, boundary, foundation, and map-layer checks pass `4/4`. The model passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `178` production findings, `60.7` UI pressure, and `87.5/100` production health.

## Current validation checkpoint (post Chunks 202–203)

The broad suite executes `783` tests with `12` failures. The current failing-name set is a subset of the established `33`-failure baseline; no new failing test names appeared. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass.

## Next Chunk Review

Continue with the remaining high-confidence UI large-function hotspots, prioritizing a seam with focused tests and a stable public model or window contract. Preserve the observed baseline failure set and rerun the full suite after the next bounded group of slices.


## Chunk 204 — Facility component row ownership

`PNC_SettlementManagement_FacilityComponentRows.lua` now keeps `Rows.Build` as a coordinator. Local helpers own role-level rows, assigned and pending child rows, and room-profile rows; the stockpile-specific path remains separate. Component ordering, construction and removal actions, storage actions, room capacity rows, localization, and public `Rows.Build` output remain unchanged.

Focused facility component, facility materials, base-building details, and colony-management boundary checks pass `4/4`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `177` production findings, `58.9` UI pressure, and `87.6/100` production health.

## Chunk 205 — Unique NPC detail row ownership

`PNC_UniqueNPCDebugModel.lua` now keeps `Model.BuildDetailRows` as a coordinator. Local helpers own identity and registration rows, live runtime rows, and authored definition rows. Row keys, localization metadata, scalar formatting, nested value formatting, ordering, and the public debug model contract remain unchanged.

Focused Unique NPC debug, Unique NPC, and NPC trait model checks pass `8/8`. The model passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `176` production findings, `57.1` UI pressure, and `87.8/100` production health.


## Current validation checkpoint (post Chunks 204–205)

The latest broad suite executes `783` tests with `6` failures. Every current failing test name is within the established `33`-failure baseline; no new failing test names appeared. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass. The current architecture audit reports `176` production findings, `57.1` UI pressure, and `87.8/100` production health.


## Chunk 206 — Nameplate combat debug text ownership

`PNC_NameplateRenderer_DebugText.lua` now keeps `Renderer.BuildCombatDebugLines` as a coordinator. Local helpers own combat summary, threat and visible-zombie rows, target rows, ranged rows, action and movement rows, and defense rows. Existing text labels, formatting, ordering, optional fields, and renderer API remain unchanged.

Focused Nameplate debug, relationship feedback, speech, and tool feedback checks pass `4/4`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`.

## Chunk 207 — Nameplate combat world rendering ownership

`PNC_NameplateRenderer_CombatDebug.lua` now keeps `drawCombatDebug` as a coordinator. Local helpers own combat ranges, target and movement markers, animation trace rows, line color selection, and text drawing. World marker ordering, target-distance calculation, renderer callbacks, and public `Renderer.RenderCombatDebug` behavior remain unchanged.

The same focused Nameplate checks pass `4/4`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `175` production findings, `53.5` UI pressure, and `88.0/100` production health.

## Chunk 208 — Nameplate zombie sound debug ownership

`PNC_NameplateRenderer_ZombieDebug.lua` now keeps `drawSoundDebug` as a coordinator. Local helpers own stimulus markers and lines, observed-world sound comparison, native zombie diagnostics, line color selection, and overlay drawing. Marker de-duplication, observed-match classification, fallback text, coordinate selection, and public `Renderer.RenderZombieDebug` behavior remain unchanged.

Focused Nameplate debug and PBrainZ context checks pass `2/2`; the separate Zombie aggro smoke retains its pre-existing locomotion-wrapper failure. The module passes PZ Kahlua verification and Lua syntax parsing. The refreshed architecture audit reports `174` production findings, `53.5` UI pressure, and `88.0/100` production health.

## Chunk 209 — Nameplate combat header follow-up

The initial combat text split left `appendCombatHeader` at 125 lines. It was further divided into combat summary, threat summary, and visible-zombie row helpers. Focused Nameplate checks pass `4/4`, Kahlua verification is clean, and the refreshed architecture audit reports `173` production findings, `51.7` UI pressure, and `88.1/100` production health.


## Current validation checkpoint (post Nameplate slices)

The broad suite executes `783` tests with `2` observed failures. Both current failing test names are within the established `33`-failure baseline; no new failing test names appeared. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass.


## Chunk 210 — Nameplate live rendering ownership

`PNC_NameplateRenderer_Core.lua` now keeps `drawLive` as a coordinator. Local helpers own firearm anchor updates, status and speech overlays, identity and health presentation, and debug overlays. Scope visibility, vertical placement, zoom propagation, incapacitation coloring, relationship feedback, and `Internal.DrawLive` behavior remain unchanged.

Focused Nameplate debug, relationship feedback, speech, and tool feedback checks pass `4/4`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `172` production findings, `49.9` maximum pressure, and `88.2/100` production health.

## Chunk 211 — Nameplate debug text ownership

`PNC_NameplateRenderer_Core.lua` now keeps `drawDebugText` as a coordinator. Local helpers own reusable debug line drawing, relationship lines, core and infection lines, and animation or scene lines. Text order, per-line colors, widths, spacing, animation flags, scene flags, and private renderer behavior remain unchanged.

Focused Nameplate checks pass `4/4`; Kahlua verification, syntax parsing, and `git diff --check` pass. The refreshed architecture audit reports `171` production findings, `48.1` UI pressure, and `88.4/100` production health.

## Chunk 212 — Nameplate path debug ownership

`PNC_NameplateRenderer_PathDebug.lua` now keeps `drawPathGoal` as a coordinator. Local helpers own world path and final-goal geometry and label rendering. Goal validation, blocked colors, final-goal distance, marker geometry, text centering, and `Internal.DrawPathGoal` behavior remain unchanged.

Focused Nameplate checks pass `4/4`; the module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `170` production findings, `46.3` UI pressure, and `88.7/100` production health.

## Chunk 213 — Travel map layer ownership

`PNC_MapLayer_Travel.lua` now keeps `TravelLayer.Render` as a coordinator. Local helpers own projected-entry marker rendering and hover-card rendering. Marker filtering, selection routes, hover portrait delegation, labels, ETA text, control exclusion, and layer registration remain unchanged.

Focused map travel, map-layer, and world-discovery visibility checks pass `6/6`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `169` production findings, `44.5` UI pressure, and `89.1/100` production health.


## Current validation checkpoint (post Chunks 210–213)

The broad suite passes `783/783`. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass. The current architecture audit reports `169` production findings, `44.5` UI pressure, and `89.1/100` production health. The earlier `33`-failure baseline has no current failing names.


## Chunk 214 — Inventory refresh and presentation ownership

`InventoryWindow/_Refresh.lua` now keeps `ISPNCInventoryWindow:refreshInventory` as a small coordinator. Local helpers own cache-aware player context preparation, inventory and container list synchronization, courier status presentation, and endpoint identity presentation. The public refresh method, trade-mode delegation, refresh signature gating, selected-container behavior, button state, status text, title updates, and invalidation event registration remain unchanged.

`InventoryWindow/_Presentation.lua` now keeps `ISPNCInventoryWindow:prerender` as a small lifecycle coordinator. Local helpers own pane drawing, list headers, status feedback, and drag feedback. Timeout handling, opacity and tooltip updates, base window rendering order, layout values, labels, and mouse behavior remain unchanged.

Focused inventory UI, inventory open performance, tooltip capability, and context inventory access checks pass `4/4`. Both modules pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `167` production findings, `40.9` UI pressure, and `89.7/100` production health.

## Current validation checkpoint (post Chunk 214)

The broad suite passes `783/783`. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass. The earlier `33`-failure baseline has no current failing names in this run.

## Next Chunk Review

Continue with the highest-value remaining production seam with focused coverage. The refreshed UI findings now start with `Endpoint.LocalDraft`, `cacheMetrics`, animation debug detail refresh, facility responsive layout, and the Unique NPC editor modules. Preserve endpoint contracts, UI lifecycle order, and the current full-suite result.


## Chunk 215 — Local draft endpoint and nameplate metric ownership

`PNC_InventoryTransferEndpoint/_LocalDraft.lua` now keeps `Endpoint.LocalDraft` as a compact endpoint factory. Module-local helpers own lazy editor-model resolution, runtime-record access, item capture and transfer filtering, and action execution. Endpoint method names, payload and container projections, transfer directions, skipped-item reasons, editor synchronization, dirty-state updates, and public return values remain unchanged.

`PNC_NameplateEntries.lua` now keeps `cacheMetrics` as a coordinator. Local helpers own debug text preparation, action and speech feedback preparation, faction and community diagnostics, and primary or secondary text-metric caching. Entry visibility fields, metric keys, fonts, optional-data handling, and cache order remain unchanged.

Focused Unique NPC editor transfer, inventory, context inventory, Nameplate debug, relationship feedback, speech, and tool feedback checks pass `8/8` across the affected groups. Both modules pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `165` production findings, `37.3` UI pressure, and `90.4/100` production health.

## Current validation checkpoint (post Chunks 214–215)

The broad suite passes `783/783`. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass. The earlier `33`-failure baseline has no current failing names in this run.

## Next Chunk Review

Continue with the highest-value remaining production seam with focused coverage. The remaining UI findings are concentrated in animation debug refresh, facility responsive layout, and the Unique NPC editor modules. Preserve debug visibility, endpoint contracts, UI lifecycle order, and the current full-suite result.


## Chunk 216 — Animation scene debug detail ownership

`PNC_AnimationSceneDebugWindow.lua` now keeps `ISPNCAnimationSceneDebugWindow:refreshDetails` as a small refresh coordinator. Local helpers own registered-scene details, authority and pool-cycle runtime details, and client body animation details. Detail throttling, selected-scene fallback, row labels and ordering, runtime formatting, client-state fields, and the public debug window lifecycle remain unchanged.

Focused animation scene debug, route, scene, and snapshot-gate checks pass `4/4`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `164` production findings, `35.5` UI pressure, and `90.7/100` production health.

## Current validation checkpoint (post Chunk 216)

The broad suite passes `783/783`. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass. The earlier `33`-failure baseline has no current failing names in this run.

## Next Chunk Review

Continue with the remaining high-confidence UI function, `ISPNCFacilityBuildWindow:onResponsiveLayout`, or a bounded Unique NPC editor seam if its focused coverage supports the same behavior-preserving split. Preserve responsive layout geometry, editor lifecycle order, and the current full-suite result.


## Chunk 217 — Facility build responsive layout ownership

`PNC_SettlementManagement_FacilityBuildPresentation.lua` now keeps `ISPNCFacilityBuildWindow:onResponsiveLayout` as a geometry coordinator. Local helpers own category button layout, category-card pagination and visibility, description and footer sizing, card placement, and action or paging control layout. Responsive calculations, selected-category and page state, description/error wrapping, debug gating, button enablement, and layout order remain unchanged.

Focused colonist activity, facility build materials, base-building details, footer layout, and anchor-only facility selector checks pass `5/5`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `163` production findings, `33.7` UI pressure, and `91.1/100` production health.

## Current validation checkpoint (post Chunk 217)

The broad suite passes `783/783`. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass. The earlier `33`-failure baseline has no current failing names in this run.

## Next Chunk Review

Continue with a bounded Unique NPC editor seam. The remaining UI findings are the large appearance window, editor model, editor window, and the editor window child creation and responsive layout functions. Preserve editor draft state, control IDs, action routing, and layout behavior.


## Chunk 218 — Unique NPC editor window ownership

`PNC_UniqueNPCEditorWindow.lua` now keeps `ISPNCUniqueNPCEditorWindow:createChildren` as a lifecycle coordinator. Local helpers own editor state initialization, toolbar construction, tab and appearance view construction, form control construction, portrait setup, and initial option refresh. Control IDs, draft and preview ownership, tab wiring, editor action callbacks, refresh order, and responsive-layout requests remain unchanged.

The same module now keeps `ISPNCUniqueNPCEditorWindow:onResponsiveLayout` as a geometry coordinator. Local helpers own frame and tab geometry, form row layout, and portrait bounds while the public method retains the final `self.layout` snapshot. Responsive stacking, two-column thresholds, child bounds, appearance delegation, and stored layout fields remain unchanged.

Focused Unique NPC editor model, transfer, base editor, debug window, and appearance checks pass `5/5`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `161` production findings, `30.1` UI pressure, and `91.7/100` production health.

## Current validation checkpoint (post Chunk 218)

The broad suite passes `783/783`. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass. The earlier `33`-failure baseline has no current failing names in this run.

## Next Chunk Review

Continue with a bounded large-module seam in the Unique NPC appearance window or editor model. Use focused appearance, editor-model, and transfer coverage; preserve draft mutation ownership, appearance field contracts, and preview synchronization.


## Chunk 219 — Unique NPC appearance construction ownership

`PNC_UniqueNPCAppearanceWindow.lua` now keeps `ISPNCUniqueNPCAppearanceWindow:createChildren` as a construction coordinator. Local helpers own appearance state initialization, top action controls and scroll content, outfit and voice controls, skin controls, and final option or draft synchronization. Public control callbacks, draft references, option sources, child registration order, location rows, and `syncFromDraft` behavior remain unchanged.

Focused Unique NPC appearance, editor model, transfer, base editor, and debug window checks pass `5/5`. The module passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit remains at `161` production findings, `30.1` UI pressure, and `91.7/100` production health; the appearance module remains a large-module follow-up because its other responsibilities are still intentionally grouped by appearance domain.

## Current validation checkpoint (post Chunk 219)

The broad suite passes `783/783`. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass. The earlier `33`-failure baseline has no current failing names in this run.

## Next Chunk Review

Continue with the remaining Unique NPC editor module seam only where ownership is clear. The remaining UI findings are the appearance module, editor model, and editor window module sizes. Preserve appearance domain grouping, draft mutation ownership, preview synchronization, and stable editor contracts.


## Chunk 220 — Unique NPC editor model provider split

`PNC_UniqueNPCEditorModel.lua` remains the stable model entry point and now loads two same-root providers. `PNC_UniqueNPCEditorModel_Definition.lua` owns definition import and sparse serialization; `PNC_UniqueNPCEditorModel_Runtime.lua` owns preview runtime synchronization, appearance patching, equipment visual capture, and runtime record refresh. A small internal helper table shares copy, naming, item export, appearance capture, and related state without changing the public `PNC.UniqueNPCEditorModel` API or existing require path.

Focused Unique NPC editor model, transfer, base editor, debug window, and appearance checks pass `5/5`. The entry point and both providers pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `160` production findings, `27.3` UI pressure, and `92.3/100` production health; the editor model large-module finding is resolved.

## Current validation checkpoint (post Chunk 220)

The broad suite passes `783/783`. Whole-tree Lua parsing, the stale colony-presentation path guard, and `git diff --check` pass. The earlier `33`-failure baseline has no current failing names in this run.

## Next Chunk Review

Continue with a bounded editor window module seam. The remaining UI module findings are the Unique NPC editor window and appearance window; preserve their existing entry paths, public window methods, draft ownership, and provider load order.


## Chunk 221 — Unique NPC appearance layout provider split
`PNC_UniqueNPCAppearanceWindow.lua` remains the stable appearance-window entry point and now loads `PNC_UniqueNPCAppearanceWindow_Layout.lua`. The provider owns `ISPNCUniqueNPCAppearanceWindow:onResponsiveLayout` while the entry point supplies the existing shared layout helper through its internal dependency table. Control bounds, responsive sizing, scroll height and scrollbar placement, row order, and resize callbacks remain unchanged. Existing draft-sync provider load order and public window methods remain stable. Focused colonist activity plus Unique NPC appearance/editor/model/transfer/debug checks pass `6/6`. The appearance entry point, layout provider, and draft-sync provider pass PZ Kahlua verification; all parse with `luac`; whole-tree parsing, stale colony-presentation path guard, and `git diff --check` pass. Refreshed architecture audit reports `159` production findings, `24.6` UI pressure, and `92.9/100` production health; the appearance large-module finding is resolved and the remaining UI large module is `PNC_UniqueNPCEditorWindow.lua`.

## Current validation checkpoint (post Chunk 221)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass.

## Next Chunk Review
Continue with the remaining Unique NPC editor window seam only where ownership is clear. Preserve existing entry paths, public window methods, draft mutation ownership, provider load order, and editor tab behavior.


## Chunk 222 — Unique NPC editor detail provider split
`PNC_UniqueNPCEditorWindow.lua` now keeps the public editor shell and action dispatch while `PNC_UniqueNPCEditorWindow_Details.lua` owns detail row construction, detail selection refresh, skill and trait additions, authored detail removal, and detail reset. Model calls, draft mutation fields, pending selection keys, runtime inventory adoption, remove-button enablement, status text, and action names remain unchanged. Focused Unique NPC appearance/editor/model/transfer/debug checks pass `5/5`; the entry point and provider pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`.

## Chunk 223 — Unique NPC editor form provider split
`PNC_UniqueNPCEditorWindow_Form.lua` now owns core and repeater row construction, archetype/gender/equipment/style/repeater option refresh, and combo change routing. The main window passes the existing UI and option helpers through its internal dependency table; control IDs, callbacks, authored appearance flags, option data, and form-change routing remain unchanged. Focused checks pass `5/5`; entry point and provider pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`.

## Chunk 224 — Unique NPC editor preview provider split
`PNC_UniqueNPCEditorWindow_Preview.lua` now owns status updates, effective draft selection, preview rebuild, form-change routing, appearance propagation, and runtime preview adoption. The main window still owns the public class and loads the provider from the existing require path; preview model calls, portrait rendering, appearance-tab synchronization, and status messages remain unchanged. Focused checks pass `5/5`; entry point and provider pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`.

## Chunk 225 — Unique NPC editor persistence provider split
`PNC_UniqueNPCEditorWindow_Persistence.lua` now owns saved-draft list refresh and selected-draft loading. Storage access, file selection preservation, failure status messages, draft replacement, appearance-tab synchronization, and forced preview rebuild remain unchanged. Focused checks pass `5/5`; entry point and provider pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `158` production findings, `21.8` UI pressure, `100.0/100` UI health, and `93.6/100` production health; the Unique NPC editor window large-module finding is resolved.

## Current validation checkpoint (post Chunk 225)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass. The graph generation remains `2026-09-30T23:25:13Z`; changed and new provider files were read directly and validated because they are not represented as fresh graph records.

## Next Chunk Review
Continue the broader Project Hoomans refactor from the current audit and graph evidence. Preserve existing public entry paths, load order, semantic dialogue contracts, multiplayer authority, and bounded runtime work.


## Chunk 226 — Semantic telemetry filename probing is bounded
`PNC_SemanticTelemetryStorage.lua` now bounds collision probing in `nextFileName` to `MAX_FILENAME_PROBES = 1024`. Existing index validation, file-exists handling, filename format, and successful first-free-name behavior remain unchanged. Exhaustion now returns the explicit `telemetry_probe_limit` reason instead of leaving a client operation in an unbounded loop. Focused semantic NLU, dialogue, diagnostics, and local-route checks pass `4/4`; the storage file passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The refreshed architecture audit reports `157` production findings, `36.0` semantics pressure, and `93.7/100` production health; the telemetry unbounded-loop finding is resolved.

## Current validation checkpoint (post Chunk 226)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass.

## Next Chunk Review
Continue the broader Project Hoomans refactor from the remaining bounded-work and dependency findings. Preserve semantic dialogue contracts and document any intentional finite exhaustion behavior.


## Chunk 227 — Physical inventory capture uses a bounded item snapshot
`PNC_Inventory_CorePhysicalAdapter.lua` now captures the physical adapter’s materialized item list once and iterates it with a finite indexed loop. Presentation-item exclusion, item encoding, state decoding, operation ordering, atomic delta application, and equipment/cache fallback behavior remain unchanged. Focused inventory transactions, state roundtrip, equipment sync, transfer rollback, and Unique NPC transfer checks pass `5/5`; the adapter passes PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. Refreshed architecture audit reports `155` production findings and no remaining `UNBOUNDED_LOOP` category.

## Current validation checkpoint (post Chunk 227)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass.

## Next Chunk Review
Continue with the remaining dependency cycles, composition coupling, and high-density modules. Keep server/client authority boundaries, inventory atomicity, semantic contracts, and bounded work explicit.


## Chunk 228 — Shared composition load order is segmented
`PNC_SharedComposition.lua` remains the stable shared composition entry point and now delegates its current require sequence to five ordered providers: Foundation, IdentitySocial, InventoryWorld, CombatRuntime, and Final. The providers preserve all `226` existing dependency names and their current working-tree order; the root path and bootstrap delegation remain unchanged. Composition smoke capture stubs now expand provider files so their predecessor/successor assertions continue to inspect the full dependency sequence. Composition bootstrap and pathing/presence boundary checks pass `2/2`; the root and providers pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The audit still reports two composition dependency-cycle findings and composition coupling because these files remain load-order composition roots; this slice improves ownership of the contractual order without claiming dependency inversion.

## Current validation checkpoint (post Chunk 228)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass.

## Next Chunk Review
Continue with the remaining high-density runtime modules and composition-cycle evidence. Preserve current bootstrap order, server/client authority boundaries, and public entry paths.


## Chunk 229 — Animation debug player equipment provider
`PNC_AnimationDebugPlayer.lua` now delegates temporary ranged-equipment discovery, snapshot capture, variable restoration, and override application to `PNC_AnimationDebugPlayer_Equipment.lua`. The player retains ownership of the internal equipment table and public animation player API; playback cleanup and failure reasons remain unchanged.

## Chunk 230 — Animation debug player track provider
`PNC_AnimationDebugPlayer_Track.lua` now owns animation track timing, native clip creation, debugger-owned track release, pose holding, and finished-track maintenance. The main player passes its existing invocation/read/write helpers through an internal table; track timing, pause behavior, blend setup, cleanup fallback, and runtime state fields remain unchanged.

## Chunk 231 — Animation debug player condition provider
`PNC_AnimationDebugPlayer_Conditions.lua` now owns selector condition coercion, read-only selector guards, save/apply and restore behavior, and preview metadata marking/clearing. The original selector adapter tables and read-only set are passed through the internal dependency table; `PNCActor` enforcement, skipped-selector reporting, metadata keys, and reload cleanup remain unchanged. The existing animation smoke loader now expands all three providers when it mocks `require`. Focused animation player, player animation, snapshot gate, and scene checks pass `4/4`; the player and all three providers pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. Refreshed architecture audit reports `158` production findings, `11` large modules, and `93.7/100` production health; the animation debug player large-module finding is resolved.

## Current validation checkpoint (post Chunk 231)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass.

## Next Chunk Review
Continue with the remaining high-density runtime modules, prioritizing clear ownership seams and preserving debug contracts, cleanup behavior, and load order.


## Chunk 232 — Live body heavy-item safety provider
`PNC_LiveBodyControl_State.lua` now loads `PNC_LiveBodyControl_HeavyItems.lua` for heavy-held-item detection, native movement detection, climb-ahead clearing, and heavy hand-slot clearing. The state module retains its stable path and passage-blocking coordinator; client-only packet safety, server authority guard, hand-slot behavior, diagnostics increment, and exported `LiveBodyControl` method names remain unchanged. Graph evidence identifies `LiveBodyControl_Events.OnZombieUpdate` and the dedicated heavy-item smoke coverage as callers. Focused heavy-item, vanilla passage, pathing boundary, and ambient-facing checks pass `4/4`; state and provider pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. Refreshed architecture audit reports `157` production findings, `10` large modules, and `93.9/100` production health; the LiveBodyControl state large-module finding is resolved.

## Current validation checkpoint (post Chunk 232)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass.

## Next Chunk Review
Continue with the remaining high-density runtime modules, prioritizing bounded, ownership-preserving seams in presence, needs, director, zombies, and firearm systems.


## Chunk 233 — Ambient visit mobile-site provider
`PNC_AmbientVisitService.lua` now delegates mobile shelter site caching, retry failures, cache trimming, resolver calls, and target-bound validation to `PNC_AmbientVisitService_MobileSites.lua`. The lease service retains the stable `TryStartMobileShelter` flow; site keys, oldest-first bounded cache eviction, retry timestamps, resolver reasons, target bounds checks, and copied site payloads remain unchanged.

## Chunk 234 — Ambient visit eligibility provider
`PNC_AmbientVisitService_Eligibility.lua` now owns the public lease lookup and ambient eligibility gates: `Get`, `IsActive`, `IsOrderProtected`, `CanUseAmbient`, and `IsEligible`. Internal lease, authority, body-materialization, order, blocked-runtime, and constants dependencies are passed explicitly from the service. Public method names, failure reasons, authority checks, lease expiry behavior, ownership guards, and blocked-runtime rules remain unchanged. Both providers tolerate standalone server-file loading when the parent service is absent, preserving the MP loader guard contract. Focused ambient lease, mobile ambient, roam ambient, and path-facing checks pass `4/4`; service and providers pass PZ Kahlua verification, Lua syntax parsing, and `git diff --check`. The server-file inventory guard baseline is updated from `871` to `873` for the two intentional provider files. Refreshed architecture audit reports `156` production findings, `9` large modules, and `93.9/100` production health; the ambient visit service large-module finding is resolved.

## Current validation checkpoint (post Chunk 234)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, MP server-file inventory guard, and `git diff --check` pass.

## Next Chunk Review
Continue with the remaining high-density runtime modules, prioritizing explicit ownership boundaries and preserving standalone loader safety for server files.

## Chunk 235 — Zombie aggro multiplayer directive provider
`PNC_ZombieAggro_Update.lua` now delegates multiplayer pursuit directive publication and clearing to `PNC_ZombieAggro_Update_Multiplayer.lua`. The stable update module retains `PNC_ZombieAggro.Pump`, coordinate path requests, target selection, stealth suppression, bite ownership, and private call sites; directive payload fields, revisions, TTL and movement throttles, network-unavailable diagnostics, ModData cleanup, and server authority behavior remain unchanged. The provider receives the existing diagnostic and authority helpers through an internal dependency table, and the update module initializes its internal namespace for standalone pathing smoke loaders. Focused multiplayer zombie aggro, coordinate path, stealth suppression, and compatibility checks pass `4/4`; both files pass PZ Kahlua verification, whole-tree Lua parsing, and `git diff --check`. The refreshed architecture audit reports `155` production findings, `93.9/100` production health, and the zombie aggro update module is below the large-module threshold.

## Current validation checkpoint (post Chunk 235)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass. Codebase graph coverage reports no recorded issue for the operated files; the modified main file has metadata-changed freshness and the new provider is not tracked by the current graph generation, so direct source validation is the evidence for those paths.

## Next Chunk Review
Continue with the remaining high-density runtime modules in presence, needs, director, and firearm systems. Preserve public entry paths, multiplayer authority, bounded work, and standalone loader behavior.

## Chunk 236 — Away need route catalog providers
`PNC_NeedFacilityTriggers_AwayRoutes.lua` now keeps the shared route predicates, candidate construction, retry policy, hydration policy, and movement helpers while loading five ordered providers for personal hydration, water refill, camp routes, personal food, and world water. The provider order preserves the original six `Routes.Register` blocks, `BySource` registration, ordered candidate behavior, route identifiers, facility assignments, retry reasons, and server authority guard. Helper functions are passed through `Routes.Internal`; each provider returns safely when the parent route namespace is absent so the MP server-file loader can inspect them independently. Focused need-facility, camp-sleep, hydration-policy, and MP server-file guard checks pass `4/4`; whole-tree Lua parsing, the route directory PZ Kahlua check, and `git diff --check` pass. The server-file inventory guard baseline is updated from `873` to `878` for the five intentional providers. Refreshed architecture audit reports `154` production findings and `94.0/100` production health.

## Current validation checkpoint (post Chunk 236)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, MP server-file inventory guard, and `git diff --check` pass. Codebase graph coverage reports no recorded issue for the operated paths; the modified entry file has metadata-changed freshness and the five new providers are not tracked by the current graph generation, so direct source validation is used for those files.

## Next Chunk Review
Continue with the remaining high-density runtime modules in presence, director, firearm, and other composition-adjacent systems. Preserve provider order, public entry paths, server authority, and standalone loader safety.

## Chunk 237 — Client firearm screen renderer provider
`PNC_ClientFirearmEffects.lua` now delegates queued muzzle-flash and tracer screen rendering to `PNC_ClientFirearmEffects_UIDraw.lua`. The stable effects module retains native capability checks, world-space muzzle resolution, audio, impact effects, shot deduplication, simulation controls, tick cleanup, reset behavior, public `OnPreUIDraw`, and event registration. Renderer culling, zoom handling, renderline coordinates, colors, TTL advancement, audit events, and queue removal behavior remain unchanged. Drawing dependencies are passed through an internal table and the provider returns safely when the client effects namespace is absent. Focused firearm effects, native firearm effects, anchor, and combat-presence checks pass `4/4`; both files pass PZ Kahlua verification, whole-tree Lua parsing, and `git diff --check`. Refreshed architecture audit reports `154` production findings and `94.0/100` production health.

## Current validation checkpoint (post Chunk 237)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass. Codebase graph coverage reports no recorded issue for the operated paths; the modified effects file has metadata-changed freshness and the new renderer provider is not tracked by the current graph generation, so direct source validation is used for those files.

## Next Chunk Review
Continue with the remaining high-density presence, director, and combat-adjacent modules while preserving client event registration, effect queues, and bounded runtime work.

## Chunk 238 — Corpse-awareness relationship provider
`PNC_BodyLifecycle_CorpseAwareness.lua` now delegates kinship markers, relationship normalization, faction hostility, category classification, relation lookup, memory ID creation, duplicate-memory checks, and bounded death-memory counting to `PNC_BodyLifecycle_CorpseAwareness_Relationship.lua`. The stable awareness module retains corpse inspection, death attribution, witness memory writes, candidate collection, visibility checks, reaction scheduling, and public observation methods. Relationship categories, memory prefixes and limits, bounded relationship scans, faction rules, and witness behavior remain unchanged. The provider receives the parent `lower` normalizer and constants through an internal dependency table and returns safely when the awareness namespace is absent. Focused corpse-awareness, corpse transfer, lifecycle boundary, and social greeting checks pass `4/4`; both files pass PZ Kahlua verification, whole-tree Lua parsing, and `git diff --check`. Refreshed architecture audit remains at `154` production findings and `94.0/100` production health.

## Current validation checkpoint (post Chunk 238)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, and `git diff --check` pass. Codebase graph coverage reports no recorded issue for the operated paths; the modified awareness file has metadata-changed freshness and the new relationship provider is not tracked by the current graph generation, so direct source validation is used for those files.

## Next Chunk Review
Continue with the remaining director and presence-adjacent modules, preserving bounded scans, social memory contracts, public observation paths, and load order.

## Chunk 239 — Mobile director target provider
`PNC_MobileGroupDirector_Ambient.lua` now delegates shelter and road-zone target discovery to `PNC_MobileGroupDirector_Ambient_Targets.lua`. The stable director module retains ownership snapshots, shelter validation, ambient phase, order construction and repair, strategic refresh, abstract objectives, faction refresh, scheduler cursoring, and public internal methods. Shelter resolver filters, road-zone enumeration, target payloads, search radii, diagnostics timing, finite numeric normalization, and target-selection reasons remain unchanged. The provider receives the existing diagnostic timing and numeric helper functions through `MobileGroupDirectorInternal` and returns safely when the server namespace is absent. Focused mobile ambient, mobile group, director boundary, and population director checks pass `6/6`; the MP server-file guard passes with a `879` file baseline, and both files pass PZ Kahlua verification, whole-tree Lua parsing, and `git diff --check`. Refreshed architecture audit remains at `154` production findings and `94.0/100` production health.

## Current validation checkpoint (post Chunk 239)
Broad suite passes `783/783`. Whole-tree Lua parsing, stale colony-presentation path guard, MP server-file inventory guard, and `git diff --check` pass. Codebase graph coverage reports no recorded issue for the operated paths; the modified director file has metadata-changed freshness and the new target provider is not tracked by the current graph generation, so direct source validation is used for those files.

## Next Chunk Review
Review remaining composition and dependency findings with the same bounded provider approach. Preserve ambient order semantics, scheduler budgets, server authority, and standalone loader safety.

## Chunk 240 — HuskLedger debug provider
`PNC_BodyLifecycle_HuskLedger.lua` now delegates bounded debug snapshot/report generation, ledger clearing, persisted-record seeding, and diagnostics projection to `PNC_BodyLifecycle_HuskLedger_Debug.lua`. The stable ledger module retains ModData storage, schema packing, index rebuilds, expiry and overflow eviction, husk matching, rearming, lost-body recording, and shell-outfit identity state. Debug entry limits, census fallback, estimated-byte accounting, seed authority checks, persistence calls, counters, and public lifecycle method names remain unchanged. The provider receives storage, diagnostics, census, layout, and identity helpers through an internal dependency table. Focused HuskLedger, end-to-end husk lifecycle, reaper, lost-body, and reanimation checks pass `5/5`; both files pass PZ Kahlua verification, whole-tree Lua parsing, and `git diff --check`. The refreshed architecture audit reports `154` production findings, `94.0/100` production health, and `58.3%` confidence.

## Final architecture checkpoint (post Chunk 240)
The refactor now has behavior-preserving provider boundaries across UI rendering, semantic telemetry, inventory persistence, shared composition, animation debugging, pathing safety, ambient visits, zombie aggro, needs route catalogs, firearm effects, corpse awareness, mobile director targets and orders, and HuskLedger diagnostics. Stable public entry files remain in place; providers load in explicit order and pass narrow internal dependencies. Whole-tree syntax, Kahlua checks for every operated slice, stale path guards, MP server-file inventory guards, focused smoke coverage, and the full `783/783` suite are green. The codebase graph generation is `2026-09-30T23:25:13Z`; modified paths report metadata-changed freshness and new providers are not tracked by that generation, so direct source reads and validation are the evidence for those files.

The architecture audit still identifies two composition dependency cycles and eight composition coupling findings. Its remaining high-density scope includes large functions in combat, semantics, social, tasking, facilities, and presence; Java output files are outside this Lua migration. The safest next seam is a separately audited large function with focused existing coverage, while composition roots should retain contractual require order until a dependency inversion can be proven without changing load behavior.

## Validation correction — post Chunk 239
The ambient orders provider added one intentional server Lua file after Chunk 239. The MP server-file inventory guard baseline is now `880`; the guard and full suite remain green.
