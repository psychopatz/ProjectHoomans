# Project Hoomans Monolith Refactor Report

Date: 2026-10-01
Project: `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`

## Scope

Refactor the Project Hoomans runtime into cohesive modules while preserving
public namespaces, load order, semantic contracts, client and server
authority, optional integrations, persistence behavior, and Project Zomboid
runtime compatibility.

## Evidence baseline

- Codebase-memory project: `project-hoomans`.
- Index generation used for the latest verified slice: `2026-09-30T23:25:13Z`.
- Index size: 73,274 nodes and 284,219 edges.
- Architecture audit: 2,565 production files, 355,932 scored production LOC,
  257 production findings, 17 large modules, and 196 large functions.
- Coverage is a best-effort signal. Modified entries reported
  `metadata_changed`; new spokes reported `not_tracked`. All operated-on
  source was read directly after the coverage check.

## Completed migrations

### Semantic response catalog

Entry:
`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua`

New spokes:

- `SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Situational.lua`
- `SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Questions.lua`
- `SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Social.lua`

The entry owns catalog mechanics, validation, bounded limits, condition
matching, deterministic selection, selection history, text fallback
registration, and generated response extension. The spokes own the 20 built-in
response pools by semantic responsibility. The original require path and
`PNC.Semantics.ResponseCatalog` public table remain unchanged.

### Puppet Opera blueprints

Entry:
`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints.lua`

Built-in scene definitions moved to
`PNC_PuppetOpera_Blueprints_Builtins.lua`. The entry owns runtime validation,
track and timeline access, capability checks, and the
public blueprint registry. The original require path, registry table, and
built-in IDs remain unchanged.

### Puppet Opera normalization boundary

Blueprint input normalization, actor and anchor validation, track lowering, and
timeline-node compilation now load through
`PNC_PuppetOpera_Blueprints_Normalization.lua`. The public blueprint entry keeps
registry composition, runtime capability checks, lookup, listing, and the
`Registry.Normalize`/`Register` contracts. The registry root is now 253 lines;
the cohesive normalization provider is 571 lines.

### Puppet Opera authority guard boundary

Distance and range checks, unsafe NPC action-state guards, actor admission
validation, and movement ownership validation now load through
`PNC_PuppetOpera_Authority_Guards.lua`. The authority root retains session
state, composition wiring, and the public authority contract. Existing
`Authority.Internal` guard names remain unchanged. The authority root is now
114 lines; the guard provider is 257 lines.

### Puppet Opera authority lifecycle boundary

Client delivery, phase transitions, session indexing, actor release, close,
and abort now load through
`PNC_PuppetOpera_Authority_Lifecycle.lua`. The authority root keeps the
session tables, public API, and ordered composition requires. The lifecycle
provider is 197 lines and loads after the root clock/trace seams and before
the admission and runtime providers. Existing `Authority.Internal` lifecycle
keys remain unchanged.

### Puppet Opera runtime timeline boundary

Timeline lookup, node selection, animation ownership, and per-node animation
observation now load through
`PNC_PuppetOpera_Authority_Runtime_Timeline.lua`. The runtime provider keeps
phase progression and session pumping in the authority runtime root. The root
is now 232 lines; the timeline provider is 238 lines. Its
`Authority.Internal` handoff is loaded by the guarded runtime provider.

### Puppet Opera runtime phase boundary

Movement, facing, beat preparation, and playback phase handlers now load
through `PNC_PuppetOpera_Authority_Runtime_Phases.lua`. The runtime root keeps
safety checks, override maintenance, session dispatch, and the public pump
entry. The phase provider is 271 lines and publishes the existing phase pump
handoffs through `Authority.Internal`.

### Puppet Opera runtime safety boundary

Active actor safety, movement and action-state validation, ownership checks,
and lease renewal now load through
`PNC_PuppetOpera_Authority_Runtime_Safety.lua`. The runtime root keeps
override maintenance, phase dispatch, timeout handling, and the public pump
entry. The root is now 113 lines; the safety provider is 144 lines.

### Puppet Opera runtime dispatch boundary

Override maintenance, phase dispatch, timeout handling, and the public pump
entry points now load through
`PNC_PuppetOpera_Authority_Runtime_Dispatch.lua`. The runtime root is now a
25 line dependency-ordered composition entry; the dispatch provider is 111
lines. Existing `Authority.Pump`, `Authority.PumpSession`, and internal
handoffs remain unchanged.

### Puppet Opera authority admission boundary

NPC and blueprint resolution, actor readiness, and preflight planning now
load through `PNC_PuppetOpera_Authority_Admission_Preflight.lua`. Session
construction, NPC lease acquisition, movement startup, and authoritative
start requests now load through
`PNC_PuppetOpera_Authority_Admission_Session.lua`. The admission root is a
21 line composition entry; the providers are 347 and 297 lines. The original
admission require path and `Authority.Internal` contracts remain unchanged.

### Puppet Opera authority request boundary

Session lifecycle actions now load through
`PNC_PuppetOpera_Authority_Requests_Session.lua`. Preflight, snapshot, and
trace actions now load through
`PNC_PuppetOpera_Authority_Requests_Readonly.lua`. The original Requests
module keeps authorization, response dispatch, acknowledgement fallback, and
the public `Authority.HandleRequest` entry. The root is 106 lines; session
and read-only providers are 121 and 79 lines. Existing request action names
and error response contracts remain unchanged.

### Puppet Opera authority response boundary

Server/client command delivery, state snapshots, and structured error
responses now load through
`PNC_PuppetOpera_Authority_Lifecycle_Response.lua`. The lifecycle module
keeps phase transitions, session indexes, actor release, and close behavior;
its root is 158 lines and the response provider is 66 lines. Existing
`Authority.Internal` response helpers and command payloads remain unchanged.

### Puppet Opera authority context boundary

Shared authority time, tracing, owner identity, and debug authorization now
load through `PNC_PuppetOpera_Authority_Context.lua`. The authority root keeps
namespace setup, ordered provider loading, and final event/router
registration. The root is 78 lines and the context provider is 60 lines;
existing `Authority.Internal` context handoffs remain unchanged.

### Puppet Opera authority bootstrap boundary

The final `OnTick` pump hook and server command registration now load through
`PNC_PuppetOpera_Authority_Bootstrap.lua`. The authority root is a 67-line
composition entry; the bootstrap provider is 31 lines and loads last after
the authority spokes. Existing `Authority.Pump` and request-router contracts
remain unchanged.

### Puppet Opera NPC ownership adapter boundary

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

### Lumber execution boundary

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

### Lumber WorkAdapter boundary

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
unchanged. The root and providers total 504 lines.

### World-effect service boundary

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

### WorkService queue and claim boundary

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

### WorkService scheduler boundary

`PNC_WorkService_Scheduler.lua` is now a 25-line composition root. Durable
order processing, quarantine guards, worker location transitions, and live or
abstract execution handoff load through
`PNC_WorkService_Scheduler_Orders.lua`; bounded reconciliation, priority
ordering, terminal-history pruning, diagnostics, and the scheduler pump load
through `PNC_WorkService_Scheduler_Pump.lua`. The original `Service.Tick`
entry point remains available through thin root wiring, the OnTick hook stays
at the composition boundary, and the WorkService require path and internal
handoffs remain unchanged.

### WorkService progress and completion boundary

`PNC_WorkService_Progress.lua` is now a 37-line composition root. Input
collection and assignment load through
`PNC_WorkService_Progress_Inputs.lua`; ordinary progress and elapsed-time
accounting load through `PNC_WorkService_Progress_Accounting.lua`; ordinary
completion and deferred world-effect finalization load through
`PNC_WorkService_Progress_Completion.lua`. The public `CollectInputs`,
`Assign`, `AddProgress`, `AddElapsed`, and `CompleteDeferred` command
signatures remain available through thin root wiring. The internal completion
handoff remains stable for accounting, and existing WorkService consumers,
load order, and server-only guards remain unchanged.

### WorkTaskProvider execution boundary

`PNC_WorkTaskProvider.lua` is now a 19-line composition root. Shared fatigue,
assignment, and lease-phase policy loads through
`PNC_WorkTaskProvider_Context.lua`; candidate discovery and assignment load
through `PNC_WorkTaskProvider_Assignment.lua`; lease cancellation, completion,
and recovery snapshots load through `PNC_WorkTaskProvider_Lease.lua`; and live
or abstract execution handler dispatch loads through
`PNC_WorkTaskProvider_Execution.lua`. The original provider table, callback
names, watchdog recovery contract, `work` registration, and server-only guard
remain at the original require path.

### TaskRequest command and snapshot boundary

`PNC_TaskRequestService.lua` is now a 15-line composition root. Player task
mutation and authorization commands load through
`PNC_TaskRequestService_Commands.lua`; the unified work, medical, lease, and
facility activity read model loads through
`PNC_TaskRequestService_Snapshots.lua`. The original `Commands` and `Queries`
tables, cancellation and pause/resume/retry command names, snapshot shape,
and server-only guard remain at the original require path.

### Tasking recovery boundary

`PNC_Tasking_Recovery.lua` is now a 37-line composition root. Watchdog state,
provider refresh, movement recovery observation, and recovery snapshots load
through `PNC_Tasking_Recovery_Context.lua`; retry and quarantine policy loads
through `PNC_Tasking_Recovery_Retry.lua`; stalled-lease recovery loads through
`PNC_Tasking_Recovery_Stall.lua`; and executor-failure recovery loads through
`PNC_Tasking_Recovery_Executor.lua`. Existing internal recovery methods,
watchdog domains, retry counters, quarantine behavior, and load order remain
unchanged.

### Tasking pump orchestration boundary

`PNC_Tasking_Pump.lua` is now a 68-line composition root. Shared timing and Puppet ownership helpers load through `PNC_Tasking_Pump_Context.lua`; orphan activity reconciliation loads through `PNC_Tasking_Pump_Reconciliation.lua`; bounded event inbox reevaluation loads through `PNC_Tasking_Pump_Evaluation.lua`; bounded executor and recovery dispatch loads through `PNC_Tasking_Pump_Execution.lua`. The original `Tasking.Commands.Pump` entry point, interval and budget behavior, initialization events, Puppet suspension and materialization behavior, recovery ordering, semantic ActionPlan pump, diagnostics, load path, and server-only guards remain unchanged.

### Task lease lifecycle boundary

`PNC_TaskLeaseService.lua` is now a 42-line composition root. Phase normalization and transition policy load through `PNC_TaskLeaseService_Context.lua`; creation and active-index ownership load through `PNC_TaskLeaseService_Creation.lua`; lookup and invariant queries load through `PNC_TaskLeaseService_Queries.lua`; cancellation policy loads through `PNC_TaskLeaseService_Cancellation.lua`; reservation release and terminal cleanup load through `PNC_TaskLeaseService_Release.lua`. The original `PNC.TaskLeaseService` table, public Create, RequestCancellation, Get, ForNPC, SetPhase, Release, CheckInvariants, and Count methods, phase transitions, cancellation deferral, reservation cleanup, active indexes, events, and server-only loading remain unchanged.

### WorkService operation registry boundary

`PNC_WorkService_OperationRegistry.lua` is now a 61-line provider loaded explicitly by the WorkService composition root and by the Core compatibility path. It owns the eight registration methods for completion, completion recovery, preparation, collection, target providers, live execution, abstract execution, and reconciliation. Core retains eligibility, worker selection, shared internal helpers, and handler-map initialization. The original WorkService registration methods, handler tables, direct Core load path, dependency order, and server-only loading remain unchanged.

### WorkService target/provider boundary

`PNC_WorkService_Targets.lua` is now a 12-line composition root. Target-provider and collection handoff loads through `PNC_WorkService_Targets_Providers.lua`; station and worker claim orchestration loads through `PNC_WorkService_Targets_Claim.lua`. The original `WorkService.Internal` target helpers, target-provider selection, collection behavior, station claims, live order projection, direct target-service load path, dependency order, and server-only loading remain unchanged.

### WorkService worker reconciliation boundary

`PNC_WorkService_WorkerReconciliation.lua` is now a 22-line composition root. Durable worker and station claim index rebuilding loads through `PNC_WorkService_WorkerReconciliation_Claims.lua`; stale NPC runtime and order-state recovery loads through `PNC_WorkService_WorkerReconciliation_State.lua`. The original `WorkService.ReconcileWorkerState` entry point, repository reload, claim ordering and repair behavior, stale worker cleanup, registry events, direct reconciliation load path, dependency order, and server-only loading remain unchanged.

### Social damage adapter boundary

`PNC_SocialEventHooks_DamageAdapter.lua` is now a 14-line composition root. Shared combat event context and delivery helpers load through `PNC_SocialEventHooks_DamageAdapter_Context.lua`; social damage and witness recorders load through `PNC_SocialEventHooks_DamageAdapter_Recorders.lua`; vanilla damage snapshots and polling load through `PNC_SocialEventHooks_DamageAdapter_Polling.lua`. The original `SocialEventHooksInternal` damage callbacks, relationship event payloads, witness delivery, vanilla marker state, engine callback registration, direct adapter load path, dependency order, and server-only loading remain unchanged.

### Social combat adapter boundary

`PNC_SocialEventHooks_CombatAdapter.lua` is now a 13-line composition root. Zombie awareness emission and public horde/stamina hooks load through `PNC_SocialEventHooks_CombatAdapter_Awareness.lua`; player-kill witness attribution and engine callbacks load through `PNC_SocialEventHooks_CombatAdapter_Witnesses.lua`. The original `SocialEventHooksInternal` callback names, public awareness hooks, relationship memory updates, core-detector integration, direct adapter load path, dependency order, and server-only loading remain unchanged.

### Social event downstream bridge boundary

`PNC_SocialEventService_Process_Bridges.lua` now owns post-transaction faction incident recording, faction telemetry, processed-event diagnostics, and knowledge evidence recording. `SocialEvents.Process` retains validation, observer preflight, relationship mutation, and conduct transaction ownership while preserving the original output object and bridge ordering.

### Social event transaction boundary

`PNC_SocialEventService_Process.lua` is now a 118-line orchestration provider. Relationship and conduct preparation, mutation, commit, and transaction failure fields load through `PNC_SocialEventService_Process_Transaction.lua`; downstream faction, diagnostics, and knowledge bridges remain in `PNC_SocialEventService_Process_Bridges.lua`. The original `SocialEvents.Process` signature, validation and observer ordering, mutation detail payloads, conduct commit behavior, rejection reasons, bridge ordering, direct service load path, dependency order, and server-only loading remain unchanged.

### Social teammate damage delivery boundary

Teammate witness scanning and ambient flavor delivery extracted from
deliverTeammateDamageFlavor now load through the dedicated
PNC_SocialEventHooks_DamageAdapter_TeammateDelivery.lua provider.
The provider is 262 lines; the recorder provider is 469 lines and retains
the original NPC damage recorder callbacks behind the internal handoff.
Authority, throttling, witness filtering, delivery radius, event IDs,
treatment context, transport, audit phases, load order, and server guards
remain unchanged.

### Conversation ambient receive boundary

`PNC_SocialFlavorPresentation.lua` retains shared identity, medical-request,
speech, safety, and delivery helpers while loading the 222-line
`PNC_SocialFlavorPresentation_Receive.lua` provider for the authoritative
`Presentation.Receive` queue boundary. The internal helper handoff preserves
NPC and player identity shaping, relationship context, medical supply state,
queue payloads, presentation state, immediate pumping, logging, the public
presentation namespace, and the original load path.

### Conversation gift-result boundary

`PNC_ConversationComposer_Gifts.lua` is now a 10-line composition root.
Gift lifecycle, authoritative relationship refresh, group-session routing,
dialogue append, preference-aware replies, failure replies, and diary
recording load through the 295-line
`PNC_ConversationComposer_Gifts_Receive.lua` provider. The original
`Composer.ReceiveGiftResult` contract, duplicate handling, lifecycle
cleanup, semantic gift context, inventory close, text loading, and
conversation progression remain unchanged.

### Conversation sandbox-definition boundary

`PNC_ConversationDebugModel.lua` now keeps context defaults, listing,
inspection, sandbox execution, and OpenSandbox while loading the 330-line
`PNC_ConversationDebugModel_Sandbox.lua` provider for sandbox text, node,
choice, relationship-panel, and definition construction. The public
`Model.BuildSandboxDefinition` and `Model.OpenSandbox` contracts, cloned
context behavior, graph navigation, choice execution, relationship preview,
and debug namespace remain unchanged.

### Conversation root-menu boundary

`PNC_ConversationComposer_Menu.lua` now keeps category diagnostics and
greeting construction while loading the 279-line
`PNC_ConversationComposer_Menu_Root.lua` provider for category choices,
debug choice, and root-menu construction. The original root and menu node
contracts, category selection, hostile ceasefire, recruitment, settlement
admission, departure, goodbye, debug, translation, and preview behavior
remain unchanged.

### Conversation authority choice boundary

`PNC_ConversationAuthority_Choice.lua` is now an 11-line composition root.
The 171-line `PNC_ConversationAuthority_Choice_Handle.lua` provider owns
authoritative choice validation, replay handling, context construction,
effect application, history commits, state progression, and outcome
transport. The original `Authority.HandleChoice` contract, rejection
reasons, relationship payloads, processed-request state, close behavior,
direct authority load path, dependency order, and server-only guard remain
unchanged.


### Corpse haul work adapter diagnostics boundary

Durable operation diagnostics, throttled logging, and failure metadata now
load through
`PNC_CorpseHaulService_WorkAdapter_Diagnostics.lua`. The work adapter keeps
the existing `Service.Internal` diagnostic handoff and task failure behavior.
The diagnostics provider is 104 lines.

### Corpse haul work adapter targeting boundary

Live and abstract target selection, drop-point validation, world wait state,
and work-scene status observation now load through
`PNC_CorpseHaulService_WorkAdapter_Targeting.lua`. The work adapter keeps
transfer effects, cleanup, and tick orchestration. The work adapter root is
now 875 lines; the targeting provider is 145 lines.

### Corpse haul work adapter cleanup boundary

Live route reset, carried-corpse preservation, marker cleanup, runtime index
release, and work-sequence reset now load through
`PNC_CorpseHaulService_WorkAdapter_Cleanup.lua`. These effects remain one
boundary so a terminal operation cannot release only part of its ownership.
The work adapter root is now 741 lines; the cleanup provider is 152 lines.

### Corpse haul work adapter transfer boundary

Live corpse movement, durable completion, cancellation recovery, deferred
world effects, and completion retry handling now load through
`PNC_CorpseHaulService_WorkAdapter_Transfer.lua`. The work adapter keeps
worker tick progression and service registration. The work adapter root is
now 443 lines; the transfer provider is 342 lines.

### Corpse haul work adapter tick boundary

