# Roadmap: Unified Schema- & Compiler-Driven NPC AI

## Parent Objective

Deliver a modular, schema- and compiler-driven NPC AI and asset production architecture across `psychopatzCore` and `ProjectHoomans` (preserving standalone `DynamicTrading`/`DTAbstract` compatibility) that synthesizes Sims-style band-gated autonomy, RimWorld-consistent colony labor, GTA V/RDR2 behavioral environment reactivity, and Façade-inspired micro-beat dialogue while strictly maintaining Build 42 Kahlua performance budgets, Live/Abstract parity, and SP/MP server authority.

## Why

Current NPC autonomy, colony chores, ambient loops, reactivity, and authoring definitions remain split across standalone Lua tables and bypass loops (`PNC_AmbientFacilityService`, `PNC_RoamingSeatService`, `PNC_RoamAmbientService`, `PNC_CorpseHaulService` `Events.OnTick`, `PNC_BehaviorSystem_Tick_Ownership`, monolithic `PNC_SocialEventHooks_CombatAdapter_Awareness.lua`). Unifying these behind offline compilation, unified `PNC.Tasking.Claims`, dirty-state reconcilers, and strict `O(L)`/`O(live)` scaling preserves frame pacing and eliminates cross-mod drift.

## Source-Verified Baseline & Prerequisite Readiness Matrix (Phase U0 Audit)

| Prerequisite Job | Verified Status | Completed Phases | Open / Required for Unified AI | Blocker Impact |
| --- | --- | --- | --- | --- |
| `LightweightNPCRuntime` | `USER_ACCEPTANCE` (developer-complete on `main`) | L0–L6 + Core recruitment | Native SP/MP user runtime acceptance only | None for U1–U6 |
| `Portable Social State` | `READY_FOR_USER_LIVE_TEST` (developer-complete) | P0–P12 (Core), H0–H8 (Hoomans), DT0–DT6 (DT) | Native SP/MP user playtesting only | None for U1–U6 |
| `PortableActorLifecycleGC` | `READY_FOR_USER_LIVE_TEST` (developer-complete) | L0–L9 (Core), H0–H6 (Hoomans), D0–D5 (DT) | Native SP/MP user playtesting only | None for U1–U6 |
| `CoreSemanticRelationshipFoundation` & `SemanticGenerationLifecycleCleanup` | `COMPLETE` / `USER_ACCEPTANCE` | P0–P20, G9R1–G9R5 | Native SP/MP user acceptance only | None for U1–U6 |
| `ModularWorkFoundationAndFarming` | `READY_FOR_USER_LIVE_ACCEPTANCE` (F1–F5 complete) | F1–F5 (`WorkDefinitions`, `WorkItemService`, `WorkInputService`, `WorkOutputService`, `WorkZoneService`, `WorkToilRunner`, 4 adapters; 0 `isFarmer` gates) | **Phase U1 closes remaining unification gaps:** add `PNC.Tasking.Claims`, wire all 4 chore reconcilers onto `WorkService.RegisterReconciler`, retire `CorpseHaulService` `Events.OnTick` and duplicate `LumberService.Pump` reconcile, gate legacy `"farming"` provider when `WorkService` active, add `WorkToilRunner.AbortOrder` | Closed directly in **Phase U1** |
| `ConvoEngine` S13 (`SemanticDialogueLanguageStandard`) | `IN_PROGRESS` (`psychopatzCore`) | S0–S12R2 (`activeCurrentPsdlIdentityCount = 0`, 470 families) + S13A–S13C (`reconcile --check` clean) | **S13D–S13F OPEN:** collapse duplicate `Behaviors/Director/*` + `Beats/Director/*` projections into canonical `Behavior/*` + `Beat/*`, freeze Director index metadata | **Hard gate U5a immediately before Phase U5** (`CONVERSATION_DIRECTOR_ARCHITECTURE.md` §12); does NOT block U1–U4 |
| `SemanticSocialConversationDirector` | `USER_ACCEPTANCE` (developer-complete) | D0–D8 + `SocialDirectorAudit` | Native SP/MP timing verification; future Director expansion gated on Core S13D–S13F | None for U1–U4; integrates with U5a before U5 |

### Verified Stage 0 Baseline HEADs

| Repository | Branch | Baseline HEAD at U0 Audit | Active Layer |
| --- | --- | --- | --- |
| `ProjectHoomans` (Primary) | `main` | `cbf62c1aedbb57cf486503ae707c8ca6a457e2a6` | `42.20` + `common` |
| `psychopatzCore` (Required) | `main` | `e7149129f10da87c28b56d6359aac3ff461eba09` | `42.20` + `common` |
| `DynamicTrading` (Guard) | `main` | `2b66a9583fcbe3d9e915b6c16ab9d6851d053eab` | `42.20` + `common` |

