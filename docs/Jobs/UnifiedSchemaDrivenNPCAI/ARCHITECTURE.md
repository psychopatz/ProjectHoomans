# Architecture: Unified Schema- & Compiler-Driven NPC AI (`UnifiedSchemaDrivenNPCAI`)

## 1. Core Architectural Thesis

Unify selective behavioral mechanisms from *The Sims* (band-gated autonomy & smart affordances), *Façade* (pragmatic discourse acts, bounded micro-beats, global mix-ins), *GTA V / RDR2* (sensory perception cones, shocking events, agitation escalation, non-interrupting secondary reactions, scenario chains), and *RimWorld* (dirty-state reconcilers, Toil execution, reservations, thought stacking, offline Def inheritance) directly onto existing authoritative subsystems—**zero parallel AI engines, zero runtime XML parsing, and zero non-AI physics/Euphoria coupling**.

## 2. Single-Owner Authority Boundaries

| Capability / Truth | Authoritative Owner | Existing Verified Seam Extended |
| --- | --- | --- |
| Multi-IR Compiler, Offline Inheritance, Cross-IR Linker, Deterministic Lua Emitter | `psychopatzCore` | `CodeBuilder` (`tools/semantic_harness/codebuilder/targets/pz_packages.json`, `generation_ownership.py`, `generation_recipe.py`, `reconcile.py`) |
| Bounded Spatial Shocking-Event Ring Buffer | `psychopatzCore` | New opt-in capability `core.shocking_events` at `PsychopatzCore/common/media/lua/shared/PsychopatzCore/Events/PsychopatzShockingEventBus.lua` (omitted from `pack.trading_common`/`pack.trading_abstract`) |
| Portable Social Memory, Directed Relationships, Lazy Decay, Thought Stacking | `psychopatzCore` | `PsychopatzCore/common/media/lua/shared/PsychopatzCore/Actors/PsychopatzSocial.lua` (`SCHEMA_VERSION = 3`, `SCENE`/`SHORT`/`LONG`/`ANCHOR` tiers) + `social_policy_compiler.py` |
| Canonical Semantic Dialogue Families, Pragmatic Acts, Global Mix-Ins | `psychopatzCore` (engine/IR) + Adopters (packages) | `ConvoEngine v1` (S13D–S13F single-authority layout & `Index/Director.lua` closed) |
| 8-Band Semantic Precedence Arbiter & Unified Resource Claims | `ProjectHoomans` | `PNC.Tasking`, `PNC_TaskPriority`, `PNC_TaskLeaseService`, and `PNC.Tasking.Claims` (`server/PNC/Tasking/PNC_Tasking_Claims.lua`) |
| Colony Work Discovery, Zone Policy & 5-Step Dual-Executor Toils | `ProjectHoomans` | `PNC.WorkService` (`RegisterOperation`/`RegisterReconciler`), `PNC.WorkZoneService`, `PNC.WorkToilRunner`, `WorkOutputService`, `WorkInputService`, `WorkItemService` |
| Perception Cones, Reaction Policies, Sparse Agitation & Secondary Channel | `ProjectHoomans` | `PerceptionService` (extending `PNC_Perception`/`PNC_Perception_Frame`), `AgitationService`, `PNC_NetworkSnapshots_DomainDeltas`, `PNC_Presence_Abstract`/`PNC_BodyLifecycle_Reanimation` + client `PNC_Animation` / `PNC.NPCVoice.Catalog` |
| Bounded Micro-Beat Dialogue Orchestration & Joint Scene Leases | `ProjectHoomans` | `PNC/ConvoEngine/Social/Director.lua`, `PNC_DialogueMicroBeatDirector`, `PNC_JointSceneLeaseService`, `PNC_StreetInteractionService`, `PNC_SocialWitnessService`, `Interaction/SceneAdopters.lua` |
| Standalone Trader Continuity (must work with `ProjectHoomans` disabled) | `DynamicTrading` | `DTCommon_CoreActorPolicy`, `DTAbstract_CoreProvider`, `DTAbstract_CoreConversation` |