Live phase advancement, abstract progress, worker release, interaction
timeouts, carry progression, and transfer handoff now load through
`PNC_CorpseHaulService_WorkAdapter_Tick.lua`. The work adapter root remains
the ordered composition point for provider loading, public registration,
cancellation wiring, and world effect registration. The root is now 227
lines; the tick provider is 257 lines. Existing `Service.Internal` handoffs
and Work registration names remain unchanged.

### Corpse haul dispatch boundaries

Automatic corpse selection and background order creation now load through
`PNC_CorpseHaulService_Dispatch_Assignment.lua`. Manual request validation,
order reuse, immediate reevaluation, and request diagnostics now load through
`PNC_CorpseHaulService_Dispatch_Manual.lua`. The original `Dispatch.lua`
require path remains the composition point and keeps terminal-order pruning;
its root is 56 lines, with 135 line assignment and 385 line manual providers.
The existing `Internal` functions and public `Service.RequestManual` entry
remain unchanged.

### Corpse haul reconciliation candidate boundary

Corpse discovery, identity scoring, reservation rebinding, duplicate cleanup,
and reservation marker cleanup now load through
`PNC_CorpseHaulService_Reconciliation_Candidates.lua`. The original
`Reconciliation.lua` path remains the active reconciliation composition point
and keeps pending world-effect handling, legacy completion recovery, order
retirement, and bounded active scanning. The root is now 352 lines; the
candidate provider is 366 lines. Existing reconciliation `Internal` entry
points remain unchanged.

### Corpse haul active reconciliation boundary

Pending world effects, legacy completion recovery, durable retirement,
reconciliation diagnostics, and bounded active-order scans now load through
`PNC_CorpseHaulService_Reconciliation_Active.lua`. The original
`Reconciliation.lua` path remains a 14 line composition root that loads the
candidate provider before the active provider. The active provider is 356
lines; the candidate provider remains 366 lines. Existing pending-effect and
active-order `Internal` entry points remain unchanged.

### Companion command group-camp boundary

Entry:
`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Commands/PNC_CompanionCommandRegistry.lua`

The group-camp composition boundary is now split across
`PNC_CompanionCommandRegistry_GroupCamp.lua`,
`PNC_CompanionCommandRegistry_GroupCampDetails.lua`,
`PNC_CompanionCommandRegistry_GroupCampRecipients.lua`, and
`PNC_CompanionCommandRegistry_GroupCampApplication.lua`. The composition
provider owns site validation and the private service seams; the details,
recipient, and application providers own bounded serialization, admission,
coordinator fallback, order installation, and network effects respectively.
The public `PNC.CompanionCommands` API remains unchanged.

### Companion command registry boundary

Registration, group registration, lookup, ordered listing, attack-type
normalization, and command-specific eligibility moved to
`PNC_CompanionCommandRegistry_Registry.lua`. The parent entry retains identity
and ownership checks, proximity and radio authority, follow-order preparation,
attack application, group-camp integration, command application, and protocol
execution. The original registry require path and public methods remain
unchanged.

### Companion command authority boundary

Identity, ownership, live-position resolution, proximity eligibility, and radio
relay policy moved to `PNC_CompanionCommandRegistry_Authority.lua`. The parent
entry retains order preparation, equipment and attack application, command
application, group-camp integration, and protocol execution. Live-position
access is exposed through the existing internal command seam for closest-target
selection. Public authority methods and signatures remain unchanged.

### Companion command execution boundary

Target selection, scope handling, closest-target resolution, group dispatch, and
result shaping moved to `PNC_CompanionCommandRegistry_Execution.lua`. The
parent entry retains the single-record application pipeline and its order,
equipment, network, and runtime mutation effects. The original
`Commands.Execute` entry point and return shapes remain unchanged.

### Companion command application boundary

Single-record command application, follow-order preparation, attack-type
effects, equipment refresh, runtime command metadata, and network broadcast
moved to `PNC_CompanionCommandRegistry_Application.lua`. The original registry
file is now a 25-line composition root that initializes the public namespace and
loads registry, authority, application, group-camp, and execution providers in
order. `Commands.Apply` retains its signature, return values, authority guard,
side-effect order, and public namespace.

### Group-camp details boundary

Primitive-only group-camp response serialization moved to
`PNC_CompanionCommandRegistry_GroupCampDetails.lua`. It owns bounded text and
number normalization, compact site details, task-lease snapshots, and target
detail lists. Group-camp validation, recipient admission, coordinator fallback,
order installation, and network effects remain in the group-camp provider. The
`CampCommandDetails` internal seam preserves the existing response shape and
bounds.

### Group-camp recipient admission boundary

Bounded recipient selection moved to
`PNC_CompanionCommandRegistry_GroupCampRecipients.lua`. It owns ownership
verification, materialized-live checks, explicit target-ID normalization,
legacy registry fallback, duplicate suppression, radius eligibility, and stable
ID ordering. Site validation, coordinator fallback, order installation, and
network effects remain in the group-camp provider. The internal recipient seam
preserves the existing admission rules and 32-target bound.

### Group-camp application boundary

Coordinator invocation, compatibility fallback, group-camp ID generation,
order installation, runtime mutation, and network broadcast moved to
`PNC_CompanionCommandRegistry_GroupCampApplication.lua`. The group-camp entry
retains site validation and shared internal seams; details and recipient
admission remain separate providers. `Commands.ApplyGroupCamp` keeps its
signature, return shapes, authority guard, coordinator fallback, and bounded
response behavior.

### Performance diagnostics settings boundary

Entry:
`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics.lua`

Central debug-settings registration and startup hydration moved to
`PNC_PerformanceScalingDiagnostics_Settings.lua`. The entry retains counters,
timing, logging, gauges, export, and the existing inventory audit extension.
The settings IDs, disabled-path behavior, optional PsychopatzCore integration,
registration order, and public diagnostics table remain unchanged.

### Performance diagnostics runtime boundary

Runtime metric sampling, bounded runtime summaries, frame and path breakdown
recording, gauge refresh, profiler export, and snapshots moved to
`PNC_PerformanceScalingDiagnostics_Runtime.lua`. The entry retains persistent
state initialization, counter and timing primitives, opt-in event logging,
and the inventory audit extension. A small `Diagnostics.Internal.TimingNow`
seam supplies the shared clock behavior without exposing a new public API.
The original diagnostics entry path and every `Diagnostics.*` method remain
unchanged.

### Performance diagnostics audit logging boundary

Opt-in network, seating, sleep, zombie aggro, NPC threat, firearm, needs,
follower, and build audit formatting moved to
`PNC_PerformanceScalingDiagnostics_AuditLogging.lua`. The provider also owns
seating and sleep snapshots plus build trace correlation. Channel state and
startup registration remain in the entry and settings provider, so existing
runtime overrides and optional integrations continue to read the same fields.

### Facility behavior arrival and scene boundary

Entry:
`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior.lua`

Arrival positioning and seat or sleep surface preparation moved to
`PNC_FacilityJobsBehavior_Arrival.lua`. Scene admission and animation request
startup moved to `PNC_FacilityJobsBehavior_SceneStart.lua`. The behavior entry
loads the existing state, lifecycle, camp, and scene providers first, then
arrival, scene start, and the reduced tick coordinator in that order. The
`Internal.Tick` entry point, retry behavior, seat transitions, sleep placement,
water refill admission, and animation scene request contract remain unchanged.
The tick provider is now 188 physical lines; Arrival and SceneStart are 245
and 220 lines respectively.

### Facility service durable state boundary

`PNC_FacilityJobs_Service_StartState.lua` now owns durable facility activity
state creation, normalized executor order installation, live-object bookkeeping,
and start diagnostics. `PNC_FacilityJobs_Service_Start.lua` retains authority
checks, facility and activity acquisition, target normalization, and the public
`Jobs.Start` and `Jobs.StartForFacility` entry points. The new provider loads
before Start through the existing server service composition root and is gated
by the server runtime role. The service API, persisted field names, order shape,
and return values remain unchanged.

### Facility service durable activity-state boundary

The durable start path now separates state construction from installation.
`PNC_FacilityJobs_Service_StartState_Activity.lua` builds the save-safe
facility activity descriptor, while
`PNC_FacilityJobs_Service_StartState_Order.lua` builds the normalized executor
order. `PNC_FacilityJobs_Service_StartState.lua` is now a 72-line composition
provider that retains record mutation, live-object bookkeeping, diagnostics,
and the existing `H.InstallActivity` return contract. The activity and order
providers load before the composition provider installs the public start path.

### Facility service manual-start orchestration boundary

### Facility service start-targeting boundary

Target normalization, live-object lookup, approach-candidate copying, sleep
target validation, and start-context construction now load through
`PNC_FacilityJobs_Service_Start_Targeting.lua`. `PNC_FacilityJobs_Service_Start.lua`
is now a 101-line public entry provider retaining authority checks, facility
acquisition, activity replacement, `Jobs.Start`, and `Jobs.StartForFacility`.
The targeting provider is 165 lines and returns the same context fields to
`H.InstallActivity`; reservation release and error reasons remain unchanged.

### Facility service manual-start orchestration boundary

`PNC_FacilityJobs_Service_ManualStart.lua` now owns the manual activity
command orchestration for food, hydration, sleep, world water, and water
refill. `PNC_FacilityJobs_Service_ManualTargets.lua` retains personal-supply
checks, live-position assignments, home and camp acquisition, and route-level
resource resolution. The existing `H.ManualStart` internal seam and all four
callers remain unchanged; the service composition root loads the orchestration
provider before the manual toggle consumer.

### Facility service manual water boundary

World hydration and container-refill route acquisition moved to
`PNC_FacilityJobs_Service_ManualWater.lua`. It retains the legacy
`H.ManualNearbyWaterActivity` alias while keeping route selection, hydration
plan validation, and refill assignment in one server-owned provider. ManualStart
continues to call the same internal functions through the same `H` table.

### Facility service manual sleep boundary

Home and camp sleep acquisition moved to
`PNC_FacilityJobs_Service_ManualSleep.lua`. The provider owns the camped-NPC
branch, bounded nearby sleep acquisition, home fallback, and sleep policy
metadata. ManualTargets now retains personal-supply checks and local-position
assignments, with the composition root loading water, sleep, and manual-start
providers in dependency order.

### Facility resources seating boundary

Seating geometry, live-object rehydration, and the seat detector moved to
`PNC_FacilityResources_Seating.lua`. The original resource entry retains world
scanning, bed and sofa detectors, capacity and selection behavior, and exposes
the small `Resources.Internal` seam used by the seating provider for descriptor
keys and object iteration. The seat provider loads after bed and sofa
registration, preserving detector order and the public
`Resources.BuildSeatSpots`, `Resources.ResolveLiveObject`, and resource tables.
The root resource entry is now 95 lines; the scan provider is 217 lines,
the capacity and selection provider is 341 lines, the seating provider is
340 lines, the activity provider is 111 lines, the snapshot provider is 58
lines, and the detector provider is 68 lines.

### Facility resources scan boundary

World scanning and facility cache lifecycle now load through
`PNC_FacilityResources_Scan.lua`. The provider owns detector ordering,
descriptor key normalization, `ScanRegion`, `Refresh`, `Invalidate`,
`GetScan`, and `GetResources`. Detector registration remains on the root
resource table; the scan provider loads before seating so both providers use
the same internal descriptor and object-iteration seam.

### Facility resources capacity and selection boundary

Capacity normalization, detected capacity, sleep capacity, reservation-aware
slot checks, sleep-target validation, physical selection, and virtual-resource
fallbacks now load through
`PNC_FacilityResources_CapacitySelection.lua`. The provider preserves the
public `Resources.GetBinding`, `Resources.GetCapacity`, `Resources.Select`,
and related methods. Snapshot activity rehydration uses two internal virtual
resource helpers; the scan, capacity, and seating providers load in that
dependency order.

### Facility resources activity boundary

Activity resource-key resolution and authoritative live-body materialization
now load through `PNC_FacilityResources_Activity.lua`. The provider keeps the
saved facility activity descriptor separate from live world objects while
preserving `Resources.ResolveActivityTarget` and
`Resources.ApplyMaterializationTarget`. The resource root remains the public
composition entry and loads the activity provider after scan, capacity, and
seating dependencies.

### Facility resources snapshot and detector boundary

Read-only facility component snapshots now load through
`PNC_FacilityResources_Snapshot.lua`, while bed and sofa detector
registration now load through `PNC_FacilityResources_Detectors.lua`. The
95-line root retains `Resources.CopyDescriptor`, `Register`, `GetDetector`,
the shared object-iteration seam, and ordered provider loading. Existing
detector IDs, snapshot profiles, read-only component fields, and public
`PNC.FacilityResources` methods remain unchanged.

### Command hub child branch boundary

The command hub child controller now keeps lifecycle policy in
`PNC_CommandHub_ChildController.lua` and loads the ten concrete window
adapters from `PNC_CommandHub_ChildController_Branches.lua`. The root retains
the public `PNC.CommandHub.ChildController` methods, close ordering, active
branch state, opacity propagation, and position synchronization. The branch
provider owns each child window's open, close, focus, visibility, and sync
contract. A small `Controller.Internal` table carries only those UI helpers
across the provider boundary. The root is now 334 lines; the branch provider
is 286 lines.

### Command hub registry category boundary

Command category ordering, category definitions, zone actions, and stockpile
bootstrap presentation now load through
`PNC_CommandHub_Registry_Categories.lua`. The registry root retains client
gate calculations, tracing, and the public
`PNC.CommandHub.Registry` and `PNC.CommandHub.Gates` namespaces. A small
`RegistryInternal` seam supplies the category provider's resolved actions and
gate functions. The root is now 477 lines; the category provider is 245
lines.

### Command hub gate policy boundary

Eligibility snapshots, stockpile material checks, colony/base/stockpile gates,
disabled-tooltip policy, and radio detection now load through
`PNC_CommandHub_Registry_Gates.lua`. The registry root retains composition,
tracing, and the public `PNC.CommandHub.Gates` namespace. Public gate methods
and return shapes are unchanged. The gate provider is 215 lines; the category
provider remains 245 lines.

### Command hub action adapter boundary

Optional child, work, zone, journal, colonist, storage, research, base, and
scavenge routing now load through
`PNC_CommandHub_Registry_Actions.lua`, together with the stockpile bootstrap
callbacks. The root retains composition and the public registry tables; the
provider writes the existing `RegistryInternal` callbacks consumed by category
registration. The root is now 26 lines; the action provider is 266 lines.

### Zone window state service boundary

Colony snapshot reads, revision tracking, action-result translation, request
timing, and deferred selector startup now load through
`PNC_CommandHub_ZoneWindow_Service.lua`. The zone window retains rendering,
input, public `ZoneUI.Open`/`Close`/`CloseAll`/`SyncPositions` methods, and
window lifecycle behavior. The root is now 401 lines; the service provider is
123 lines.

### Command hub settings action boundary

Settings reset, theme cycling, action-panel branch changes, apply handling,
and cross-window opacity propagation now load through
`PNC_CommandHub_SettingsWindow_Actions.lua`. The settings window retains field
creation, population, rendering, and the public `SettingsUI` lifecycle. A
small `SettingsInternal` seam carries only the settings dependencies and
presentation helpers. The root is now 488 lines; the action provider is 138
lines.

### Facility build catalog boundary

Facility option normalization, cost availability, recipe metadata, technology
prerequisites, stockpile state, and production skill selection now load through
`PNC_SettlementManagement_FacilityBuildCatalog.lua`. The modal retains card
rendering, window layout, input handling, snapshot refresh, and the public
`PNC.FacilityBuildUI.BuildOptions` entry point. The modal root is now 484 lines;
the catalog provider is 336 lines.

### Facility build card boundary

The reusable facility card, native multi-tile preview compositor, text fitting,
and card rendering now load through
`PNC_SettlementManagement_FacilityBuildCard.lua`. The modal keeps window
interaction and consumes the existing `BuildUI.FacilityCard` and
`BuildUI.DrawNativePreview` exports. The card provider is 306 lines.

### Facility build interaction boundary

Build confirmation, debug-material requests, build-error presentation, snapshot
refresh, and the public `BuildUI.Open`/`Reopen` lifecycle now load through
`PNC_SettlementManagement_FacilityBuildInteraction.lua`. The modal retains
class setup, responsive layout, card composition, category selection, and the
public `PNC.FacilityBuildUI` table. The modal root is now 365 lines; the
interaction provider is 150 lines.

### Facility build presentation boundary

Child-control construction, responsive layout, category navigation, selection
state, and description rendering now load through
`PNC_SettlementManagement_FacilityBuildPresentation.lua`. The modal root keeps
only namespace setup, class lifecycle, and composition requires. The modal root
is now 97 lines; the presentation provider is 302 lines.

### Base building recipe state boundary

Facility recipe filtering, native recipe identity and favorite state, local
catalog reconstruction, stockpile pricing, and public recipe catalog wrappers
now load through `PNC_BaseBuildingCatalog_Recipes.lua`. The Buildings tab keeps
its list controls, preview, layout, row presentation, placement, queue, and
favorite actions while consuming the provider through a small `RecipeState`
seam. The catalog root is now 896 lines; the recipe provider is 156 lines.

### Conversation group fanout boundary

`PNC_ConversationGroup.lua` retains group state, participant selection,
addressed filtering, public group-session access, and audit helpers while
loading `PNC_ConversationGroup_Fanout.lua`. The 136-line provider owns
per-member delivery, shared-session routing, response queues, and fallback
handling. The original `Group:Fanout` contract, participant ordering,
primary-session behavior, gift and camp routes, addressed delivery, and audit
payloads remain unchanged.

### Conversation lifecycle creation boundary

`PNC_ConversationLifecycle.lua` retains lifecycle state, transition
orchestration, ceasefire requests, heartbeat, cleanup, farewell, and transport
helpers while loading the 160-line
`PNC_ConversationLifecycle_Create.lua` provider. Creation, nameplate
fallback and grace handling, safety admission, initial context, and session
startup remain behind the original `Lifecycle.Create` contract. The internal
`IsNameplateConversation` handoff was made explicit during validation.

### Conversation recruitment result boundary

`PNC_ConversationComposer_Recruitment.lua` is now a client composition root.
The 154-line `PNC_ConversationComposer_Recruitment_Receive.lua` provider
owns recruitment result validation, relationship refresh, rejection diary and
reply handling, menu reopening, accepted recruitment presentation, and session
close behavior. Request matching, dialogue payloads, diary entries,
relationship deltas, and close state remain unchanged.

### Conversation recruitment authority boundary

`PNC_ConversationAuthority_Recruit.lua` is now a guarded server composition
root. The 168-line
`PNC_ConversationAuthority_Recruit_Handle.lua` provider owns recruitment
request validation, lease and replay checks, context admission, recruitment
service execution, relationship effects, history commits, and result
transport. The original `Authority.HandleRecruit` contract, rejection
payloads, replay state, history policy, relationship updates, close state,
facade load order, and server-only guard remain unchanged.