## Frozen Cross-Repo Ownership Manifest (Phases U1–U6)

Zero parallel file overlap allowed across phases or concurrent workers:

| Phase | Owner Repo(s) | Exact Owned Paths / Seams |
| --- | --- | --- |
| **U0** | `ProjectHoomans` | `docs/Jobs/UnifiedSchemaDrivenNPCAI/{ARCHITECTURE,ROADMAP,PROGRESS,AGENT_RUNBOOK,HANDOFF}.md` |
| **U1** | `ProjectHoomans` | `42.20/media/lua/server/PNC/Tasking/{PNC_Tasking.lua,PNC_Tasking_Claims.lua,PNC_TaskLeaseService_Release.lua,Tasking/PNC_Tasking_Assignment.lua,Tasking/PNC_Tasking_Pump_Reconciliation.lua,PNC_CorpseHaulService.lua,CorpseHaulService/*}`, `server/PNC/Production/{WorkService/*,WorkZoneService/PNC_WorkZoneService_Claims.lua,WorkToilRunner/*}`, `server/PNC/Farming/{PNC_FarmingWorkAdapter.lua,FarmingService/PNC_FarmingService_Provider.lua}`, `server/PNC/Fishing/PNC_FishingWorkAdapter.lua`, `server/PNC/Lumber/{PNC_LumberWorkAdapter_OrderBridge.lua,LumberService/PNC_LumberService_Runtime.lua,LumberService/PNC_LumberService_Trees_Claims.lua}`, `tests/pnc_u1_work_foundation_unification_smoke.lua`, `tests/pnc_mp_server_file_guard_smoke.lua` |
| **U2** | `psychopatzCore` -> `ProjectHoomans` (generated artifacts) | `psychopatzCore/tools/semantic_harness/codebuilder/*`, `psychopatzCore/tools/semantic_harness/tests/*`, `psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/PsychopatzSocial*.lua`, `psychopatzCore/tests/*`; generated IR outputs in `ProjectHoomans/common/media/lua/shared/PNC/...` |
| **U3** | `ProjectHoomans` | `server/PNC/Tasking/Autonomy/*`, `server/PNC/Settlement/FacilityJobs/{PNC_AmbientFacilityService.lua,PNC_LivingRoomService.lua,PNC_RoamingSeatService*,PNC_RoamAmbient*}`, `shared/PNC/Core/Behaviors/{PNC_BehaviorSystem_Tick_Ownership.lua,PNC_Behavior_Roaming_AreaMovement.lua,PNC_Behavior_AtCamp.lua,PNC_BehaviorCompanion_StaticOrders.lua}`, `server/PNC/Server/PNC_Server_SubsystemPumps.lua`, `server/PNC/ConvoEngine/Interaction/SceneAdopters.lua`, Colonists Debug UI (`client/PNC/UI/Colonist/*`, `server/PNC/Colony/ColonyManagement/*`) |
| **U4** | `psychopatzCore` first -> `ProjectHoomans` second | Core: `common/media/lua/shared/PsychopatzCore/Events/PsychopatzShockingEventBus.lua`, `Kernel/{PC_CapabilityCatalog.lua,Composition/PC_SharedComposition.lua}`. Hoomans: `shared/PNC/Core/Perception/*`, `server/PNC/Awareness/*`, `server/PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Awareness.lua`, `server/PNC/Tasking/Reactions/*`, `server/PNC/Agitation/*`, `shared/PNC/Core/Visuals/PNC_Animation*`, `server/PNC/Networking/PNC_NetworkSnapshots_DomainDeltas*`, `client/PNC/Audio/PNC_NPCVoice*`, `common/media/AnimSets/zombie/*` |
| **U5a + U5** | `psychopatzCore` -> `ProjectHoomans` -> `DynamicTrading` (S13D–S13F + Director) | S13D–S13F closure in Core/Hoomans/DT first; then `PNC/ConvoEngine/Social/*`, `server/PNC/ConvoEngine/Interaction/{SceneAdopters,JointSceneLease,DialogueDirector}*`, `server/PNC/Social/PNC_SocialGreetingService.lua`, `DTCommon`/`DTAbstract` compatibility verification |
| **U6** | `ProjectHoomans`, `psychopatzCore`, `DynamicTrading` | Verification & scale harness runs, `tests/`, `pz-runtime-harness` JVM runs, `docs/01_SYSTEM_MAP.md` & job doc closure |