## 3. CodeBuilder Multi-IR Asset Pipeline

Rule: **One `CodeBuilder` toolchain, five typed portable IR domains, adopter-owned source packages, Core-owned compiler/runtime mechanisms.** Never force non-conversation gameplay policy into `ConvoEngine`, and never hand-edit generated Lua outputs.

1. **`ConvoEngine v1` IR (Active Canonical):** Semantic families, pragmatic discourse acts (`agree`, `disagree`, `praise`, `criticize`, `pacify`, `greet`, `antagonize`, `defuse`), 5-stage micro-beats, global mix-ins, realization styles.
2. **`SocialPolicy` IR:** Existing `psychopatz.social-policy.package.v1` / `psychopatz.social-policy.v1` pipeline (`social_policy_compiler.py`), extended in U2 with `stackLimit`, `stackedEffectMultiplier`, and `nullifyingTraits`, plus aligned generated marker header (`"do not edit by hand."` matching `reconcile.py:90`).
3. **`AutonomyAd` IR:** Facility capability ads, piecewise urgency curves, hysteresis `(enter, exit, critical)` thresholds, trait/mood intra-band weights, Situation role constraints.
4. **`ReactionPolicy` IR:** Archetype perception profiles (including precomputed `cos(fov/2)`), shocking-event `(event, archetype, relTier) -> intent` tables, agitation trigger/stage tables, secondary bark priorities.
5. **`WorkDef & Scenario` IR:** Work operations, required/forbidden capability tags, tool/input requirements, fatigue-gate flags, 5-step Toil chains, time-of-day scenario weights.

Compile-time guarantees (Phase U2):

* **Offline Inheritance:** Flatten `"abstract": true` / `"parent"` chains at compile time (no runtime metatable traversal).
* **Two-Pass Cross-IR Linker:** Fail build on any dangling reference across IRs (e.g., `ReactionPolicy` -> `ConvoEngine` act -> `SocialPolicy` memory -> `WorkDef` intent) and statically validate Build 42 `AnimSet` XML keys under `ProjectHoomans/common/media/AnimSets/` plus `PNC.NPCVoice.Catalog.Events` (`client/PNC/Audio/PNC_NPCVoiceCatalog.lua`) / optional `VoiceGateway` keys (`KnoxVox` has zero references in `psychopatzCore` and `ProjectHoomans` and is not assumed).
* **Additive Overlays & Recipe Reconciliation:** Support non-destructive JSON Patch overlays routed via `targets/pz_packages.json` and `generation_recipe.json` (`owned_fileset` + `sha256_text` fingerprints, `reconcile.py --check/--apply` clean, `activeCurrentPsdlIdentityCount = 0`). Runtime third-party Workshop mods remain dynamically discovered (`MarketSense`, loaded PZ recipes/items).

## 4. Build 42 Java Engine Ground-Truth Constraints (`pz-java-baseline`)

Verified directly from decompiled Project Zomboid Build 42 Java sources:

1. **`IsoGameCharacter.setVariable(...)` Server No-Op in MP:** In `IsoGameCharacter.java:12525-12591`, `setVariable` returns `null` (no-op) when `GameServer.server && this instanceof IsoZombie`, and `VariableSyncPacket` only replicates for local `IsoPlayer` + `VariableSyncPacket.syncedVariables`. Therefore, U4 Non-Interrupting Secondary Layer `AnimSet` state variables for NPC bodies MUST replicate via narrow server-to-client domain deltas (`PNC_NetworkSnapshots_DomainDeltas`) and apply `setVariable` on the client (or SP local).
2. **`IsoGameCharacter.faceLocationF(x, y)` Coincident-Point Guard:** `IsoGameCharacter.java:10465-10479` returns `false` and logs a `DebugType.FaceLocationFix` warning stacktrace if `diffX == 0 && diffY == 0`. All secondary gaze callers must guard against identical `(x, y)` coordinates before calling `faceLocationF`.
3. **`IsoGameCharacter.CanSee(obj)` Has No FOV/Distance Check:** `IsoGameCharacter.java:5044-5056` delegates straight to `LosUtil.lineClear(..., false) != Blocked`. Distance squared and precomputed `cos(fov/2)` azimuth pre-filtering before globally budgeted `LosUtil.lineClear` / `CanSee` is mandatory.
4. **`WorldSoundManager` Server MP Semantics:** In `WorldSoundManager.java`, dedicated `GameServer.server` does NOT populate `chunk.soundList`, and `getBiggestSoundZomb` mutates a shared singleton `resultBiggestSound`. U4 audio perception must consume `Events.OnWorldSound` / server sound hooks rather than polling `chunk.soundList`.

## 5. Runtime Execution Invariants

1. **8-Band Semantic Precedence Wall (`PNC.Tasking`):** `HARD_EMERGENCY > CRITICAL_NEED > FORCED_ORDER > NORMAL_NEED > HIGH_WORK > NORMAL_WORK > OPTIONAL > IDLE`. Intra-band trait/mood/distance scoring (`0.0..1.0`) and `SAME_BAND_MARGIN = 0.08` hysteresis never breach band walls. Hard cap: `MAX_CANDIDATES_PER_PROVIDER = 64`.
2. **Unified Resource Claims (`PNC.Tasking.Claims`):** Server-authoritative TTL/owner/lease-indexed claim table auto-released by `PNC_TaskLeaseService_Release` and `PNC_Tasking_Assignment` rollback, bridged across Work/WorkZone/Lumber/CorpseHaul.
3. **Orthogonal Non-Interrupting Secondary Channel:** Stationary `faceLocationF` (coincident-guarded), client-applied Build 42 `AnimSet` variables (`setVariable` via narrow domain delta), and speech-priority-gated barks (with recent-line decay and recycle/demotion cleanup) execute without cancelling active `PNC.TaskLeaseService` leases.
4. **Dual-Executor Live/Abstract Parity:** `PNC.Tasking`, `WorkToilRunner`, `PsychopatzSocial`, and `ConvoEngine` evaluate identical compiled plans for Live and Abstract actors and invoke identical authoritative domain mutations (`WorldEffectService` for unloaded tiles).
5. **Shared Server-Authoritative SP/MP Path:** `client request -> server validates -> server mutates -> domain delta replicated`. Clients never run authoritative perception, agitation, work, or social writes, and private social graphs never replicate broadly.
6. **Performance Complexity Contract (`LightweightNPCRuntime` Aligned):**
   * Compact `SurvivorWorld` storage: `O(N)` (`O(1)` idle tick)
   * Promoted Hoomans actors: `O(L)` via single lazy promotion/demotion seam
   * Live perception/agitation/combat: `O(live)` with activity-sensitive cadence, local squared-distance + cosine pre-filter, globally budgeted `LosUtil.lineClear`/`CanSee` queue, and lazy-decay agitation/memory
   * Tasking & Work reconcilers: `O(dirty)` bounded per-pump slices (zero `IsoCell` or standalone `Events.OnTick` polling loops)
   * Persistence: `O(dirty domains)` deferred coalesced flush (zero synchronous `GlobalModData.save()` on routine mutations)
   * Networking: `O(interested recipients * changed domains)` domain-delta sync
7. **Observability & Failure Containment:** Debug OFF incurs effectively zero recurring overhead; Colonists Debug GUI exposes active band, top candidates + rejection reasons, perception clues/LOS budget, agitation stage, and secondary channel state. Faults in `ConvoEngine`, `Agitation`, or optional `PBrainZ` degrade locally without breaking combat, inventory, or tasking.