### Conversation outcome result boundary

`PNC_ConversationComposer_Outcomes.lua` retains block-result handling and
shared composer setup while loading the 154-line
`PNC_ConversationComposer_Outcomes_Receive.lua` provider. Authoritative
outcome validation, relationship and diary updates, effect routing, response
queueing, territory setup, gift-window transitions, and next-node state remain
behind the original `Composer.ReceiveOutcome` contract. Request matching,
failure routes, payload construction, relationship deltas, effect handling,
session close behavior, and menu or block progression remain unchanged.

### Companion player-emote result boundary

`PNC_CompanionCommandPresentation.lua` retains shared command flavor,
speech, acknowledgement, and command presentation helpers while loading the
257-line `PNC_CompanionCommandPresentation_PlayerEmoteResult.lua` provider.
Deduplicated player-emote results, per-NPC relationship updates, diary
entries, reply flavor, legacy delta compatibility, and relationship-debug
synchronization remain behind the original
`Presentation.HandlePlayerEmoteInteractionResult` contract. The public
presenter namespace, result cache limit, router handoff, and relationship
payloads remain unchanged.

### Companion social-greeting boundary

`PNC_CompanionCommandPresentation.lua` now loads the 180-line
`PNC_CompanionCommandPresentation_SocialGreeting.lua` provider for
deduplicated greeting results, corpse-reaction gossip rendering, ambient
social-flavor queueing, NPC fallback speech, and diary recording. The
original `Presentation.HandleSocialGreeting` contract, event cache limit,
corpse and companion-dog routes, social-flavor payloads, public presenter
namespace, and router handoff remain unchanged.

### Social greeting transaction boundary

`PNC_SocialGreetingService.lua` retains proximity scanning, per-player
presence edges, pump cadence, abandonment ordering, and greeting budgets while
loading the 194-line
`PNC_SocialGreetingService_TryGreet.lua` provider. Meeting validation,
relationship eligibility, canonical relationship mutation, animation requests,
relationship transport, and social-greeting payload delivery remain behind
the original `Service.TryGreet` contract. Event identity, daily-greeting
guards, relationship deltas, network payloads, and authority behavior remain
unchanged.

## Boundary decisions

- Composition roots remain unchanged.
- Network commands, payloads, response shapes, and authority direction remain
  unchanged.
- Persistence schema, save ordering, and ModData ownership remain unchanged.
- Semantic IR, parser, policy, task, MarketSense, group dialogue, and LLM
  fallback contracts remain unchanged.
- Declarative built-in data loads only after the owning entry APIs exist.
- Puppet Opera normalization and timeline lowering remain one cohesive provider;
  the registry entry retains the public normalize/register and runtime lookup
  contracts.
- Puppet Opera authority guards load before admission and runtime providers;
  existing `Authority.Internal` names preserve the server authority seam.
- New spokes return safely when their parent registry is unavailable.
- Runtime diagnostics providers load after their state and timing primitives,
  while the original entry remains the only public load path.
- The audit logging provider loads before the inventory audit extension and
  preserves every existing diagnostics method on the public table.
- Facility behavior providers load after shared state and scene primitives;
  arrival preparation runs before scene admission and the reduced tick keeps
  the original `Internal.Tick` entry point.
- Facility service activity and order providers load before the StartState
  composition provider; its public `H.InstallActivity` handoff remains
  unchanged.
- Manual activity orchestration loads after its assignment helpers and before
  the toggle consumer; `H.ManualStart` remains the only internal entry point.
- Manual water and sleep providers load before manual-start orchestration and
  preserve the existing internal helper names and nearby-water compatibility
  alias.
- Facility resource seating loads after bed and sofa registration; its
  descriptor and object iteration dependencies cross only the internal seam.
- Facility resource scanning loads before seating and keeps the public
  resource cache methods on the original table.
- Facility resource capacity and selection load after scanning and before
  seating; virtual-resource helpers cross only the internal seam.
- Facility resource activity resolution loads after scan, capacity, and
  seating; saved resource keys and live materialization remain on the original
  `Resources` namespace.
- Command hub lifecycle loads before its branch adapters; the original child
  controller require path remains the only public entry point.
- Command hub action adapters load after gate policy and before category
  registration; existing `RegistryInternal` callback ownership is preserved.
- Zone window state service loads after the window class and before `ZoneUI`
  operations; the public zone table and window callback names are preserved.
- Command hub settings actions load after the settings class and layout; the
  public `SettingsUI` lifecycle and callback method names are preserved.
- Facility build catalog loads before the modal window consumes
  `BuildUI.BuildOptions`; the public build UI table and option shapes are
  preserved.
- Facility build card loads before the modal creates cards; shared card and
  preview exports remain available to the integrated Buildings tab.
- Facility build interaction loads after the modal class and before the public
  build UI entry point; build callbacks and snapshot contracts are preserved.
- Facility build presentation loads before interaction and uses the card helper
  seam; public window method names and selection state remain unchanged.
- Base building recipe state loads before the Buildings tab catalog; public
  `Building.CatalogRecipes`, `FilterFacilityRecipes`, favorite, and placement
  contracts remain unchanged.
- Command hub gate policy loads before category definitions; category
  definitions consume the registry's public gate table through the existing
  small internal seam.
- The server-only inventory guard was reviewed from 765 to 766 files after
  adding the capacity and selection provider.

### Detailed snapshot boundary

`PNC_NetworkSnapshots_DetailedPayloads.lua` remains the dependency handoff
and ordered composition root while loading
`PNC_NetworkSnapshots_DetailedPayloads_Build.lua`. The provider owns the
unchanged 220-line `Network.BuildSnapshot` assembly and its needs summary
helper. Public payload keys, copy behavior, optional-module guards, method
signature, and load order remain unchanged.

The focused detailed snapshot, presence, authority, activity, and profiler
matrix passed 7/7. The architecture audit still reports the snapshot assembly
as a networking finding because this chunk establishes ownership and a stable
handoff without changing the serialization contract.

### Movement halt contract boundary

`PNC_Behavior_Common.lua` retains shared combat, owner, and movement-intent
helpers while loading `PNC_Behavior_Common_MovementHalt.lua`. The provider owns
the unchanged 50-line `Common.HaltMovement` contract: move-intent holds,
engine-path invalidation, live path reset, and abstract fallback reset. The
public entry point and all existing callers remain unchanged; `MoveRecord`
stays in the root because its broader navigation and presentation
responsibilities need a separate boundary.

Movement, combat, seating, follow, lumber, threat, camp, corpse-haul, and
ranged checks passed 10/11. `pnc_seated_threat_smoke` retains its established
`SetCombatDebug` baseline failure. The full suite remains at 34 failures out
of 783 with no new failures; the inventory presence boundary is the one
resolved baseline failure. Whole-tree Lua parsing passed for 2,412 files;
changed-file Kahlua validation and `git diff --check` passed.

### Stationary movement hold boundary

`PNC_Behavior_Common.lua` retains `MoveRecord` orchestration while loading
`PNC_Behavior_Common_StationaryMovementHold.lua`. The provider owns the
stationary presentation guard for seat and sleep ownership: presentation
resolution, seated diagnostics, presentation movement release, and the
existing movement halt handoff. The `MoveRecord` entry point, return values,
caller surface, fallback seat detection, and load order remain unchanged.

The focused movement and presentation matrix passed 12/12. The full suite
remains at 34 failures out of 783 with no failure-name delta against the
movement-halt baseline. Whole-tree Lua parsing passed for 2,412 files; both
changed Lua files passed Kahlua validation and `git diff --check` passed. The
new provider is not server-only and introduces no network, persistence, or
optional-integration changes.

### Movement request dispatch boundary

`PNC_Behavior_Common.lua` now retains movement preparation and loads
`PNC_Behavior_Common_MovementDispatch.lua`. The provider owns the live
`MoveIntent.RequestMove` preference, the `PathService.MoveToward` fallback,
and the `PathService.AdvanceAbstract` path for abstract records. The
`MoveRecord` signature, return values, live and abstract behavior, caller
surface, and load order remain unchanged.

The focused movement, navigation, and abstract-path matrix passed 18/18. The
full suite remains at 34 failures out of 783 with no failure-name delta
against the movement-routing baseline. Whole-tree Lua parsing passed for
2,412 files; all four movement files passed Kahlua validation and
`git diff --check` passed. The architecture audit reports 2,544 production
files, 355,200 scored production LOC, and 256 findings.

### Companion FollowOwner combat and vehicle handoff boundaries

`PNC_BehaviorCompanion.lua` remains the ordered composition root. It now loads
`PNC_BehaviorCompanion_FollowOwner_CombatHandoff.lua` and
`PNC_BehaviorCompanion_FollowOwner_VehicleHandoff.lua` before the existing
`PNC_BehaviorCompanion_FollowOwner.lua` coordinator. The combat provider owns
live follow-owner retreat, owner-priority combat, urgent threat, horde
retreat, and owner-leash threat handoff. The vehicle provider owns boarding,
passenger maintenance, disembark handling, and the full-vehicle wait path.

`BehaviorCompanion.Tick`, `Internal.TickFollowOwner`, the existing internal
handoff names, return values, load order, owner authority, and optional vehicle
integration remain unchanged. The focused companion matrix passed 16/16. The
established `pnc_follow_horde_steering_smoke` stationary-owner failure remains
unchanged; the full suite remains 34 failures out of 783 with no failure-name
delta. Whole-tree Lua parsing passed for 2,417 files; the four changed
companion files passed Kahlua validation and `luac`, and `git diff --check`
passed. The current architecture audit reports 2,546 production files,
355,274 scored production LOC, 257 findings, and a Behaviors subsystem of 36
files and 6,302 LOC. `Internal.TickFollowOwner` is 249 lines.

### Companion abstract and live movement handoff boundaries

`PNC_BehaviorCompanion_AbstractFollowOwner.lua` now owns the bodyless
follow-owner branch: durable owner identity recovery, unresolved-owner retry,
abstract catch-up speed, bounded long-range convergence, anchor fallback, and
follower-presence diagnostics. The original `FollowOwner.lua` path keeps a
guarded compatibility require so direct consumers still receive
`Internal.TickAbstractFollowOwner`.

`PNC_BehaviorCompanion_FollowOwner_MovementHandoff.lua` owns live stationary
owner holding, formation-slot sampling, personal-space correction, horde
steering, stealth move-mode selection, move-intent gating, combat-target clear,
and the final `MoveRecord` request. The existing `Internal.TickFollowOwner`
entry point and return behavior remain unchanged; it now sequences owner state,
vehicle, hazard, combat, and movement handoffs.

Abstract, formation, navigation, and traversal checks passed 5/5 after
excluding the established `pnc_follow_horde_steering_smoke` stationary-owner
failure. The full suite remains 34 failures out of 783 with no failure-name
delta. Whole-tree Lua parsing passed for 2,419 files; changed companion files
passed Kahlua validation and `luac`, and `git diff --check` passed. The audit
reports 2,548 production files, 355,329 scored production LOC, 258 findings,
and a Behaviors subsystem of 38 files and 6,357 LOC. `Internal.TickFollowOwner`
is now 144 lines.

### Companion FollowOwner owner-state handoff boundary

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
validation and `luac`, and `git diff --check` passed. The audit reports 2,549
production files, 355,355 scored production LOC, 257 findings, and a Behaviors
subsystem of 39 files and 6,383 LOC. `Internal.TickFollowOwner` is now 133
physical lines and no longer appears as a large-function finding.

### Companion horde-steering boundary

`PNC_BehaviorCompanion_FollowHazardSteering.lua` now owns the short-lived
`ResolveHordeAwareFollowTarget` calculation and traversal-safe candidate
selection. `PNC_BehaviorCompanion_FollowHazards.lua` retains shared zombie
sensing, bounded per-owner candidate caching, hazard aggregation, and horde
observation. The original internal function contract, direct
`FollowHazards.lua` load path, movement consumer, and profiler marker remain
unchanged.

The affected hazard, steering, formation, navigation, traversal, abstract, and
profiler checks passed 7/7 after excluding the established
`pnc_follow_horde_steering_smoke` stationary-owner failure. The full suite
remains 34 failures out of 783 with no failure-name delta. Whole-tree Lua
parsing passed for 2,421 files; changed hazard files passed Kahlua validation
and `luac`, and `git diff --check` passed. The audit reports 2,550 production
files, 355,380 scored production LOC, 257 findings, and a Behaviors subsystem
of 40 files and 6,408 LOC. The steering provider is 166 physical lines;
abstract follow remains a cohesive deferred provider.

### Companion abstract owner-resolution and movement boundaries

`PNC_BehaviorCompanion_AbstractFollowOwner_Resolution.lua` now owns durable
owner recovery, unresolved-owner retry budgeting, presence wake-up, and the
unresolved diagnostic. `PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff.lua`
owns abstract catch-up speed, long-range bounded convergence, `MoveRecord`,
facility-held movement reporting, and abstract follow telemetry. The original
`Internal.TickAbstractFollowOwner` entry point, state modes, owner identity
fields, diagnostic event names, and direct `FollowOwner.lua` compatibility path
remain unchanged.

The affected abstract, hazard, formation, navigation, traversal, and profiler
checks passed 7/7 after excluding the established
`pnc_follow_horde_steering_smoke` stationary-owner failure. The full suite
remains 34 failures out of 783 with no failure-name delta. Whole-tree Lua
parsing passed for 2,423 files; changed abstract files passed Kahlua validation
and `luac`, and `git diff --check` passed. The audit reports 2,552 production
files, 355,490 scored production LOC, 257 findings, and a Behaviors subsystem
of 42 files and 6,518 LOC. The abstract coordinator is now 124 physical lines.

### Self-treatment tick boundary

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
and `luac`, and `git diff --check` passed. The audit reports 2,553 production
files, 355,529 scored production LOC, 257 findings, and a Behaviors subsystem
of 43 files and 6,557 LOC. Live multiplayer and save/reload runtime gates
remain required.

### BehaviorSystem tick composition boundary

`PNC_BehaviorSystem.lua` now retains shared helper definitions and publishes an
explicit `Behavior.Internal.Tick` dependency bundle. The ordered
`PNC_BehaviorSystem_Tick.lua` provider owns the public `Behavior.Tick` loop,
preserving the existing treatment, committed combat, threat safety, animation,
task, companion, and recovery order while reducing the composition file to
helper definitions plus provider wiring. Public namespaces and direct loading
remain compatible.

The focused BehaviorSystem matrix passed 4/4. Whole-tree Lua parsing passed
2,425 files; both BehaviorSystem files passed Kahlua validation and `luac`, and
`git diff --check` passed. The full suite remains at the established 34 failures
out of 783 with no new failure-name delta. The audit now reports 2,554
production files, 355,579 scored production LOC, and 257 findings.

### Common movement-record coordinator boundary

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
passed Kahlua validation and `luac`, and `git diff --check` passed. The full
suite remains at the established 34 failures out of 783 with no new
failure-name delta. The audit now reports 2,555 production files, 355,598
scored production LOC, and 257 findings; Behaviors is 45 files and 6,626 LOC.

### Abstract follow movement advance provider boundary

`PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff.lua` now remains a
13-line composition boundary. The 143-line `H.Advance` implementation lives in
`PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff_Advance.lua` with
the existing Core, Const, Common, and diagnostics dependencies. The direct
`AbstractFollowOwner` path now guards the provider load so compatibility loads
retain the same movement behavior as the ordered companion root.

The abstract movement matrix passed 6/6. All four changed companion files pass
Kahlua validation; whole-tree Lua parsing passed 2,427 files; `luac` and
`git diff --check` passed. The full suite remains at the established 34
failures out of 783 with no new failure-name delta. The audit now reports 2,556
production files, 355,612 scored production LOC, and 257 findings.

### ThreatGuard tick provider boundary

`PNC_BehaviorThreatGuard_Lifecycle.lua` now owns the compact lifecycle helpers,
`IsActive`, and the dependency bundle. The 122-line public `ThreatGuard.Tick`
implementation lives in `PNC_BehaviorThreatGuard_Tick.lua`; it receives the
existing Core, Common, timing, and lifecycle helper dependencies and preserves
the existing transition-provider calls and threat-state ownership.

The focused ThreatGuard matrix passed 2/4 checks; the two remaining failures
are the established `SetCombatDebug` baseline path. Whole-tree Lua parsing
passed 2,428 files; both ThreatGuard files passed Kahlua validation and `luac`,
and `git diff --check` passed. The full suite remains at the established 34
failures out of 783 with no new failure-name delta. The audit now reports 2,557
production files, 355,637 scored production LOC, and 257 findings.

### World-target refresh provider boundary

`PNC_Behavior_Targeting.lua` now retains live-facing and target-resolution APIs,
the shared `sameTarget` helper, and an explicit dependency bundle. The
169-line `Targeting.UpdateTargetFromWorld` implementation lives in
`PNC_Behavior_Targeting_UpdateTargetFromWorld.lua`, preserving visibility
memory, player/NPC/zombie resolution, compatibility-target resolution, and
target-threat checks.

The target refresh matrix passed 4/4. Both targeting files passed Kahlua
validation and `luac`; whole-tree Lua parsing passed 2,429 files; and
`git diff --check` passed. The full suite remains at the established 34
failures out of 783 with no new failure-name delta. The audit now reports 2,558
production files, 355,664 scored production LOC, and 257 findings.

### Semantic context-question catalog boundary

`PNC_SemanticCatalog_QuestionPatterns.lua` retains catalog bootstrap and the
location/seen question registrations while loading
`PNC_SemanticCatalog_QuestionPatterns_ContextQuestions.lua`. The provider
owns the unchanged 344-line `Internal.RegisterWorldFactQuestions` registration
block for time, date, weather, identity, activity, wellbeing, and gift
preference questions. The existing internal function contract,
`registerPattern` dependency, catalog registration order, and semantic
pattern definitions remain unchanged.

Semantic fact, topic, and dialogue checks passed 3/3. The local response,
local route, and NLU wellbeing checks retain their established baseline
failures. The full suite remained at 35 failures out of 783 with no failure
name delta. Whole-tree Lua parsing passed for 2,410 files; changed-file
Kahlua validation and `git diff --check` passed.

### Inventory transfer authority boundary

`PNC_ServerInventory_Transfer.lua` retains inventory helper ownership,
medical bandage transfer, idempotency cache ownership, and ordered handoff
while loading `PNC_ServerInventory_Transfer_Handle.lua`. The provider owns the
unchanged 172-line `Service.Transfer` server transaction: gift replay handling,
authority and revision validation, medical-supply admission, direction
dispatch, gift effects, medical completion, notification, and audit projection.
The public `Service.Transfer` contract and existing client/server command route
remain unchanged.

Inventory transaction, rollback, gift-idempotency, semantic give-item, server
audit, and MP loader checks passed 6/6. The inventory presence boundary smoke
now passes; its previous function-count failure is the one resolved baseline
failure. The full suite is 34 failures out of 783 with no new failure names.