## Non-Goals

* No Euphoria ragdoll physics, physics-bone combat, or procedural motion-matching engines.
* No parallel AI controller, second relationship history store, or runtime XML/XPath parser.
* No global Aristotelian story-arc Drama Manager or distributed ABL multi-agent negotiation planner.
* No mandatory LLM dependency (entire system operates deterministically with zero LLM calls; `PBrainZ` remains optional surface rephrasing only).
* No artificial NPC population cap reductions to mask scaling defects.

## Phases & Acceptance Gates

### Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze (**COMPLETE**)

* **Purpose:** Verify live Git state (`ProjectHoomans`, `psychopatzCore`, `DynamicTrading`), audit real completion state of prerequisite jobs, verify Build 42 Java ground truth via `pz-java-baseline`, and freeze the cross-repo Phase U1–U6 manifest.
* **Acceptance Gate:** Source-verified prerequisite table, Build 42 Java constraints, and frozen file-ownership manifest recorded; zero production edits during U0. (**PASSED**)

### Phase U1 — RimWorld Work Foundation Unification (**NEXT**)

* **Dependencies:** U0.
* **Responsibilities:** Implement `PNC.Tasking.Claims` (`Acquire`, `Renew`, `Release`, `ReleaseByLease`, `ReleaseByOwner`, `PruneExpired`, `GetDiagnostics`) with automatic release in `PNC_TaskLeaseService_Release` and `PNC_Tasking_Assignment` rollback; bridge station/zone/tree/corpse claims cleanly; add `WorkToilRunner.AbortOrder`; register all four colony chores (`FARMING`, `FISHING`, `LUMBER`, `CORPSE_HAUL`) onto `WorkService.RegisterReconciler`; gate/remove standalone `CorpseHaulService` `Events.OnTick`, duplicate `LumberService.Pump` reconcile call, and redundant `"farming"` Tasking provider when `WorkService` is active.
* **Acceptance Gate:** Zero standalone chore polling loops in production composition; all 4 chore reconcilers wired into `WorkService`; `PNC.Tasking.Claims` auto-releases on lease teardown; zero `isFarmer` gates; focused `work`, `farming`, `lumber`, `fishing`, `corpse`, `tasking`, `mp_server_file_guard`, and `u1_work_foundation` tests + Kahlua lint pass.

### Phase U2 — `CodeBuilder` Multi-IR Expansion (`psychopatzCore` Primary)

* **Dependencies:** U0, `SocialPolicy IR` alignment.
* **Responsibilities:** Extend `CodeBuilder` with offline `abstract`/`parent` flattening, two-pass cross-IR symbol validation, JSON Patch overlays, deterministic SHA-256 reconciliation (`reconcile.py` header fix aligned with `social_policy_compiler.py`), `SocialPolicy` extensions (`stackLimit`, `stackedEffectMultiplier`, `nullifyingTraits`), and flat Lua emitters for `AutonomyAd IR`, `ReactionPolicy IR`, and `WorkDef & Scenario IR` routed via `targets/pz_packages.json`. Add static validation for Build 42 `AnimSet` XML keys (`ProjectHoomans/common/media/AnimSets/`) and `PNC.NPCVoice.Catalog.Events` keys.
* **Acceptance Gate:** Compiler unit tests prove inheritance flattening, dangling cross-IR reference failure, deterministic output, clean `reconcile` (`missing=0, drifted=0, stale=0, ambiguous=0`), `activeCurrentPsdlIdentityCount = 0`, and zero regressions to the 470-family `ConvoEngine v1` closure.

### Phase U3 — Sims Band-Gated Autonomy & Co-Presence Unification

* **Dependencies:** U1, U2 (`AutonomyAd IR`), `PsychopatzSocial` read seam.
* **Responsibilities:** Refactor `PNC_AmbientFacilityService` (`LivingRoomService`), `PNC_RoamingSeatService`, and `PNC_RoamAmbientService` into registered `OPTIONAL`/`IDLE` `PNC.Tasking` providers; wire compiled `AutonomyAd IR` curves, hysteresis locks, failure cooldowns, and intra-band trait/mood/distance scoring; add lightweight Co-Presence Situations submitting bounded social opportunities into `SceneAdopters.lua`; wire auto-satisfy hydration at lazy promotion; expose full candidate/rejection diagnostics in Colonists Debug GUI (`taskBrainNpcID` + `aiDiagnostics` on `debug` tab).
* **Acceptance Gate:** Zero bypassed `Registry.ForEach` ambient loops; intra-band scoring never overrides higher semantic bands; Colonists Debug GUI displays active band, top candidates, claims, modifiers, and rejection reasons at zero cost when Debug OFF.