### Relationship mutation transaction boundary

`PNC_RelationshipService_EventMutation.lua` remains the ordered composition
root for the relationship mutation adapter while loading
`PNC_RelationshipService_EventMutation_Apply.lua`. The provider owns the
174-line `Relationships.ApplyEventMutation` atomic persistent mutation:
authority and target validation, duplicate, cooldown, and saturation guards,
memory pruning, relationship recalculation, bounded event state, commit, and
optional journal projection. `ApplyConversationEffect` remains in the root as
the conversation adapter. Public `Relationships` and `Personal.Commands`
aliases, load order, and return shapes remain unchanged.

Relationship-service presence, foundation, and faction-toll checks passed 3/3.
The social-event smoke retains its established definition-count baseline
failure (`21` expected, `24` actual). The MP server-file guard now accounts for
the guarded provider. The full suite remains at 35 failures out of 783 with no
new or resolved failure names. Whole-tree Lua parsing passed for 2,409 files;
changed-file Kahlua validation and `git diff --check` passed.

### Semantic social authority boundary

`PNC_ServerSemanticSocialInteractionCommandHandler.lua` retains server-only
initialization, semantic event definitions, relationship summary helpers, and
ordered command registration while loading
`PNC_ServerSemanticSocialInteractionCommandHandler_Handle.lua`. The provider
owns the unchanged 162-line `Authority.Handle` transaction, including
authority and player validation, conversation lease validation, NPC and target
identity checks, semantic event emission, relationship delivery, and result
shaping. Namespace ownership, command routing, and the pure-client early
return remain unchanged.

Server-router and MP guard checks passed 2/2. Adjacent semantic chat, group,
and world-target authority checks passed 3/3. The direct semantic social smoke
retains its established profanity-pattern baseline failure.

### LLM social reaction authority boundary

`PNC_ServerLLMSocialReactionCommandHandler.lua` retains policy loading,
request reservation and release callbacks, shared authority helpers, and
ordered command registration while loading
`PNC_ServerLLMSocialReactionCommandHandler_Handle.lua`. The provider owns the
unchanged 237-line `Authority.HandleLLMSocialReaction` transaction, including
request validation, lease ownership, idempotency, target identity, policy
evaluation, relationship mutation, result construction, relationship
transport, and optional integration degradation. The public authority method,
command routes, and server-only early return remain unchanged.

The PBrainZ social reaction, policy, tool catalog, result diary, nameplate,
server router, and MP server-file guard matrix passed 7/7. Both changed files
pass syntax and Kahlua checks.

### Client inventory-delta boundary

`PNC_ClientInventoryCommands.lua` retains client command registration,
character-payload application, result delivery, and helper ownership while
loading `PNC_ClientInventoryCommands_Delta.lua`. The provider owns the
unchanged 157-line `Internal.ApplyInventoryDelta` transaction, including
revision guards, all supported item operations, resync requests, equipment
cache rebuilding, diagnostics, and inventory-window invalidation. The public
command route and internal state contracts remain unchanged.

The isolated inventory recovery, state roundtrip, and network scale matrix
passed 3/3. The client-command smoke reproduces its established legacy
pursuit failure. Both changed files pass syntax and Kahlua checks.

### Presence payload boundary

`PNC_NetworkSnapshots_PresencePayload.lua` remains the ordered composition
root and now loads `PNC_NetworkSnapshots_PresencePayload_Build.lua`. The new
provider owns the unchanged `Network.BuildPresenceDelta` assembly body and
receives its former local dependencies through
`Network.Internal.PresencePayload`. Public namespace ownership, payload shape,
serialization order, optional profiler behavior, and load order remain
unchanged.

The focused presence-delta, network-scale, and profiler marker matrix passed
5/5. The architecture audit still records the provider's 158-line assembly
function as a networking finding; this chunk establishes ownership and a
stable handoff for later bounded work.

## Validation

| Check | Result |
|---|---|
| Response catalog smoke | Passed |
| Inventory dialogue smoke | Passed |
| Puppet Opera focused suite | 18/18 passed |
| Companion command matrix | 9/9 passed |
| Client companion authority smoke | Passed |
| Group-camp coordinator smoke | Passed |
| Colony-management section smoke | Passed |
| Performance diagnostics smoke | 1/1 passed |
| Follower presence diagnostics smoke | 1/1 passed |
| Inventory server audit smoke | 1/1 passed |
| Audit-channel focused matrix | 11/12 passed; one known baseline zombie-aggro harness failure |
| Facility behavior and service focused matrix | 10/10 passed |
| Facility seating/resource focused matrix | 6/6 passed; two existing baseline failures remain isolated |
| Facility resource provider matrix | 7/7 passed; resource smoke retains its established sofa-detector baseline failure |
| Facility resources activity and load-order gates | 3/4 passed; the resource smoke retains its established sofa-detector baseline failure, while roaming-floor-seat, semantic-camp-site, and MP server-file guard passed |
| Facility resources snapshot/detector matrix | 3/4 passed; the resource smoke retains its established sofa-detector baseline failure, while snapshot consumers, semantic camp-site, and MP server-file guard passed |
| Facility Jobs start-state matrix | 10/10 focused activity and service gates passed; full suite remained 35 failures out of 783 |
| Facility Jobs start-targeting matrix | 10/10 focused activity and service gates passed; full suite remained 35 failures out of 783 |
| Command hub UI matrix | 16/16 passed |
| Facility build/catalog matrix | 23/23 passed |
| Facility build/card matrix | 22/22 passed |
| Facility build interaction matrix | 22/22 passed |
| Facility build presentation matrix | 24/24 passed |
| Base building recipe state slice | Focused matrix 12/12 passed; full suite remained 35 failures out of 783 |
| Puppet Opera normalization matrix | 18/18 passed |
| Puppet Opera authority guard matrix | 18/18 passed |
| Puppet Opera authority lifecycle matrix | 19/19 passed; full suite remained 35 failures out of 783 |
| Puppet Opera runtime timeline matrix | 19/19 passed; full suite remained 35 failures out of 783 |
| Puppet Opera runtime phase matrix | 19/19 passed; full suite remained 35 failures out of 783 |
| Puppet Opera runtime safety matrix | 19/19 passed; full suite remained 35 failures out of 783 |
| Puppet Opera runtime dispatch matrix | 19/19 passed; full suite remained 35 failures out of 783 |
| Puppet Opera authority admission matrix | 19/19 passed; full suite remained 35 failures out of 783 |
| Puppet Opera authority request matrix | 4/4 passed; full suite remained 35 failures out of 783 |
| Puppet Opera authority context matrix | 4/4 passed; full suite remained 35 failures out of 783 |
| Puppet Opera authority bootstrap matrix | 4/4 passed; full suite remained 35 failures out of 783 |
| Puppet Opera NPC ownership matrix | 6/6 focused tests passed; full suite remained 35 failures out of 783 |
| Lumber service execution matrix | 4/4 focused tests passed; full suite remained 35 failures out of 783 |
| Lumber WorkAdapter boundary matrix | 4/4 focused tests passed; full suite remained 35 failures out of 783 |
| World-effect, Lumber, and corpse-haul matrix | 10/10 focused tests passed; full suite remained 35 failures out of 783 |
| WorkService queue and claim matrix | 14/14 focused tests passed; full suite remained 35 failures out of 783 |
| WorkService scheduler boundary matrix | 9/9 focused tests passed; full suite remained 35 failures out of 783 |
| WorkService progress and completion matrix | 12/12 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| WorkTaskProvider execution matrix | 12/12 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| TaskRequest command and snapshot matrix | 8/8 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Tasking recovery matrix | 8/8 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Tasking pump orchestration matrix | 9/9 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Task lease lifecycle matrix | 13/13 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| WorkService operation registry matrix | 12/12 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| WorkService target/provider matrix | 13/13 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| WorkService worker reconciliation matrix | 13/13 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Social damage adapter matrix | 5/5 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Social combat adapter matrix | 6/6 focused tests passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Social event service boundary matrix | 2/2 presence and MP loader checks passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Social teammate damage delivery matrix | 3/3 focused combat, faction attack, and MP loader checks passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Conversation ambient receive matrix | Affected conversation smokes reproduce their established harness failures; full suite remained 35 failures out of 783 with no new or resolved failures |
| Conversation gift-result matrix | 6/7 focused gift checks passed; the remaining conversation smoke retains its established Memory harness failure; full suite remained 35 failures out of 783 with no new or resolved failures |
| Conversation sandbox-definition matrix | Debug initialization/menu checks passed 2/3; the remaining conversation smoke retains its established Memory harness failure; full suite remained 35 failures out of 783 with no new or resolved failures |
| Conversation root-menu matrix | Affected client-command and conversation smokes reproduce their established harness failures; full suite remained 35 failures out of 783 with no new or resolved failures |
| Conversation authority choice matrix | Authority presence and MP loader checks passed 2/3; the remaining behavior smoke retains its established Memory harness failure; full suite remained 35 failures out of 783 with no new or resolved failures |
| Conversation group fanout matrix | Semantic group smoke passed 1/1; full suite remained 35 failures out of 783 with no new or resolved failures |
| Conversation lifecycle creation matrix | Conversation safety smoke passed 1/1 after restoring the explicit nameplate helper handoff; full suite remained 35 failures out of 783 with no new or resolved failures |
| Conversation recruitment result matrix | Recruitment debug smokes passed 2/2; affected conversation smokes retain their established Memory harness failures; full suite remained 35 failures out of 783 |
| Conversation recruitment authority matrix | Authority presence, MP server-file guard, command-handler, and recruitment debug checks passed 5/5; full suite remained 35 failures out of 783 with no new or resolved failures |
| Conversation outcome result matrix | Base UI source-boundary smoke passed after including the provider; full suite remained 35 failures out of 783 with no new or resolved failures |
| Companion player-emote presentation matrix | Vanilla-emote presentation, interaction, nameplate feedback, and LLM diary checks passed 4/4; full suite remained 35 failures out of 783 with no new or resolved failures |
| Companion social-greeting matrix | Social-greeting, greeting-presentation, vanilla-emote, interaction, and nameplate checks passed; corpse-awareness retains its established baseline failure; full suite remained 35 failures out of 783 |
| Social greeting transaction matrix | Social greeting, presentation, MP loader, nameplate, and abandonment checks passed 5/5; full suite remained 35 failures out of 783 with no new or resolved failures |
| Corpse haul work adapter diagnostics/targeting matrix | 5/5 passed; full suite remained 35 failures out of 783 |
| Corpse haul work adapter cleanup matrix | 5/5 passed; full suite remained 35 failures out of 783 |
| Corpse haul work adapter transfer matrix | 5/5 passed; full suite remained 35 failures out of 783 |
| Corpse haul work adapter tick matrix | 5/5 passed; full suite remained 35 failures out of 783 |
| Corpse haul dispatch matrix | 5/5 passed; full suite remained 35 failures out of 783 |
| Corpse haul reconciliation candidate matrix | 5/5 passed; full suite remained 35 failures out of 783 |
| Corpse haul active reconciliation matrix | 5/5 passed; full suite remained 35 failures out of 783 |
| Movement halt contract matrix | Movement, combat, seating, follow, lumber, threat, camp, corpse-haul, and ranged checks 10/11; seated-threat retains its established `SetCombatDebug` failure; full suite remained 34 failures out of 783 with no new failures |
| Companion FollowOwner combat and vehicle handoff matrix | 16/16 focused companion checks passed; the established `pnc_follow_horde_steering_smoke` stationary-owner failure remains; full suite remained 34 failures out of 783 with no failure-name delta |
| Companion abstract and live movement handoff matrix | Abstract, formation, navigation, and traversal checks passed 5/5 after excluding the established stationary-owner horde failure; full suite remained 34 failures out of 783 with no failure-name delta |
| Companion FollowOwner owner-state handoff matrix | 6/6 affected companion checks passed after excluding the established stationary-owner horde failure; full suite remained 34 failures out of 783 with no failure-name delta |
| Companion horde-steering matrix | 7/7 affected hazard, steering, formation, navigation, traversal, abstract, and profiler checks passed after excluding the established stationary-owner horde failure; full suite remained 34 failures out of 783 with no failure-name delta |
| Companion abstract owner-resolution and movement matrix | 7/7 affected abstract, hazard, formation, navigation, traversal, and profiler checks passed after excluding the established stationary-owner horde failure; full suite remained 34 failures out of 783 with no failure-name delta |
| Self-treatment tick matrix | Self-treatment and combat-commitment checks passed 2/2; full suite remained 34 failures out of 783 with no failure-name delta |
| Stationary movement hold matrix | Movement and presentation checks passed 12/12; full suite remained 34 failures out of 783 with no failure-name delta |
| Movement request dispatch matrix | Movement, navigation, and abstract-path checks passed 18/18; full suite remained 34 failures out of 783 with no failure-name delta |
| Semantic context-question catalog matrix | Fact, topic, and dialogue checks 3/3; three wellbeing checks retain established baseline failures; full suite remained 35 failures out of 783 with no failure-name delta |
| Inventory transfer authority matrix | Transaction, rollback, gift-idempotency, semantic give-item, server-audit, and MP-loader checks 6/6; inventory presence boundary resolved its previous count failure; full suite remained 34 failures out of 783 with no new failure names |
| Relationship mutation transaction matrix | Presence, foundation, and faction-toll checks 3/3; social-event smoke retains its established definition-count baseline failure; full suite remained 35 failures out of 783 with no new or resolved failures |
| Semantic social authority matrix | Server-router and MP guard 2/2; adjacent semantic checks 3/3; direct social smoke retains its established profanity-pattern baseline failure; full suite remained 35 failures out of 783 with no new or resolved failures |
| LLM social reaction authority matrix | 7/7 passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Client inventory-delta matrix | 3/3 passed; client-command smoke retains its established legacy pursuit failure; full suite remained 35 failures out of 783 with no new or resolved failures |
| Detailed snapshot, presence, authority, activity, and profiler matrix | 7/7 passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Presence payload and profiler marker matrix | 5/5 passed; full suite remained 35 failures out of 783 with no new or resolved failures |
| Lua syntax with `luac` | Passed for changed Lua files |
| `pz_verify` Kahlua scan | Zero errors for changed Lua files |
| `git diff --check` | Passed |
| Semantic suite | Same 6 failures out of 66 on clean `HEAD` and refactored worktree |
| Full suite | Baseline 35 failures out of 783; current refactored worktree has 34, resolving `pnc_server_inventory_presence_boundary_smoke` with no new failure names |

The recorded baseline establishes that the remaining reported semantic and
full-suite failures predate these migrations; the inventory presence boundary
count failure is resolved by this slice. The failures include existing fuzzy
parsing, generated wellbeing variants, profanity-pattern expectations, UI and
runtime assumptions, missing optional dependencies, persistence setup, and
other unrelated harness cases.

| BehaviorSystem tick provider boundary | 4/4 focused checks passed; full suite remained 34 failures out of 783 with no new failure-name delta |
| Common movement-record coordinator boundary | 22/23 executed caller checks passed; the remaining check retained the established `SetCombatDebug` baseline; full suite remained 34 failures out of 783 |
| Abstract follow movement advance provider boundary | 6/6 focused checks passed; full suite remained 34 failures out of 783 |
| ThreatGuard tick provider boundary | 2/4 focused checks passed; two checks retained the established `SetCombatDebug` baseline; full suite remained 34 failures out of 783 |
| World-target refresh provider boundary | 4/4 focused checks passed; full suite remained 34 failures out of 783 |

### FollowOwner tick coordinator boundary

`PNC_BehaviorCompanion_FollowOwner.lua` retains direct-load compatibility and
provider wiring. The 109-line `Internal.TickFollowOwner` sequencing function
now lives in `PNC_BehaviorCompanion_FollowOwner_Tick.lua` with explicit Core,
Const, Stealth, BehaviorCommon, and CompanionVehicle dependencies. Owner-missing
recovery, state preparation, vehicle handoff, hazard assessment, combat handoff,
movement handoff, ordering, and the original internal entry point are preserved.

The focused FollowOwner matrix passed 7/8 checks; the one remaining
`pnc_follow_horde_steering_smoke` stationary-owner assertion is the established
baseline failure. Whole-tree Lua parsing passed 2,429 files; changed-file
`pz_verify`, `luac`, and `git diff --check` passed. Full suite remains 34/783
with no failure-name delta. Architecture audit reports 2,559 production files,
355,684 scored production LOC, and 257 findings; Behaviors is 49 files and
6,712 LOC with an 83.8 health score.

### Roaming area-mode provider boundary

`PNC_Behavior_Roaming.lua` retains shared roaming helpers, mode registration,
normalizers, job wiring, and the public `Roaming.Tick` contract. The complete
area roaming state machine now lives in
`PNC_Behavior_Roaming_AreaMode.lua` as `Roaming.Internal.AreaMode.Run`, with
explicit Core, Const, Common, BehaviorCombat, goal, pause, passage, and threat
dependencies. Area pause and threat handling, ambient and floor-seat callbacks,
goal selection, blocked-path recovery, movement requests, player-mode fallback,
and registration order are preserved.

The focused roaming matrix passed 7/7 checks. Whole-tree Lua parsing passed
2,431 files; changed-file `luac` and Kahlua checks passed. `pz_verify` reports
the remaining 4,922-token bloat warning on the 559-line roaming root.
`git diff --check` passed. Full suite remains 34/783 with no new roaming
failure. Architecture audit reports 2,560 production files, 355,716 scored
production LOC, and 257 findings; Behaviors is 50 files and 6,744 LOC with an
83.8 health score.

### Behavior tick sleep dependency repair

`PNC_BehaviorSystem_Tick.lua` now receives the root-owned
`tickPendingSleepWake` helper through `Behavior.Internal.Tick`, removing the
unresolved global lookup from the earlier provider extraction while preserving
sleep teardown ordering and the public `Behavior.Tick` entry point. The focused
sleep and recovery matrix passed 5/5 checks. Whole-tree Lua parsing passed
2,431 files; changed-file `luac` and Kahlua checks passed; `git diff --check`
passed. Full suite remains 34/783.

### Behavior tick dispatch provider boundary

`PNC_BehaviorSystem_Tick.lua` retains authority, safety-gate ordering,
presentation leases, treatment, and semantic action-plan ownership. Job
selection, reselection diagnostics, registry dispatch, companion and hostile
fallback, follower reconciliation, and idle presentation now live in
`PNC_BehaviorSystem_Tick_Dispatch.lua` as `Behavior.Internal.TickDispatch.Run`.
The original `Behavior.Tick` entry point, return behavior, ordering, and
dependency wiring are preserved.

The focused behavior matrix passed 10/10 checks. Whole-tree Lua parsing passed
2,432 files; changed-file `luac` and Kahlua checks passed; `git diff --check`
passed. Full suite remains 34/783. The graph coverage check at generation
`2026-09-30T23:25:13Z` reported `metadata_changed` for edited roots and
`not_tracked` for the new dispatch provider; no uncovered ranges were reported
and the changed source was read directly. Architecture audit reports 2,561 production
files, 355,750 scored production LOC, and 257 findings; Behaviors is 51 files
and 6,778 LOC with an 83.8 health score. `Behavior.Tick` is now 196 lines.

### Roaming player-mode provider boundary

`PNC_Behavior_Roaming.lua` retains shared roaming helpers, area/road/shelter
mode ownership, registry wiring, and the public `Roaming.Tick` contract. Player
target refresh, visibility checks, mobile-group transition handling, no-player
holding, and movement now live in
`PNC_Behavior_Roaming_PlayerMode.lua` as `Roaming.Internal.PlayerMode.Run` with
explicit Core, Const, Common, and Perception dependencies. Player-mode
registration and area fallback remain ordered through the original registry.

The focused player/mobile matrix passed 8/8 checks. Whole-tree Lua parsing
passed 2,433 files; changed-file `luac` and Kahlua checks passed;
`git diff --check` passed. Full suite remains 34/783. `pz_verify` reports the
remaining roaming root bloat at 3,840 estimated tokens across 426 lines.
Architecture audit reports 2,562 production files, 355,769 scored production
LOC, and 257 findings. Coverage at graph generation `2026-09-30T23:25:13Z`
reported `metadata_changed` for the edited root and `not_tracked` for the new
player provider; no uncovered ranges were reported and the changed source was
read directly. Behaviors is 52 files and 6,797 LOC with an 83.8 health
score.

### Roaming road-mode provider boundary

`PNC_Behavior_Roaming.lua` retains shared pacing helpers, area/player/shelter
mode ownership, registry wiring, and the public `Roaming.Tick` contract. Road
bounds tracking, bounded goal selection, blocked-path recovery, threat handling,
pause transitions, and road movement now live in
`PNC_Behavior_Roaming_RoadMode.lua` as `Roaming.Internal.RoadMode.Run`, with
explicit Core, Const, Common, BehaviorCombat, area fallback, pause, threat, and
random-goal dependencies. Road registration order and area fallback are
preserved.

The focused roaming matrix passed 8/8 checks. Whole-tree Lua parsing passed
2,434 files; changed-file `luac` and Kahlua checks passed; `git diff --check`
passed. Full suite remains 34/783. Coverage at graph generation
`2026-09-30T23:25:13Z` reported `metadata_changed` for the edited root and
`not_tracked` for the new road provider; no uncovered ranges were reported and
the changed source was read directly. `pz_verify` reports the remaining roaming
root bloat at 3,029 estimated tokens across 336 lines. Architecture audit
reports 2,564 production files, 355,911 scored production LOC, and 257
findings; Behaviors is 54 files and 6,939 LOC with an 83.8 health score.

### Roaming shelter-mode provider boundary

`PNC_Behavior_Roaming.lua` retains shared pacing and normalization helpers, all
mode registry wiring, job registration, and the public `Roaming.Tick` contract.
Shelter target tracking, threat handling, shelter arrival state, mobile-shelter
ambient callbacks, halting, and movement now live in
`PNC_Behavior_Roaming_ShelterMode.lua` as `Roaming.Internal.ShelterMode.Run`,
with explicit Core, Const, Common, BehaviorCombat, and threat-resolution
dependencies. Optional `AmbientVisitService` resolution remains dynamic.

The focused shelter/mobile matrix passed 8/8 checks. Whole-tree Lua parsing
passed 2,435 files; changed-file `luac` and Kahlua checks passed;
`git diff --check` passed. Full suite remains 34/783. Coverage at graph
generation `2026-09-30T23:25:13Z` reported `metadata_changed` for the edited
root and `not_tracked` for the new shelter provider; no uncovered ranges were
reported and the changed source was read directly. `pz_verify` reports the
remaining roaming root bloat at 2,500 estimated tokens across 276 lines.
Architecture audit reports 2,565 production files, 355,932 scored production
LOC, and 257 findings; Behaviors is 55 files and 6,960 LOC with an 83.8 health
score.

### Shared roaming context provider boundary

`PNC_Behavior_Roaming_Context.lua` now owns the shared roaming context helpers:
random goal selection, area-bound synchronization, area-state change detection,
active-passage detection, pause initialization, and roaming-threat resolution.
The provider receives explicit `Core`, `Const`, `Targeting`, and `Common`
dependencies through `Roaming.Internal.Context`. Area, road, and shelter mode
providers consume exported helper references while the root retains order
normalization, public `Roaming.Tick`, mode registration, and job wiring.

The focused all-roaming matrix passed 8/8 checks. Whole-tree Lua parsing passed
2,436 files; changed files passed `luac` and Kahlua compatibility checks with
zero issues. `git diff --check` passed. The full suite remains at 34 failures
out of 783, matching the established baseline. Coverage at graph generation
`2026-09-30T23:25:13Z` reports `metadata_changed` for the edited root and
`not_tracked` for the edited or new roaming providers; no uncovered ranges
were reported and changed source was read directly. `pz_verify` reports no
bloat warning for the 155-line root or 159-line context provider. Architecture
audit reports 2,566 production files, 355,959 scored production LOC, and 257
findings; Behaviors is 56 files and 6,987 LOC with an 83.8 health score.

### Roaming order normalization provider boundary

`PNC_Behavior_Roaming_Order.lua` now owns the roaming order schema adapter and
receives only `Const` through `Roaming.Internal.Order`. The composition root
retains the public `Roaming.Tick` contract, mode registration, job wiring, and
normalizer registration while both roaming order kinds use the provider’s
explicit `Order.Normalize` export.

The focused all-roaming matrix passed 8/8 checks. Whole-tree Lua parsing passed
2,437 files; changed files passed `luac` and Kahlua compatibility checks with
zero issues. `git diff --check` passed. The full suite remains at 34 failures
out of 783, matching the established baseline. Coverage at graph generation
`2026-09-30T23:25:13Z` reports `metadata_changed` for the edited root and
`not_tracked` for edited or new roaming providers; no uncovered ranges were
reported and changed source was read directly. `pz_verify` reports no bloat
warning for the 112-line root, 58-line order provider, or 159-line context
provider. Architecture audit reports 2,567 production files, 355,972 scored
production LOC, and 257 findings; Behaviors is 57 files and 7,000 LOC with an
83.8 health score.

### World-target resolver provider boundary

`PNC_Behavior_Targeting_WorldTargetResolver.lua` now owns native NPC, player,
zombie, and optional foreign-NPC target resolution. Shared visibility probing,
visual-memory retention, target marking, threat classification, and foreign-body
compatibility handling stay together behind the public
`Targeting.UpdateTargetFromWorld(record, target)` contract. The composition
root supplies explicit `Core`, `Const`, `Registry`, `Perception`, and
`CompatibilityAPI` dependencies and loads the resolver before the wrapper.

The targeting caller matrix passed 7/10 checks. The three failures are the
existing ThreatGuard harness failures caused by missing `SetCombatDebug`;
target reassessment, profiler markers, compatibility, Project Alife, roaming,
and player tests passed. Whole-tree Lua parsing passed 2,438 files; changed
files passed `luac` and Kahlua compatibility checks with zero issues.
`git diff --check` passed. The full suite remains at 34 failures out of 783.
Coverage at graph generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the edited targeting root and wrapper and
`not_tracked` for the new resolver; no uncovered ranges were reported and
changed source was read directly. Architecture audit reports 2,568 production
files, 356,015 scored production LOC, and 256 findings; Behaviors is 58 files
and 7,043 LOC with an 85.6 health score.

### ThreatGuard active-state tick provider boundary

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
passed. The full suite remains at 34 failures out of 783. Coverage at graph
generation `2026-09-30T23:25:13Z` reports `metadata_changed` for the
lifecycle and main tick providers and `not_tracked` for the new active
provider; no uncovered ranges were reported and changed source was read
directly. Architecture audit reports 2,569 production files, 356,039 scored
production LOC, and 255 findings; Behaviors is 59 files and 7,067 LOC with an
87.4 health score.

### Behavior tick ownership-gate provider boundary

`PNC_BehaviorSystem_Tick_Ownership.lua` now owns the ordered live-behavior
lease gates between abstract-follow/recovery handling and ordinary job
dispatch: grounded recovery, committed combat, ThreatGuard, presentation
safety, Puppet Opera, roaming ambience and seating, animation scenes, medical
leases, and treatment. The public `Behavior.Tick` coordinator retains
authority, death, sleep-wake, Puppet safety boundaries, stalled-order recovery,
facility repair, incapacitation, abstract-follow routing, action-plan ownership,
and final dispatch ordering. Source-level priority markers remain in the
coordinator for the existing combat-commitment contract check.

The focused ownership matrix passed 16/19 checks. The three failures are the
existing ThreatGuard harness failures caused by missing `SetCombatDebug`;
`pnc_combat_commitment_smoke` passed after preserving its source-order
assertions. Whole-tree Lua parsing passed 2,440 files; changed files passed
`luac` and Kahlua compatibility checks with zero issues. `git diff --check`
passed. The full suite remains at 34 failures out of 783. Coverage at graph
generation `2026-09-30T23:25:13Z` reports `metadata_changed` for the
behavior-system root and tick provider and `not_tracked` for the new
ownership provider; no uncovered ranges were reported and changed source was
read directly. Architecture audit reports 2,570 production files, 356,068
scored production LOC, and 255 findings; Behaviors is 60 files and 7,096 LOC
with an 87.4 health score.

### FollowOwner movement-plan provider boundary

`PNC_BehaviorCompanion_FollowOwner_MovementPlan.lua` now owns the live
FollowOwner movement plan: formation-slot resolution, personal-space
enforcement, horde-aware target selection, formation holding, movement-mode
selection, follow-move command issuance, combat-target clearing, and the
shared movement record update. `FollowOwner_MovementHandoff.TryHandle` keeps
the stationary-owner hold branch and delegates the remaining plan to the
provider. The companion composition root loads the provider before the
handoff with explicit Core, Const, Stealth, and Common dependencies.

The focused companion matrix passed 9/9 checks after excluding the known
pre-existing `pnc_follow_horde_steering_smoke.lua` stationary-owner failure.
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

### FollowHazard steering target-resolver provider boundary

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

### FollowOwner combat-retreat provider boundary

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

### Abstract-follow movement audit provider boundary

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

### Behavior tick preflight provider boundary

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

### Area roaming movement-plan provider boundary

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

### Abstract-follow catch-up speed provider boundary

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

### FollowOwner horde-combat policy provider boundary

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

### FollowHazard candidate-planner provider boundary

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
Whole-tree Lua parsing passed 2,450 files; changed files passed `luac` and
Kahlua compatibility checks with zero issues. `git diff --check` passed. The
full suite remains at 34 failures out of 783, matching the established
baseline.

Graph coverage generation `2026-09-30T23:25:13Z` reports
`metadata_changed` for the edited networking and inventory files and
`not_tracked` for the new providers; no uncovered ranges were reported and
changed source was read directly. The verified stale root `42.20/` duplicates
were removed. The architecture audit now reports 2,577 production files,
354,860 scored production LOC, and 240 findings; Networking is 112 files,
14,011 LOC with 62.3 health and 10 findings. Behaviors is 71 files and 7,506
LOC with a 100.0 health score and zero findings.

### Semantic social authority application boundary

`PNC_ServerSemanticSocialInteractionCommandHandler_ApplySocialEvent.lua` now
owns admitted event application, relationship replication, and response
assembly while `Authority.Handle` retains server admission and lease
validation. The public command and response contract remain unchanged. The
new server module is included in the MP loader inventory gate. The full suite
remains `34/783`, matching baseline. Architecture audit now reports 2,578
production files, 354,894 scored production LOC, and 239 findings; Networking
is 113 files, 14,045 LOC, health 62.9, and 9 findings.

### Optional LLM social authority effect and result boundaries

`PNC_ServerLLMSocialReactionCommandHandler_ApplyEffect.lua` now owns
authoritative effect application, while
`PNC_ServerLLMSocialReactionCommandHandler_BuildResult.lua` owns result
projection. The handler retains lease validation, idempotency, lease
consumption, logging, and network delivery. The full suite remains `34/783`,
matching baseline; the four focused LLM/social checks pass. Architecture
audit reports 2,580 production files, 354,991 scored production LOC, and 239
findings; Networking is 115 files, 14,142 LOC, health 62.9, and 9 findings.

### LLM reaction lease lifecycle and delivery boundary

`PNC_ServerLLMSocialReactionCommandHandler_LeaseLifecycle.lua` now owns
duplicate replay, idempotency setup, and lease consumption. The delivery
provider preserves the applied-result and relationship-snapshot order while
duplicate replay remains result-only. The full suite remains `34/783`, the
focused LLM/social checks pass `4/4`, and the MP server inventory gate is 861
files. Architecture audit reports 2,582 production files, 355,050 scored
production LOC, and 239 findings; Networking is 117 files, 14,201 LOC, health
62.9, and 9 findings.

### Combat-debug temporal projection boundary

`PNC_NetworkSnapshots_CombatDebugState_Temporal.lua` now owns expiring and
suppressed zombie combat diagnostic projection. The public combat-debug state
builder and payload schema remain unchanged. Nine focused snapshot and
presence checks pass; the full suite remains `34/783`, matching baseline.
Architecture audit reports 2,583 production files, 355,078 scored production
LOC, and 239 findings; Networking is 118 files, 14,229 LOC, health 62.9, and
9 findings.

### LLM reaction admission boundary

`PNC_ServerLLMSocialReactionCommandHandler_Admission.lua` now owns request
normalization, basic validation, lease authorization, duplicate replay, player
identity resolution, relationship snapshotting, receipt logging, and policy
availability checks. `HandleLLMSocialReaction` retains the explicit effect,
result, lease-recording, logging, and delivery sequence. Public LLM request,
rejection, idempotency, relationship, and network contracts remain unchanged.
The composition root loads admission after lease lifecycle, and direct handler
loading preserves that dependency order through fallbacks.

Focused LLM/social checks pass `4/4`; the MP server inventory gate is 862 files.
The full suite remains `34/783`, matching baseline. Whole-tree Lua parsing
passed 2,461 files, and the new provider and handler pass `luac` and
Kahlua/i18n/token checks. Architecture audit reports 2,584 production files,
355,163 scored production LOC, and 239 findings; Networking is 119 files,
14,314 LOC, health 62.9, and 9 findings. `HandleLLMSocialReaction` is no
longer a large-function finding. `Network.BuildSnapshot` and other
contract-sensitive serializers remain deferred pending a stable provider
boundary.

### Detailed snapshot projection boundaries

`PNC_NetworkSnapshots_DetailedPayloads_State.lua` owns ordered derived-state
gathering. `PNC_NetworkSnapshots_DetailedPayloads_Identity.lua` owns identity,
trait, and ownership projection. `PNC_NetworkSnapshots_DetailedPayloads_PresentationProjection.lua`
owns visual, diagnostic, equipment, and character-window projection. The final
serializer preserves the public `Network.BuildSnapshot` entry point, payload
keys, evaluation order, and inventory-copy behavior.

The composition root loads State, Identity, PresentationProjection, then Build;
direct loading keeps matching fallbacks. Focused networking and snapshot checks
pass `9/9`; the full suite remains `34/783`, matching baseline. Whole-tree Lua
parsing passed 2,464 files. Architecture audit reports 2,587 production files,
355,259 scored production LOC, 238 findings; Networking is 122 files, 14,410
LOC, health 64.2, and 8 findings. The `Network.BuildSnapshot` large-function
finding is resolved.

### LLM admission ownership boundaries

The LLM social reaction admission path now separates request normalization and
registry lookup, lease authorization and duplicate replay, and relationship
policy admission into named server providers. `Admission.lua` coordinates
those providers with player identity resolution and preserves the normalized
context consumed by the effect and result pipeline. The composition root loads
lifecycle, request, lease, policy, and admission providers in dependency order.
Focused LLM checks pass `4/4`; the MP server inventory gate is 865 files. The
full suite remains `34/783`, matching baseline. Whole-tree Lua parsing passed
2,467 files. Architecture audit reports 2,590 production files, 355,407 scored
production LOC, 237 findings; Networking is 125 files, 14,558 LOC, health
66.0, and 7 findings. `H.AdmitReaction` is no longer a large-function
finding.

### Visual-state context and payload boundaries

`VisualState_MotionContext.lua` owns path movement, facing, native traversal,
motion hints, and attack activity. `VisualState_Context.lua` retains health,
scene, and attack overlay resolution. `VisualState_Payload.lua` owns the
serialized visual-state field projection, while `BuildVisualState` remains the
timed public coordinator and preserves its payload schema and instrumentation.
The shared load order is MotionContext, Context, Payload, then coordinator.

Focused networking and snapshot checks pass `9/9`; the full suite remains
`34/783`, matching baseline. Whole-tree Lua parsing passed 2,470 files.
Architecture audit reports 2,593 production files, 355,587 scored production
LOC, 236 findings; Networking is 128 files, 14,738 LOC, health 67.8, and 6
findings. The visual-state large-function findings are resolved.

## Remaining ranked seams

1. Networking boundaries: combat-debug target normalization, presence cadence,
   combat-debug temporal projection, client inventory delta operations,
   semantic social event application, LLM effect/result boundaries, and lease
   delivery are now extracted. Remaining serializers and authority handlers
   require fresh graph evidence before a bounded handoff is safe.
2. Puppet Opera acknowledgement delivery: the 149-line provider is already
   cohesive; revisit only if acknowledgement transport and phase state acquire
   separate callers or new validation evidence.
3. Companion FollowOwner residual coordination: owner-state, abstract, live
   movement, combat, vehicle, horde-steering, and abstract movement handoffs
   are now extracted. Review remaining companion diagnostics and provider-level
   behavior hotspots after fresh graph and coverage evidence.
4. Self-treatment live and abstract tick orchestration is now behind its
   original `BehaviorTreatment.Tick` contract. Review the remaining behavior
   system coordinator and treatment helper ownership only with affected tests.
5. Seated request diagnostics were extracted from `Common.MoveRecord` into
   `PNC_Behavior_Common_MoveRecord_SeatingAudit.lua` behind the existing
   composition root. Review the remaining movement orchestration only if fresh
   graph evidence identifies a separate owner-focused contract.

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

## Known limitations

Live singleplayer, hosted multiplayer, dedicated-server, reconnect, and real
save-reload validation were unavailable in the environment. Static tests and
isolated harnesses reduce risk but do not replace those runtime gates.


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
## Chunk 241 — Scavenge window provider split