### Phase U4 — GTA V / RDR2 Behavioral Reactivity & Secondary Channel

* **Dependencies:** U2 (`ReactionPolicy IR`, `WorkDef & Scenario IR`), U3, `LightweightNPCRuntime` (L0–L3).
* **Responsibilities:** Implement bounded spatial `PsychopatzShockingEventBus` in `psychopatzCore` (`core.shocking_events`, omitted from DT packs); implement activity-sensitive `PerceptionService` (local squared-distance + precomputed `cos(fov/2)` azimuth filter, globally budgeted `LosUtil.lineClear`/`CanSee` queue, `Events.OnWorldSound` hooks) and bounded `ClueMemory` last-known-position search; wire compiled `ReactionPolicy IR` decision tables and non-lethal shocking-event providers (`StopAndAssess`, `BackAway`, `Investigate`, `WarnGroup`, `SmartFlee`); implement sparse lazy-decay `AgitationService`; wire time-of-day scenario chaining; build orthogonal Non-Interrupting Secondary Layer (coincident-guarded `faceLocationF`, domain-delta replicated + client-applied Build 42 `AnimSets` variables, speech-priority-gated barks with line-exhaustion decay and recycle/demotion audio cleanup).
* **Acceptance Gate:** Zero per-tick world-tile scans or decay loops; alerted NPCs investigate clues rather than tracking through walls; secondary gaze/barks never cancel active `PNC.Tasking` leases; SP/MP server authority and domain-delta replication verified.

### Phase U5 — S13D–S13F Prerequisite Gate + Façade-Inspired Dialogue Director & RDR2 Street Interaction

* **Dependencies:** U2, U3, U4, **`ConvoEngine` S13D–S13F closure (U5a)**, `Portable Social State`.
* **Responsibilities:**
  * **U5a:** Close `psychopatzCore` S13D–S13F across `psychopatzCore`, `ProjectHoomans`, and `DynamicTrading` (collapse duplicate `Behaviors/Director/*` and `Beats/Director/*` projections into canonical `Behavior/*` and `Beat/*`, produce Director readiness freeze report).
  * **U5b:** Build deterministic zero-LLM Dialogue Director atop `ConvoEngine v1` and `SemanticSocialConversationDirector`: 5-stage micro-beats (`transition_in`, `body`, `local_or_global_mixin`, `wait_with_timeout`, `transition_out`), ephemeral local scene tension tracking, causally independent global mix-in interruptions, atomic server-owned `JointSceneLease` (2–4 participants with listener secondary reactivity and emergency abort cleanup), RDR2-style `GREET`/`ANTAGONIZE`/`DEFUSE` pragmatic acts linked to `AgitationService`, and witness-only `PsychopatzSocial` memory/hearsay propagation.
* **Acceptance Gate:** S13D–S13F counters zero (`duplicateBehaviorProjectionBodies=0`, `duplicateBeatProjectionBodies=0`, `obsoleteDirectorProjectionCallers=0`); multi-NPC scenes and player `GREET`/`ANTAGONIZE`/`DEFUSE` flows execute deterministically with zero LLM calls; global mix-ins cleanly interrupt/interleave; unobserved events never leak into non-witness memories; `Core + DTCommon + DTAbstract` continues passing with `ProjectHoomans` disabled.

### Phase U6 — Cross-Tier Scale Proof, Diagnostics & Harness Acceptance

* **Dependencies:** U1–U5.
* **Responsibilities:** Run full unit, compiler, production-Lua harness, Colonists Debug GUI, `DynamicTrading` standalone guard, and `pz-runtime-harness` JVM suites across the scale matrix (small live party + large abstract `SurvivorWorld`, dense crowd entry/exit, shocking-event combat bursts, sustained colony farming/hauling, co-presence micro-beats, save/reload, reconnect/domain repair, profiler-OFF vs. coarse capture). Reconcile all architecture and `docs/01_SYSTEM_MAP.md` docs.
* **Acceptance Gate:** Complexity targets (`O(N)` storage, `O(L)` promoted, `O(live)` perception/AI, `O(dirty)` work/persistence, domain-delta MP replication) verified under clean profiler-OFF baselines; zero mandatory verifier findings; parent marked `READY FOR USER LIVE TEST` for native SP/MP acceptance.