`PNC_ScavengeWindow.lua` was a remaining client UI monolith. Its manifest grouping, status and diagnostics rows, user actions, widget construction and responsive layout, frame rendering, and window lifecycle now load through explicit providers: `PNC_ScavengeWindow_Manifest.lua`, `PNC_ScavengeWindow_Status.lua`, `PNC_ScavengeWindow_Actions.lua`, `PNC_ScavengeWindow_View.lua`, `PNC_ScavengeWindow_Render.lua`, and `PNC_ScavengeWindow_Lifecycle.lua`. The public `ISPNCScavengeWindow` and `PNC.ScavengeUI` entry paths remain stable; the parent passes shared dependencies through `Internal` and preserves provider load order.

The pre-split window measured 8,166 tokens and 813 lines in the local detector. The resulting entry and providers measure 1,472, 1,431, 1,844, 674, 1,997, 555, and 642 tokens respectively, so this slice has no file over the 2,000-token threshold. The existing scavenge smoke source audit now reads the provider set as one UI surface. Full validation remains green at `783/783`; whole-tree Lua parsing and `git diff --check` pass.

## Current checkpoint after Chunk 241

The screenshot hotspots are therefore not all gone. Generated catalogs and translation tables remain data-heavy, while several production modules still need bounded provider splits. The detector is a triage signal; responsibility boundaries and authority risk decide the next refactor order.
## Chunk 242 — Firearm effects provider boundaries

`PNC_ClientFirearmEffects.lua` had already moved screen drawing, but its live client module still combined debug simulation, body and weapon resolution, shot orchestration, audio and light creation, and projectile screen fallback. These responsibilities now load through explicit providers: `PNC_ClientFirearmEffects_Simulation.lua`, `PNC_ClientFirearmEffects_Lifecycle.lua`, `PNC_ClientFirearmEffects_Resolution.lua`, `PNC_ClientFirearmEffects_Play.lua`, `PNC_ClientFirearmEffects_AudioVisual.lua`, `PNC_ClientFirearmEffects_ScreenGeometry.lua`, and `PNC_ClientFirearmEffects_ProjectileQueue.lua`. The existing `PNC_ClientFirearmEffects_UIDraw.lua` path remains intact. Provider dependencies are passed through `Effects.Internal`, and event registration remains in the stable parent entry file.

The parent fell from 9,137 tokens to 2,175. The largest new provider is screen geometry at 2,172 tokens; the remaining parent and geometry provider are cohesive shared surfaces rather than mixed orchestration. The six firearm smoke tests pass after the extraction, including the long projectile and debug simulation coverage. Whole-tree Lua parsing, full `783/783` validation, and `git diff --check` pass.

## Current checkpoint after Chunk 242

The screenshot’s firearm hotspot is substantially decoupled but remains just above the detector threshold in two cohesive modules. The detector is still a triage signal; preserving the native fallback, client-only rendering, and debug simulation contracts takes priority over shaving a small number of tokens.
## Chunk 243 — Corpse-awareness provider boundaries

`PNC_BodyLifecycle_CorpseAwareness.lua` now keeps the public `PNC.CorpseAwareness` entry paths while loading relationship logic, corpse identity, death attribution, social reactions, candidate scoring, witness processing, death observation, and corpse observation through explicit providers. Existing authority checks, bounded visibility and candidate loops, ModData cache fields, relationship memory IDs, and reaction payloads remain unchanged.

The local detector reports the parent at `1,728` tokens; all nine corpse-awareness files are below the `2,000`-token threshold. The corpse-awareness smoke family passes `11/11`; whole-tree Lua parsing, the full `783/783` suite, and `git diff --check` remain required final checks. The graph coverage snapshot is from `2026-09-30`; modified and newly extracted files require direct source validation until reindexed.

## Chunk 244 — Live body control state boundaries

`PNC_LiveBodyControl_State.lua` now retains the stable `PNC.LiveBodyControl` state entry and shared state tables while loading native intent and classification, stationary presentation ownership, passage probing and door geometry, passage guard interception, and passage recovery through explicit providers. The existing heavy-item provider remains last in the state load sequence so climb-ahead behavior and native movement detection keep their established availability.

The parent is now `837` tokens. The new core, presentation, passage probe, passage guard, and passage recovery providers measure `1,228`, `1,856`, `1,829`, `1,119`, and `1,462` tokens. Focused pathing, live-body, and passage checks pass `3/3`, `2/2`, and `3/3`; the full suite passes `783/783`, whole-tree Lua parsing passes, and `git diff --check` is clean. The graph snapshot remains stale for edited and newly extracted paths, so direct source and runtime smoke validation support this slice.

## Chunk 245 — Unique NPC appearance provider boundaries

`PNC_UniqueNPCAppearanceWindow.lua` now retains the stable appearance UI namespace, scroll panel, window lifecycle, render path, and `AppearanceUI.Open` entry while loading option utilities, option catalogs, control construction, option population, appearance editing, voice preview, responsive layout, and draft synchronization through explicit providers. The shared `Window.Internal` table carries the existing model, appearance, UI, layout, translation, and audio dependencies across those providers.

The parent is `1,216` tokens; the provider set ranges from `408` to `1,884` tokens, with every appearance-window file below the `2,000`-token threshold. The Unique NPC test slice passes `7/7`; the full suite passes `783/783`, whole-tree Lua parsing passes, and `git diff --check` is clean. The current graph generation predates these providers, so direct source and parser validation support the changed UI family.

## Chunk 246 — Unique NPC editor provider boundaries

`PNC_UniqueNPCEditorWindow.lua` now retains the stable editor namespace, window lifecycle shell, render and close behavior, and `EditorUI.Open`/`Toggle` entry paths while loading shared form helpers, option catalogs, editor construction, responsive layout, and editor actions through explicit providers. The existing form, details, preview, and persistence providers remain loaded after the shared interface is established.

The parent is `976` tokens; all editor-window providers are below `2,000`, with the largest at `1,867`. The Unique NPC test slice passes `7/7`; the full suite passes `783/783`, whole-tree Lua parsing passes, and `git diff --check` is clean. The graph snapshot predates these provider files, so direct source and parser validation support the changed UI family.

## Chunk 247 — Generated semantic dialogue shards

`PNC_SemanticGeneratedDialogue.lua` is now a small stable aggregator generated alongside deterministic pattern and response shards. The semantic compiler owns the shard split and build cleanup, so generated output remains reproducible while the runtime keeps the same source marker, pattern lookup, and response-pool contract. The largest generated shard is `3,434` tokens. Semantic tests pass `69/69`; the compiler unit suite and parser checks pass.

## Chunk 248 — Roaming seat service providers

`PNC_RoamingSeatService.lua` now loads policy, discovery, lifecycle, start, tick, and scene providers in order. Facility access, ambient floor scenes, seat reservations, task start and completion, cleanup, and player-facing scenes retain their existing server ownership and public service paths. The largest provider is `2,038` tokens. Roaming tests pass `2/2`, the floor-seat Lua smoke passes, and parser and diff checks are clean.

## Chunk 249 — Character window shared providers

`PNC_CharacterWindow_Shared.lua` now keeps a stable shared entry while loading core state, activity text, data projection, clothing, and render providers. Shared caches and health, text, clothing, activity, and presentation contracts remain available through the same namespace. The largest provider is `2,643` tokens. Character data, text, and health checks pass `4/4`.

## Chunk 250 — Ambient visit service boundaries

`PNC_AmbientVisitService.lua` now loads core state, lease management, invitation handling, mobile shelter behavior, and lifecycle cleanup alongside the existing eligibility and mobile-site providers. Lease ownership, authority checks, invitation records, shelter keys, order protection, and release behavior remain in the original server service path. The largest provider is `3,557` tokens. Ambient, facility, and conversation-authority checks pass `28/28` across the focused slices.

## Chunk 251 — Colonist activity providers

`PNC_ColonistActivities.lua` now delegates shared state, layout computation, and UI actions through explicit providers while preserving the colonist presentation dependency and public activity methods. The largest provider is `3,812` tokens. Colonist activity and UI checks pass `2/2`.

## Chunk 252 — Relationship debug model providers

`PNC_RelationshipDebugModel.lua` now separates shared normalization, identity rows, detail projection, and row construction. Existing relationship graph data, personality bands, and debug presentation payloads remain unchanged. The largest provider is `2,651` tokens. Relationship model, graph, and emote presentation checks pass `3/3`.

## Chunk 253 — Semantic cognition projection providers

`PNC_SemanticCognitionProjection.lua` now loads core normalization, codec, operations, and client synchronization providers. Fact decoding, identity seeds, compact persistence, pruning, client authority, and service-facing projection methods keep the existing IR and persistence contract. The largest provider is `2,846` tokens. Projection, fact, client, service, and persistence checks pass `5/5`.

## Chunk 254 — Water container transaction providers

`PNC_WaterContainerService.lua` now separates shared transaction state, admission checks, and refill execution. Native inventory synchronization, fluid identity, rollback, ownership, diagnostics, and refill events retain their existing behavior and server entry path. The largest provider is `3,686` tokens. Water container, refill, hydration, state, and nearby-water checks pass `6/6`.

## Chunk 255 — Order system providers

`PNC_OrderSystem.lua` now loads base order construction, transitions, recovery, and actions through explicit providers. Wake records, camp-blocked release, movement order kinds, recovery state, and public order methods remain available through the same namespace and load path. The largest provider is `2,064` tokens. Order transition, recovery, camp foundation, camp work release, and API boundary checks pass `5/5`.

## Chunk 256 — Medical care executor providers

`PNC_MedicalCareExecutor_Provider.lua` now keeps a stable provider entry while loading core state, supply policy, supply actions, and lifecycle logic; the existing outer medical executor and actions path remains intact. Doctor grouping, treatment supply retries, notices, task lifecycle, and authority behavior are preserved. The largest operated provider is `3,013` tokens. Medical executor, repository, treatment policy, and semantic action-plan checks pass `6/6`.

## Chunk 257 — Zombie aggro update providers

`PNC_ZombieAggro_Update.lua` now loads core update state, pathing, pursuit, target selection, loop scheduling, and the existing multiplayer directive provider in order. Pursuit locks, stealth suppression, bite lane behavior, multiplayer target directives, and diagnostic counters remain under the original update namespace. The largest provider is `2,344` tokens. Zombie aggro, multiplayer, pursuit, bite-lane, and stimulus checks pass `10/10`.

## Chunk 258 — Camp zone service providers

`PNC_CampZoneService.lua` now loads shared helpers, bounded room discovery, need assignment policy, and runtime retention providers. Room and resource discovery, need precedence, deterministic scoring, assignment revisions, retained-directory pruning, and server authority remain unchanged. The largest provider is `2,433` tokens. The camp-zone suite passes `17/17`; adjacent camp, perception, overlay, and movement checks also pass.

## Chunk 259 — Mobile ambient director providers

`PNC_MobileGroupDirector_Ambient.lua` now keeps a stable public wrapper while loading shared ownership helpers, strategic objective logic, ambient refresh, and scheduler runtime providers. Existing shelter and order providers remain in the load path; public refresh and pump methods, target selection budgets, faction cursoring, diagnostics, and server authority are preserved. The largest new provider is `2,456` tokens. Ambient, mobile group, departure, debug, and presence checks pass `7/7`.

## Chunk 260 — Settlement layout overlay providers

`PNC_SettlementLayoutOverlay.lua` now loads geometry helpers, settlement layer and marker projection, and client rendering/state lifecycle providers. The stable entry retains event registration and the existing overlay namespace, while facility colors, work-zone handling, workstation approach points, labels, hover state, reset behavior, and client synchronization remain unchanged. The largest provider is `3,048` tokens. Overlay, tab button, and colony-context checks pass `3/3`.

## Current checkpoint after Chunk 260

The exact detector configuration from the refactor task currently reports `2,734` scanned, `81` over `4,000`, and `19` excluded. The latest batch has focused parser, diff, graph-coverage, and smoke evidence; the full suite and final zero-over-threshold scan remain pending until the remaining hotspots are migrated. The graph generation remains `2026-09-30T23:25:13Z`; changed entry files report metadata-changed freshness and new providers are not tracked, so direct source and runtime validation support these claims.

## Chunk 261 — Player animation debug window providers

`PNC_PlayerAnimationDebugWindow.lua` now retains the stable UI entry and public `PNC.PlayerAnimationDebugUI` API while loading catalog/filter setup, selected-entry details and actions, responsive layout, rendering, window lifecycle, and reset handling through explicit providers. The existing debug and catalog dependencies, player/zombie tabs, playback controls, trace dump, loop state, and permission gate remain unchanged. The largest provider is `3,071` tokens. The animation debug test family passes `24/24`, the snapshot gate passes, and all window providers pass Lua parsing.

## Current checkpoint after Chunk 261

The exact detector configuration now reports `2,738` scanned, `80` over `4,000`, and `19` excluded. Focused validation and direct source checks remain green for the latest slice; the full suite and final zero-over-threshold scan remain pending while the remaining 80 hotspots are migrated.

## Chunk 262 — Detailed network snapshot diagnostics providers

`PNC_NetworkSnapshots_DetailedDebugState.lua` now keeps the stable `SnapshotParts` entry while loading shared camp resource helpers, seating diagnostics, camp resource diagnostics, and final detailed-state projection providers. Downstream detailed and presence payload modules still capture the same `BuildDetailedDebugState`, `BuildSeatingDebugState`, and `BuildCampResourceDebugState` functions after the existing network snapshot load point. Camp overlay, snapshot, and network test slices pass `11/11`; the provider family passes Lua parsing.

## Current checkpoint after Chunk 262

The exact detector configuration now reports `2,742` scanned, `79` over `4,000`, and `19` excluded. The current graph generation is unchanged and does not track the newly extracted providers; coverage calls report no recorded issue with metadata-changed or not-tracked freshness, so direct source, parser, and focused runtime checks remain the evidence for these changes.

## Chunk 263 — Camp movement coordinator providers

`PNC_CampMovementCoordinator.lua` now loads shared movement helpers, session lifecycle, group-camp queue creation, and bounded pump advancement through explicit providers. Camp placement locks, one-live-member ownership, order writes, queued and moving states, blocked and timeout recovery, arrival events, and server authority remain on the same coordinator namespace and load path. The largest provider is `3,296` tokens. Camp movement and group-camp integration checks pass `2/2`, and the provider family passes Lua parsing.

## Current checkpoint after Chunk 263

The exact detector configuration now reports `2,746` scanned, `78` over `4,000`, and `19` excluded. The latest movement slice has focused smoke, parser, diff, and graph-coverage evidence; the full suite and final zero-over-threshold scan remain pending.
## Chunk 264 — Facility interaction target providers

`PNC_InteractionTargetResolver.lua` now loads core registration and workstation edges, furniture sleep targets, and live seating targets through explicit providers. Resolver caching, workstation approach ordering, sleep surface capacity, furniture-height conversion, SeatingManager validation, deferred abstract targets, and resource registration remain unchanged. The largest provider is `2,378` tokens. Workstation, camp sleep, roaming floor-seat, camp resource, and semantic world-target checks pass `6/6` across the focused slices.

## Current checkpoint after Chunk 264

The exact detector configuration now reports `2,749` scanned, `77` over `4,000`, and `19` excluded. The interaction-target slice has focused runtime, parser, diff, and graph-coverage evidence; the full suite and final zero-over-threshold scan remain pending.
## Chunk 265 — Base building catalog providers

`PNC_BaseBuildingCatalog.lua` now keeps a stable catalog namespace while loading shared UI helpers, recipe/category/queue projections, and public catalog controls through explicit providers. Facility recipe filtering, stable list updates, material rows, placement and queue actions, favorite state, preview state, and existing recipe, preview, and layout dependencies remain unchanged. The largest new provider is `3,813` tokens. The building test family passes `19/19`, the base UI contract check passes, and the provider family passes Lua parsing.

## Current checkpoint after Chunk 265

The exact detector configuration now reports `2,752` scanned, `76` over `4,000`, and `19` excluded. The latest building slice has focused runtime, parser, diff, and graph-coverage evidence; the full suite and final zero-over-threshold scan remain pending.
## Chunk 266 — Mobile settlement visit providers

`PNC_MobileSettlementVisitService.lua` now loads eligibility policy, deferred arrival processing, member admission, and settlement arrival orchestration through explicit server providers. Hostility checks, player-owned settlement admission, encounter handoff, visit expiry, AI join rolls, transfer rollback, pending member state, and conversation admission methods remain on the same service namespace. The largest provider is `2,060` tokens. Mobile settlement admission, composition bootstrap, and conversation authority checks pass `3/3`.

## Current checkpoint after Chunk 266

The exact detector configuration now reports `2,756` scanned, `75` over `4,000`, and `19` excluded. The latest visit-service slice has focused runtime, parser, diff, and graph-coverage evidence; the full suite and final zero-over-threshold scan remain pending.
## Chunk 267 — Nameplate firearm anchor providers

`PNC_NameplateFirearmAnchor.lua` now keeps the shared anchor namespace while loading cache and facing math, muzzle projection and offset controls, and target/render/reset lifecycle providers. Legacy offset migration, player projection caching, render-space scaling, debug state, target selection, tracer coordinates, and reset hooks remain unchanged. The largest provider is `2,882` tokens. Firearm-anchor, combat-overlay, and nameplate-debug checks pass `3/3`, and the provider family passes Lua parsing.

## Current checkpoint after Chunk 267

The exact detector configuration now reports `2,759` scanned, `74` over `4,000`, and `19` excluded. The latest anchor slice has focused runtime, parser, diff, and graph-coverage evidence; the full suite and final zero-over-threshold scan remain pending.
## Chunk 268 — Audio debug window providers

`PNC_AudioDebugWindow.lua` now keeps the stable audio debug API while loading shared UI helpers, dialogue controls, SFX controls, and window lifecycle providers. Voice style and pitch state, event filtering, dialogue playback, SFX playback, reset behavior, tab layout, debug permission checks, and the existing audio model contract remain unchanged. The largest provider is `2,377` tokens. The audio model, client bootstrap, and debug hub checks pass `3/3`, and the provider family passes Lua parsing.

## Current checkpoint after Chunk 268

The exact detector configuration now reports `2,763` scanned, `73` over `4,000`, and `19` excluded. The latest audio-window slice has focused model, parser, diff, and graph-coverage evidence; the full suite and final zero-over-threshold scan remain pending.
## Chunk 269 — Social flavor registration shards

`PNC_SocialFlavorDefinitions.lua` now acts as a stable registration aggregator with a shared translation helper and three deterministic complete-record shards. Farewell, combat, relationship, safety, zombie-awareness, translated-line, and social-role variants retain registration order and exact flavor payloads. The largest shard is `2,828` tokens. Social flavor and farewell checks pass `21/21`, and the shard family passes Lua parsing.

## Current checkpoint after Chunk 269

The exact detector configuration now reports `2,767` scanned, `72` over `4,000`, and `19` excluded. The latest flavor-data slice has focused runtime, parser, diff, and graph-coverage evidence; the full suite and final zero-over-threshold scan remain pending.
## Chunk 270 — Character-window health providers
`PNC_CharacterWindow_Health.lua` now remains a stable tab entry point while body-map rendering, wound and whole-body detail rows, medical activity, and public health interaction providers load in deterministic order. Vanilla body-damage textures, debug bandage diagnostics, selectable hit regions, translation fallbacks, and health-context menu behavior remain unchanged. The largest new provider is below `4,000` tokens. Character-health render checks pass `2/2`; health-context checks pass `1/1`; the exact detector now reports `2,770` scanned, `71` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 271 — Husk ledger providers
`PNC_BodyLifecycle_HuskLedger.lua` now keeps the original load path while storage and persistence, strict body matching and rearming, shell identity and orphan policy, and diagnostics load as ordered providers. The public `BodyLifecycle` ledger API, compact ModData rows, bounded eviction, startup seeding, strict outfit and position matching, disabled-zombie orphan rule, debug census, and reaper handoff remain unchanged. The largest provider is below `4,000` tokens. Husk ledger/reaper/end-to-end checks pass `3/3`, live-body-loss passes `1/1`, provider parsing passes; the exact detector now reports `2,773` scanned, `70` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 272 — Network payload budget providers
`PNC_Network_Server_Budget.lua` now remains the stable payload-budget API while estimation and rejection accounting, chunk decomposition and transport envelopes, and the direct `sendServerCommand` safety guard load in order. Budget estimation, section attribution, oversize action replies, chunk reconstruction contracts, third-party traffic passthrough, and server-only installation remain unchanged. The largest provider is below `4,000` tokens. Network payload budget checks pass `1/1`; multiplayer and single-player snapshot budget checks pass `1/1` each; provider parsing passes. The exact detector now reports `2,776` scanned, `69` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 273 — Companion command flavor shards
`PNC_CompanionCommandFlavorDefinitions.lua` now remains the stable catalog entry while registration helpers, base commands and vanilla emotes, relationship-sensitive replies, and social greeting data load in deterministic order. Flavor IDs, fallback lines, relationship and greeting variants, translation keys, and `Flavor.Register` side effects remain unchanged. The largest provider is below `4,000` tokens. Vanilla emote interaction checks pass `1/1`, social greeting checks pass `2/2`, companion command interaction and command checks pass `1/1` each, and provider parsing passes. The exact detector now reports `2,780` scanned, `68` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 274 — Colony management snapshot providers
`PNC_ColonyManagement_Snapshots.lua` now keeps the server snapshot entry path while shared identity and settlement helpers, the compact base projection, and the sectioned full projection load in deterministic order. Base and full snapshot APIs, ownership resolution, faction and colony selection, storage access states, roster reconciliation, settlement/task decoration, scoped sections, research/building/workshop/provision projections, zone state, and generated timestamps remain unchanged. The largest provider is below `4,000` tokens. Colony-management family checks pass `10/10`; sync and client base-scope checks pass `1/1` each; provider parsing passes. The exact detector now reports `2,783` scanned, `67` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 275 — Map command registry providers
`PNC_MapCommandRegistry.lua` now remains the stable map-command entry while selection and provider dispatch, context-menu and map-open behavior, and map rendering/input hooks load in dependency order. Provider ordering, selection normalization and bounds, region selection geometry, dispatch payloads, result handling, map-layer status, pause handling, and vanilla input delegation remain unchanged. The largest provider is below `4,000` tokens. Map registry, lumber, and fishing checks pass `1/1` each; provider parsing passes. The exact detector now reports `2,786` scanned, `66` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 276 — Unique NPC editor model providers
`PNC_UniqueNPCEditorModel.lua` now remains the stable client model entry while draft/core utilities, definition and trait validation, runtime preview synchronization, and portrait/inventory presentation operations load in order. Draft defaults, name-derived IDs, preview-only seeds, authored sparse definitions, appearance capture, skill and trait conflict validation, runtime preview retention, inventory export/removal, portrait specs, and list/map parsers remain unchanged. The largest provider is below `4,000` tokens. Editor-model checks pass `1/1`, transfer checks pass `1/1`, the broader unique-NPC family passes `7/7`, and providers parse. The exact detector now reports `2,789` scanned, `65` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 277 — Semantic world target resolver providers
`PNC_SemanticWorldTargetResolver.lua` now remains the server semantic boundary while primitive target and client-hint validation, bounded world-object/campfire helpers, provider registration, and final resolution load in order. Primitive IR assignments, client hint range and kind checks, authoritative campfire validation, dynamic players, facility resources, alias resolution, trace diagnostics, provider failure reasons, object-free output, and the existing object-provider spoke remain unchanged. The largest provider is below `4,000` tokens. World-target checks pass `2/2`; authority and client-hint checks pass `1/1` each; action-plan path and camp-task checks pass `1/1` each; providers parse. The exact detector now reports `2,791` scanned, `64` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 278 — Director debug model providers
`PNC_DirectorDebugModel.lua` now keeps the stable client model path while list helpers, director/population summaries, sector and group detail rows, and final detail composition load in order. Group/location/sector lists, population metrics, starter and discovery diagnostics, mobile lifecycle rows, combat/scavenge details, authorization errors, and row tone semantics remain unchanged. The largest provider is below `4,000` tokens. Director debug, abstract-director boundary, and mobile-group boundary checks pass `1/1` each; providers parse. The exact detector now reports `2,795` scanned, `63` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 279 — Relationship debug window providers
`PNC_RelationshipDebugWindow.lua` now remains the stable relationship laboratory entry while construction/layout, selection and request behavior, control callbacks, rendering, lifecycle, and open/toggle APIs load in order. Observer and target selection, relationship requests, graph refresh, baseline/pacification/social triggers, section filters, responsive layout, debug authorization, and reset cleanup remain unchanged. The largest provider is below `4,000` tokens. Relationship model, graph, and window boundary checks pass `1/1` each; providers parse. The exact detector now reports `2,798` scanned, `62` over `4,000`, `19` excluded. Full-suite and final zero-over-threshold validation remain pending.
## Chunk 280 — Zombie aggro state providers `PNC_ZombieAggro_State.lua` now remains the stable shared state entry while pursuit lease compatibility, attacker identity, target discovery/cleanup, and attack activation load in deterministic order. Pursuit ownership priorities, lease revisions/expiry, public `ZombieAggro.Pursuit` adapters, managed-shell identity, recent attacker records, MP native-target safety, stealth-aware player selection, NPC selection/suppression, attack cooldowns, forced aggro, and combat-hit settling remain unchanged. Largest provider is below `4,000` tokens; focused zombie aggro, pursuit, attacker, bite, stealth, stimulus, budget, and MP boundary checks pass. Provider parsing and diff checks pass. Exact detector now reports `2,802` scanned, `61` over `4,000`, `19` excluded; the next hotspot is `PNC_NameplateDebug.lua` at `5,119` estimated tokens. Full-suite final zero-over-threshold validation remains pending.
## Chunk 281 — Nameplate debug providers `PNC_NameplateDebug.lua` now remains the stable client debug API while settings/text assembly, animation runtime inspection, and scene/snapshot text load in order. Camp/seating/AI/combat/infection text, synthetic animation frames, Java animation-track sampling, scene revision diagnostics, animation labels, and snapshot descriptions remain unchanged. Largest provider is below `4,000` tokens; nameplate debug, combat overlay, and nameplate family checks pass `6/6`, provider parsing, function-contract, and diff checks pass. Exact detector now reports `2,805` scanned, `60` over `4,000`, `19` excluded; the next hotspot is `PNC_LumberService_Execution_OutputDelivery.lua` at `5,110` estimated tokens. Full-suite final zero-over-threshold validation remains pending.
## Chunk 282 — Lumber output delivery providers `PNC_LumberService_Execution_OutputDelivery.lua` now remains the guarded server composition root while floor pickup/abstract inventory delivery and destination/storage/live tick orchestration load in order. Output effect markers, one-shot grab/deposit scenes, world-item rollback, NPC inventory capture, stockpile resolution, typed storage transfer, waiting reasons, runtime diagnostics, and public `FlushAbstractOutput`/`TickLiveOutput` handoffs remain unchanged. Largest provider is below `4,000` tokens; lumber service and lumber family checks pass `7/7`, MP server loader guard passes, provider parsing, function-contract, and diff checks pass. The stale server inventory tripwire was updated from `880` to the measured `924` files. Fifty-four previously unguarded server providers also received the standard runtime-role early return after the loader audit exposed pure-client initialization hazards. Exact detector now reports `2,807` scanned, `59` over `4,000`, `19` excluded; the next hotspot is `PNC_NameplateEntries.lua` at `5,058` estimated tokens. Full-suite final zero-over-threshold validation remains pending.
## Chunk 283 — Nameplate entry providers `PNC_NameplateEntries.lua` now remains the stable client entry while faction/community diagnostics, text/metric caching, and live/debug entry refresh load in order. Identity/speech/tool feedback, animation and infection diagnostics, relationship/community tones, health/stamina visibility, snapshot/body resolution, scope filtering, diagnostics counters, stale-entry cleanup, and `Entries.Refresh` behavior remain unchanged. Largest provider is below `4,000` tokens; nameplate, nameplate-debug, and combat-overlay checks pass `6/6`, provider parsing, function-contract, and diff checks pass. Exact detector now reports `2,810` scanned, `58` over `4,000`, `19` excluded; the next hotspot is `PNC_NameplateRenderer_Core.lua` at `5,046` estimated tokens. Full-suite final zero-over-threshold validation remains pending.
## Chunk 284 — Nameplate renderer core providers `PNC_NameplateRenderer_Core.lua` now remains the stable renderer handoff while status bars/debug lines/conversation rendering and live-body anchoring/status/identity/debug overlays load in order. Scope filtering, relationship/tool feedback, speech text-object caching, health/stamina bars, firearm anchor updates, animation/scene diagnostics, debug-only entries, live entries, alpha handling, and `Internal.DrawDebugOnly`/`Internal.DrawLive` contracts remain unchanged. Largest provider is below `4,000` tokens; nameplate debug, nameplate family, and firearm-anchor checks pass `6/6`, provider parsing, function-contract, and diff checks pass. Exact detector now reports `2,812` scanned, `57` over `4,000`, `19` excluded; the next hotspot is `PNC_BodyLifecycle_CorpseItems.lua` at `5,035` estimated tokens. Full-suite final zero-over-threshold validation remains pending.
## Chunk 285 — Corpse-item providers `PNC_BodyLifecycle_CorpseItems.lua` now remains the stable lifecycle entry while identity-card handling, faction dog-tag metadata, and corpse inventory/materialization load in order. Versioned identity/dog-tag matching, stale-item cleanup, faction metadata caching, authority checks, logical inventory transfer, worn/equipped item reuse, visual copying, clothing protection, corpse-item deduplication, and `PrepareCorpseItems` remain unchanged. Largest provider is below `4,000` tokens; body-lifecycle, corpse transfer/clothing/audit, infected reanimation, and boundary checks pass `8/8`, provider parsing, function-contract, and diff checks pass. Exact detector now reports `2,815` scanned, `56` over `4,000`, `19` excluded; the next hotspot is `PNC_SupplyInventory_Consumption.lua` at `5,018` estimated tokens. Full-suite final zero-over-threshold validation remains pending.
## Chunk 286 — Supply consumption providers `PNC_SupplyInventory_Consumption.lua` now remains the guarded server entry while canonical logical operations/effects, native physical mutation, and transactional public consumption load in order. Fluid-volume hydration, food replacement, stack splitting, nutrition effects, physical rollback, native item repair, persistence-mode metrics, compact inventory deltas, event emission, and `SupplyInventory.Consume` remain unchanged. Largest provider is below `4,000` tokens; supply-inventory boundary, seed-delta, semantic consumption, MarketSense consumption, and MP server guard checks pass `5/5`, provider parsing, function-contract, and diff checks pass. The server inventory tripwire now expects the measured `927` server files. Exact detector now reports `2,818` scanned, `55` over `4,000`, `19` excluded; the next hotspot is `PNC_FacilityJobsBehavior_Lifecycle.lua` at `5,003` estimated tokens. Full-suite final zero-over-threshold validation remains pending.
## Chunk 287 — Facility lifecycle providers `PNC_FacilityJobsBehavior_Lifecycle.lua` now remains the stable shared lifecycle entry while sleep/wake interruption and finish/abort/stop progress ownership load in order. Combat-threat preservation, bounded wake animation/release, authoritative sleep-exit placement, position restoration, scene cleanup, reservation release, task-lease cancellation, order-change aborts, ActorControl ownership, effect-clock progress, and lifecycle API names remain unchanged. Largest provider is below `4,000` tokens; facility activity/recovery, sleep placement/transition, threat-guard handoff, tasking recovery, and order-transition checks pass `9/9`, provider parsing, function-contract, and diff checks pass. The order entry also retains source-boundary compatibility markers for direct recovery contracts. Exact detector now reports `2,820` scanned, `54` over `4,000`, `19` excluded; the next hotspot is `PNC_PuppetOpera_Blueprints_Normalization.lua` at `5,000` estimated tokens. Full-suite final zero-over-threshold validation remains pending.
## Chunk 288 — Puppet Opera blueprint normalization providers `PNC_PuppetOpera_Blueprints_Normalization.lua` now remains the stable normalization API while primitive sanitization/anchors, actor-kind and track lowering, and timeline/beat compilation load in order. Text/ID bounds, finite numeric validation, variable normalization, actor compatibility, player/NPC/future tracks, capability normalization, nested timeline limits, duplicate-node checks, required tracks, legacy aliases, and public normalization names remain unchanged. Largest provider is below `4,000` tokens; Puppet Opera family checks pass `18/18`, provider parsing, function-contract, and diff checks pass. Exact detector now reports `2,823` scanned, `53` over `4,000`, `19` excluded; the next hotspot is `PNC_NPCMonitor.lua` at `4,985` estimated tokens. Full-suite final zero-over-threshold validation remains pending.
## Chunk 289 — NPC monitor providers `PNC_NPCMonitor.lua` now remains the stable client entry while tracking/bootstrap and overlay controls, equipment/map context actions, and roster/detail/render lifecycle load in order. Public monitor tracking, `ISPNCNPCMonitor`, roster requests, selection/detail refresh, body outlines, debug actions, equipment/map mutations, overlay toggles, teleport/map commands, render/update hooks, reset cleanup, and UI contracts remain unchanged. Largest provider is below `4,000` tokens; NPC monitor, equipment debug, death-marker, and bootstrap checks pass `5/5`, provider parsing, function-contract, and diff checks pass. Exact detector now reports `2,826` scanned, `52` over `4,000`, `19` excluded; the next hotspot is `PNC_CampResourceService_Discovery.lua` at `4,937` estimated tokens. Full-suite final zero-over-threshold validation remains pending.

## Chunk 290 — Camp resource discovery providers
`PNC_CampResourceService_Discovery.lua` now remains the guarded discovery composition root while descriptor helpers, resource provider registration, snapshot validation/capture, and the public capture/pump API load in order. Bed, sofa, faucet, and seat detection, primitive snapshot copying, room and radius scans, bounded per-tick pumping, cache reuse, stale-state invalidation, deterministic resource ordering, and public `Capture`/`GetSnapshot`/`Pump` behavior remain unchanged. Largest provider is below `4,000` tokens; camp resource modules, sleep, seating, overlay, zone, work-release, and MP server-guard checks pass `7/7`, provider parsing, function-contract, and diff checks pass. The server inventory tripwire now expects the measured `931` files. Exact detector reports `2,830` scanned, `51` over `4,000`, `19` excluded; the next hotspot is `PNC_NPCKnowledgeAPI.lua` at `4,934` estimated tokens. Full-suite final zero-over-threshold validation remains pending.

## Chunk 291 — NPC knowledge API providers
`PNC_NPCKnowledgeAPI.lua` now remains the guarded knowledge API composition root while player context/read topics, disclosure authorization and gift preference handling, and mutating disclosure endpoints load in order. Player-scoped snapshots, topic enumeration, conversation lease checks, semantic provenance, identity-claim gates, gift preference evaluation and persistence, pending commits, related-NPC referrals, and the existing API methods remain unchanged. Largest provider is below `4,000` tokens; knowledge, identity, referral, client request, semantic mirror, network boundary, and MP server-guard checks pass `14/14`, provider parsing, function-contract, and diff checks pass. The server inventory tripwire now expects the measured `934` files. Exact detector reports `2,833` scanned, `50` over `4,000`, `19` excluded; the next hotspot is `PNC_ColonistDepartureService.lua` at `4,918` estimated tokens. Full-suite final zero-over-threshold validation remains pending.

## Chunk 292 — Colonist departure providers
`PNC_ColonistDepartureService.lua` now remains the guarded departure composition root while relationship/policy context, destination and mobile-state helpers, departure execution, and the bounded automatic pump load in order. Player ownership checks, relationship evaluation, manual penalties, fallback community sites, refugee mobile faction creation, membership transfer, abstract road objectives, completion markers, threshold confirmation, recovery, authority gates, and public `Evaluate`/`GetPreview`/`CanPlayerManage`/`Depart`/`Pump` behavior remain unchanged. Largest provider is below `4,000` tokens; colonist departure/conversion, mobile departure/group, conversation, faction/debug, social-event, nameplate feedback, and MP server-guard checks pass `14/14`, provider parsing, function-contract, and diff checks pass. The server inventory tripwire now expects the measured `938` files. Exact detector reports `2,837` scanned, `49` over `4,000`, `19` excluded; the next hotspot is `PNC_SemanticCampSiteResolver.lua` at `4,918` estimated tokens. Full-suite final zero-over-threshold validation remains pending.

## Chunk 293 — Semantic camp site resolver providers
`PNC_SemanticCampSiteResolver.lua` now remains the guarded semantic resolver composition root while shared normalization/geometry helpers, client-hint validation and diagnostics, and broad room/campfire resolution load in order. Origin and cell resolution, scope/query normalization, bounded hints, room and campfire site normalization, authoritative client-hint validation, diagnostic records, room fallback, world-target fallback, and public `ValidateClientSite`/`Resolve` behavior remain unchanged. Largest provider is below `4,000` tokens; semantic camp-site, client-hint, companion hint, camp-task, command-adapter, camp-zone/movement, communities, group-camp, bootstrap, sleep, seating, and MP server-guard checks pass `13/13`, provider parsing, function-contract, and diff checks pass. The server inventory tripwire now expects the measured `941` files. Exact detector reports `2,840` scanned, `48` over `4,000`, `19` excluded; the next hotspot is `PNC_BehaviorThreatGuard_Transitions.lua` at `4,913` estimated tokens. Full-suite final zero-over-threshold validation remains pending.

## Chunk 294 — ThreatGuard transition providers
`PNC_BehaviorThreatGuard_Transitions.lua` now remains the shared transition composition root while scene handoff/release helpers, target refresh and audit logic, and combat avoidance/engagement transitions load in order. Zombie group alerts, target retention, conversation travel holds, animation scene interruption, seating/threat audits, immediate and companion target resolution, alert refresh, attack gating, avoidance, combat-target ownership, facility wake coordination, and public transition contracts remain unchanged. Largest provider is below `4,000` tokens; threat guard, scene handoff, human-NPC threat, immediate threat, seated threat, reassessment, combat stance/commitment, companion defense, live travel, and travel-hold checks pass `15/15`, provider parsing, function-contract, and diff checks pass. Exact detector reports `2,843` scanned, `47` over `4,000`, `19` excluded; the next hotspot is `PNC_SocialEventHooks_DownedDistress.lua` at `4,880` estimated tokens. Full-suite final zero-over-threshold validation remains pending.

## Chunk 295 — Downed-distress hook providers
`PNC_SocialEventHooks_DownedDistress.lua` now remains the guarded hook composition root while shared listener/debounce state, resolver input construction, and bounded delivery/public health hooks load in order. Flavor-layer load-order fallback, hearing and line-of-sight checks, attacker/faction/relationship attribution, ownership signals, wound summaries, per-NPC cooldowns, call/update/repeat events, network payload construction, graceful degradation, and debug reset behavior remain unchanged. Largest provider is below `4,000` tokens; incapacitated flavor, social event, leader-loss, medical, bootstrap, and MP server-guard checks pass `10/10`, provider parsing, function-contract, and diff checks pass. The server inventory tripwire now expects the measured `944` files. Exact detector reports `2,846` scanned, `46` over `4,000`, `19` excluded; the next hotspot is `PNC_Combat_Engagement.lua` at `4,879` estimated tokens. Full-suite final zero-over-threshold validation remains pending.

## Chunk 296 — Combat engagement providers
`PNC_Combat_Engagement.lua` now remains the shared engagement composition root while decision/audit helpers, melee and ranged lane arbitration, and the live engagement tick load in order. Ranged audit sampling, debug state, distance refresh, retreat clearing, weapon fallback/restoration, tactical prechecks, formation-aware melee approach, shove pressure, ranged spacing, hidden-target investigation, traversal and stance holds, attack-action pumping, mixed-loadout switching, and public `CombatEngagement.Tick` behavior remain unchanged. Largest provider is below `4,000` tokens; combat behavior, ranged engagement, melee arbitration, stance/tactical, companion attack, immediate/seated threat, scene handoff, travel hold, and profiler checks pass `11/11`, provider parsing, function-contract, and diff checks pass. Exact detector reports `2,849` scanned, `45` over `4,000`, `19` excluded; the next hotspot is `PNC_CampResourceService_Activity.lua` at `4,870` estimated tokens. Full-suite final zero-over-threshold validation remains pending.

## Chunk 297 — Camp activity providers
`PNC_CampResourceService_Activity.lua` now remains the guarded activity composition root while target application and sleep/seat/water acquisition, stale activity target re-resolution, and replacement/order lifecycle cleanup load in order. Activity target projection, reservation metadata, floor-seat and world-water fallbacks, live/abstract revalidation, materialization handoff, lease updates, reservation replacement, order transitions, cache attachment, and public activity methods remain unchanged. Largest provider is below `4,000` tokens; camp resource modules, sleep, seating, zone, work-release, hydration, need-trigger, bootstrap, and MP server-guard checks pass `10/10`, provider parsing, function-contract, and diff checks pass. The server inventory tripwire now expects the measured `947` files. Exact detector reports `2,852` scanned, `44` over `4,000`, `19` excluded; the next hotspot is `PNC_NeedFacilityEffects.lua` at `4,860` estimated tokens. Full-suite final zero-over-threshold validation remains pending.

## Chunk 298 — Need-facility effect providers
`PNC_NeedFacilityEffects.lua` now remains the guarded effects composition root while shared activity timing and reporting helpers, world-water/refill transactions, and primitive/personal/need/health/recreation effects load in order. Water-source rehydration, abstract-camp hydration, bottle refill commit behavior, retry reporting, personal-item consumption, fatigue/rest, health recovery, recreation recovery, and the public `NeedFacilityEffects.Tick` contract remain unchanged. The largest provider is below `4,000` tokens; need-facility, hydration effects/policy/refill, camp sleep/zone, manual activity, tasking, survival animation, profiler, and MP server-guard checks pass `15/15`, provider parsing and function-contract checks pass. The server inventory tripwire now expects the measured `950` files. Exact detector reports `2,855` scanned, `43` over `4,000`, `19` excluded; the next hotspot is `PNC_UniqueNPCRegistry.lua` at `4,859` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 299 — Unique NPC registry providers
`PNC_UniqueNPCRegistry.lua` now remains the guarded registry composition root while shared authority/selection helpers, definition diagnostics, reservation lifecycle, and reconciliation/debug maintenance load in order. Unique-pool selection, deterministic identity seeds, reservation/commit/release/rollback transitions, death marking, authored/runtime diagnostic snapshots, reconciliation, and the public registry methods remain unchanged. The largest provider is below `4,000` tokens; unique-NPC, appearance, debug model/window, editor, transfer, and MP server-guard checks pass `8/8`, provider parsing and function-contract checks pass. The server inventory tripwire now expects the measured `954` files. Exact detector reports `2,859` scanned, `42` over `4,000`, `19` excluded; the next hotspot is `PNC_SocialFlavorPresentation.lua` at `4,851` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 300 — Social flavor presentation providers
`PNC_SocialFlavorPresentation.lua` now remains the stable client composition root while shared identity/medical context, player speech and conversation-safety enqueueing, and delivery/diary/UI lifecycle providers load in order. Medical request state, player speech recipient limits, identity privacy, safety interruption priority, diary writes, conversation history updates, LLM hooks, and the existing receive coordinator remain unchanged. The largest provider is below `4,000` tokens; conversation safety, nameplate speech, player speech, social flavor, and greeting presentation checks pass `8/8`, provider parsing and function-contract checks pass. Exact detector reports `2,862` scanned, `41` over `4,000`, `19` excluded; the next hotspot is `PNC_SemanticDialogueLocalResponse.lua` at `4,823` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 301 — Semantic local-response providers
`PNC_SemanticDialogueLocalResponse.lua` now remains the stable response composition root while catalog/context helpers, read-only time/weather/identity/location text, question-context state, and branch-specific response resolution load in order. Legacy fallback registration, response catalog selection, social history interpretation, question delegation, gift/identity/gossip/hostility/self-state branches, and the public `LocalResponse.Resolve` contract remain unchanged. The largest provider is below `4,000` tokens; semantic dialogue, inventory dialogue, question, response-catalog, and state-response checks pass `6/6`, provider parsing and function-contract checks pass. Exact detector reports `2,866` scanned, `40` over `4,000`, `19` excluded; the next hotspot is `PNC_AnimationScenes_Lifecycle.lua` at `4,787` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 302 — Animation-scene lifecycle providers
`PNC_AnimationScenes_Lifecycle.lua` now remains the shared lifecycle composition root while scene clearing/audit helpers, blocking scene requests, and stop/interruption/surrender controls load in order. Traversal ownership protection, water-scene deferral, seating diagnostics, movement quiescing, priority replacement, activation, external bumps, Puppet Opera handoff, pool requests, and surrender controls remain unchanged. The largest provider is below `4,000` tokens; animation-scene debug, presence, scavenge, and survival-sequence checks pass `6/6`, provider parsing and function-contract checks pass. Exact detector reports `2,869` scanned, `39` over `4,000`, `19` excluded; the next hotspot is `PNC_ConversationScene_Lease.lua` at `4,782` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 303 — Conversation lease providers
`PNC_ConversationScene_Lease.lua` now remains the stable lease composition root while ownership/context helpers, conversation begin, LLM request reservation/validation, and end/pump maintenance load in order. Distance and threat gates, travel holds, parley state, player/token ownership, request expiry, topic recording, lease release, safety cleanup, and the existing scene lease methods remain unchanged. The largest provider is below `4,000` tokens; conversation scene, live animation, travel hold, authority, and semantic adapter checks pass `7/7`, provider parsing and function-contract checks pass. Exact detector reports `2,873` scanned, `38` over `4,000`, `19` excluded; the next hotspot is `PNC_RelationshipTypes.lua` at `4,782` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 304 — Relationship type providers
`PNC_RelationshipTypes.lua` now remains the stable type composition root while primitive sanitizers, interaction/journal and memory normalization, and public relationship/social-state constructors load in order. Finite-number bounds, deterministic list/map repair, interaction history, memory deduplication, entity references, personality/conduct normalization, and all public constructors remain unchanged. The largest provider is below `4,000` tokens; relationship, social-profile, relationship UI, and feedback checks pass `10/10`, provider parsing and function-contract checks pass. Exact detector reports `2,876` scanned, `37` over `4,000`, `19` excluded; the next hotspot is `PNC_NPCVoiceTriggers.lua` at `4,765` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 305 — NPC voice trigger providers
`PNC_NPCVoiceTriggers.lua` now remains the stable client trigger composition root while snapshot/state helpers, playback and trigger-rule arbitration, live observation, and death/explicit-emission/reset providers load in order. Deterministic voice seeds, health/damage and stamina transitions, trigger matching/cooldowns/chance, body lookup, death playback, explicit emit, and reset behavior remain unchanged. The largest provider is below `4,000` tokens; NPC voice, combat audio, and voice gateway checks pass `5/5`, provider parsing and function-contract checks pass. Exact detector reports `2,880` scanned, `36` over `4,000`, `19` excluded; the next hotspot is `PNC_AnimationSceneDebugWindow.lua` at `4,716` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 306 — Animation-scene debug window providers
`PNC_AnimationSceneDebugWindow.lua` now remains the stable client window composition root while UI creation/layout, catalog and target state, detail projection, and actions/render/window lifecycle providers load in order. Scene catalog filtering, live runtime/client detail rows, debug transport routes, pool controls, overlays, XML handoff, responsive layout, and the existing `WindowAPI.Open` contract remain unchanged. The largest provider is below `4,000` tokens; animation-scene debug route and UI checks pass `2/2`, provider parsing and function-contract checks pass. Exact detector reports `2,884` scanned, `35` over `4,000`, `19` excluded; the next hotspot is `PNC_SemanticDialoguePolicy.lua` at `4,686` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 307 — Semantic dialogue policy providers
`PNC_SemanticDialoguePolicy.lua` now remains the stable policy composition root while fallback/catalog setup, request and identity/gift classifiers, response/decision helpers, and public process flow load in order. Command action vocabulary, confidence thresholds, unresolved-entity safeguards, fuzzy confirmation, gift consent, intent branching, local response composition, and `DialoguePolicy.Decide`/`Process` remain unchanged. The largest provider is below `4,000` tokens; semantic route, dialogue, NLU, fuzzy, gift, item, social, fact, inventory, entity, and reference checks pass `11/11`, provider parsing and function-contract checks pass. Exact detector reports `2,888` scanned, `34` over `4,000`, `19` excluded; the next hotspot is `PNC_MapLayer_Communities.lua` at `4,648` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 308 — Community map layer providers
`PNC_MapLayer_Communities.lua` now remains the stable map-layer composition root while site/relation geometry, rendering and hover presentation, and vacant-site claims/map registration load in order. Visibility authorization, community selection by site, faction relation coloring, radius/bounds drawing, hover cards, travel marker interaction, vacant-site sorting, claim actions, and the existing map hook remain unchanged. The largest provider is below `4,000` tokens; community map, debug, and world-discovery map checks pass `5/5`, provider parsing and function-contract checks pass. Exact detector reports `2,891` scanned, `33` over `4,000`, `19` excluded; the next hotspot is `PNC_SemanticDialogueSituation.lua` at `4,636` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 309 — Semantic dialogue situation providers
`PNC_SemanticDialogueSituation.lua` now remains the stable situation composition root while bounded source/rule normalization, activity and need projection, emotional/relationship/health projection, and public build/rule registration load in order. Activity precedence, bounded needs and condition values, semantic labels, relationship attitude, conversation continuity, world signals, rule limits, and the public `DialogueSituation.Build` contract remain unchanged. The largest provider is below `4,000` tokens; situation, dialogue input, inventory, local-route, and social checks pass `7/7`, provider parsing and function-contract checks pass. Exact detector reports `2,895` scanned, `32` over `4,000`, `19` excluded; the next hotspot is `PNC_AnimationSceneDefinitions.lua` at `4,634` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 310 — Animation scene definition shards
`PNC_AnimationSceneDefinitions.lua` now remains the stable catalog composition root while base/social, facility, and ambient/survival registration shards load in order. Scene IDs, definitions, step sequences, priorities, interruption policy, facility callbacks, roaming callbacks, sleep variants, hydration/eating scenes, and registration order remain unchanged. The largest provider is below `4,000` tokens; animation, survival, roaming, debug, need-facility, and hydration checks pass `8/8`, provider parsing and function-contract checks pass. Exact detector reports `2,898` scanned, `31` over `4,000`, `19` excluded; the next hotspot is `PNC_WorkshopCatalog_Rebuild.lua` at `4,598` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 311 — Workshop catalog rebuild providers
`PNC_WorkshopCatalog_Rebuild.lua` now remains the stable returned rebuild API while station/skill helpers and cell/control actions, queue/craft/salvage row builders, and final workshop build orchestration load in order. Station availability, skill/station sorting, quantities, facility-build handoff, queue controls, recipe/salvage rows, localization, and the parent catalog integration remain unchanged. The largest provider is below `4,000` tokens; workshop catalog and crafting presence checks pass `2/2`, provider parsing and function-contract checks pass. Exact detector reports `2,901` scanned, `30` over `4,000`, `19` excluded; the next hotspot is `PNC_Nameplates.lua` at `4,594` estimated tokens. Full-suite and final zero-over-threshold validation remain pending.

## Chunk 312 — Final nameplate and roster providers
`PNC_Nameplates.lua`, client roster commands, and nameplate presentation now keep their stable public paths while settings/overlay state, roster snapshots/sync/deltas, and presentation status/actions/display providers load behind them. Nameplate settings, overlay toggles, roster snapshots and retries, sync chunks/deltas, status colors, action labels, speech metrics, and public UI contracts remain unchanged. Focused nameplate, combat-overlay, roster, network-scale, relationship-feedback, speech, and tool-feedback checks pass.

## Chunk 313 — World discovery and needs UI providers
World-discovery radio context/actions and the needs debug window now use stable composition roots with helper/template/persistence, radio/contact, and core/actions/lifecycle providers. Radio template context, introduction persistence, ambient/scan/contact actions, needs controls, responsive layout, debug authorization, and refresh behavior remain unchanged. Focused world-discovery/radio, colonist UI, and needs-debug checks pass.

## Chunk 314 — Profiler, translation, and facility action providers
The profiler shared installation, translation bootstrap segments, and settlement facility actions now delegate wrapper/sampler, segment registration, and area/build/anchor behavior through small providers. Installation boundaries, sampler markers, translation registration, facility selectors, build requests, anchor assignment, failure feedback, and public APIs remain unchanged. Focused profiler, translation, facility-builder, anchor, and settlement overlay checks pass.

## Chunk 315 — Conversation, aggro, and lumber providers
Conversation groups, client zombie aggro, lumber tools, and lumber trees now retain their public roots while addressing/camp/submit, targeting/update, canonical/abstract/live/diagnostic tools, and tree access/scan/claim providers load in order. Group response routing, pursuit ownership and update contracts, tool canonicalization, tree claims, deferred removal, and lumber work adapters remain unchanged. Focused semantic-group, multiplayer aggro, zombie pursuit, lumber service/executor/progress/work-adapter, and map-command checks pass.

## Chunk 316 — Remaining world, diagnostics, and debug providers
World-discovery actions, performance-scaling audit logging, community and faction-member debug windows, semantic social catalog, telemetry prompt, and need-facility triggers now use stable roots with focused providers. Radio actions, diagnostic channels/build/state logs, UI selection/render/lifecycle behavior, social catalog registration, prompt queues, need-facility routing/recovery, inventory wakeups, and task-provider registration remain unchanged. Focused world-discovery, diagnostics, community/faction UI, semantic-social, telemetry, needs, and supply checks pass. Newly added server providers retain the standard `AllowsServerCode()` guard.

## Chunk 317 — Final over-threshold source slices
The last over-limit files were split into bounded providers: facility surface sleep/seating behavior, facility activity runtime/order payload construction, perception debug core/actions/lifecycle, zombie aggro safety/pursuit effects, corpse-haul helpers/corpses/destinations, nameplate combat-debug rendering, PBrainZ context helpers/build, social damage recorders, faction mobile normalization, relationship graph rendering, and NPC trait definition shards. Public functions were preserved across each original path; focused suites pass for every affected subsystem.

## Chunk 318 — Repository-root tooling and harness providers
The repository-root audit found two remaining in-scope hotspots that the earlier mod-only scan did not cover: `tools/generate_pnc_player_animation_debug_catalog.lua` at `8,149` estimated tokens and `tools/semantic_harness/lua/worker/SemanticAdapters.lua` at `4,040`. The generator now keeps its stable command-line entry and deterministic output while loading configuration (`586`), source parsing/resolution (`1,964`), bridge policy (`1,925`), bridge emission (`998`), and catalog serialization (`3,315`) providers; the entry is `265` tokens. The harness keeps the `worker/SemanticAdapters` require path and public identity, relationship, and configure methods while loading identity (`362`), core state (`2,309`), transport (`830`), and knowledge (`909`) providers; the entry is `161` tokens. Generator CLI arguments, catalog shape, bridge naming/deduplication, output ordering, semantic PNC namespaces, transport records, conversation leases, identity disclosure, command routing, and optional LLM fallback remain unchanged. Server-only downed-distress spokes retain guarded compatibility wrappers while shared provider implementations load through regular `require` paths. The machine-readable [token ledger](PROJECT_HOOMANS_TOKEN_LEDGER_2026-10.csv) records original and final estimates for `847` changed source/data paths. Baseline-generator equivalence and deterministic synthetic generation pass; focused harness, animation, leader-loss, and multiplayer server-guard checks pass; full Lua parsing, Kahlua verification, and `git diff --check` pass.

## Final checkpoint — 2026-10-01
The authoritative repository-root scan uses threshold `4000`, chars/token `4`, and excludes `Manuals,Debug,tests`. It reports `3,010 scanned`, `0 over`, and `804 excluded`. All authored, generated, and tooling files in the configured scan are at or below the hard maximum. Full-repository Lua parsing passes, PZ Kahlua verification reports `0` errors and `0` warnings across `2,873` mod files, the full existing suite passes `783/783`, and the multiplayer server-file guard passes. The working-tree diff passes `git diff --check`; the existing cached staged refactor retains `69` blank-line-at-EOF findings.
