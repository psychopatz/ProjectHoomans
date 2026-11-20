# Architecture: Unified Schema- & Compiler-Driven NPC AI (`UnifiedSchemaDrivenNPCAI`)

## 1. Core Architectural Thesis

Unify selective behavioral mechanisms from *The Sims* (band-gated autonomy & smart affordances), *Façade* (pragmatic discourse acts, bounded micro-beats, global mix-ins), *GTA V / RDR2* (sensory perception cones, shocking events, agitation escalation, non-interrupting secondary reactions, scenario chains), and *RimWorld* (dirty-state WorkGivers, Toil execution, reservations, thought stacking, offline Def inheritance) directly onto five existing authoritative subsystems—**zero parallel AI engines, zero runtime XML parsing, and zero non-AI physics/Euphoria coupling**.

## 2. Single-Owner Authority Boundaries

| Capability / Truth | Authoritative Owner | Existing Seam Extended |
| --- | --- | --- |
| Multi-IR Compiler, Offline Inheritance, Cross-IR Linker, Deterministic Lua Emitter | `psychopatzCore` | `CodeBuilder` (`targets/pz_packages.json`, `generation_ownership.py`) |
| Bounded Spatial Shocking-Event Ring Buffer | `psychopatzCore` | New reusable mechanism (`ShockingEventBus`) |
| Portable Social Memory, Directed Relationships, Lazy Decay, Thought Stacking | `psychopatzCore` | `PsychopatzSocial` (`SCENE`/`SHORT`/`LONG`/`ANCHOR` tiers) |
| Canonical Semantic Dialogue Families, Pragmatic Acts, Global Mix-Ins | `psychopatzCore` (engine/IR) + Adopters (packages) | `ConvoEngine v1` |
| 8-Band Semantic Precedence Arbiter & Target/Supply Reservations | `ProjectHoomans` | `PNC.Tasking`, `PNC_TaskPriority`, `PNC.Tasking.Claims` |
| Colony Work Discovery, Zone Policy & 5-Step Dual-Executor Toils | `ProjectHoomans` | `PNC.WorkService`, `WorkZoneService`, `WorkToilRunner` |
| Perception Cones, Reaction Policies, Sparse Agitation & Secondary Channel | `ProjectHoomans` | `Awareness` / `PerceptionService`, `AgitationService`, `LiveExecutor` |
| Bounded Micro-Beat Dialogue Orchestration & Joint Scene Leases | `ProjectHoomans` | `SemanticSocialConversationDirector`, `SceneAdopters.lua` |
| Standalone Trader Continuity (must work with ProjectHoomans disabled) | `DynamicTrading` | `DTCommon_CoreActorPolicy`, `DTAbstract` |

## 3. CodeBuilder Multi-IR Asset Pipeline

Rule: **One `CodeBuilder` toolchain, five typed portable IR domains, adopter-owned source packages, Core-owned compiler/runtime mechanisms.** Never force non-conversation gameplay policy into `ConvoEngine`, and never hand-edit generated Lua outputs.

1. **`ConvoEngine v1` IR (Active Canonical):** Semantic families, pragmatic discourse acts (`agree`, `disagree`, `praise`, `criticize`, `pacify`, `greet`, `antagonize`, `defuse`), 5-stage micro-beats, global mix-ins, realization styles.
2. **`SocialPolicy` IR:** Memory templates, retention tiers, `stackLimit`, `stackedEffectMultiplier`, `nullifyingTraits`, half-lives, consolidation thresholds, provenance tags.
3. **`AutonomyAd` IR:** Facility capability ads, piecewise urgency curves, hysteresis `(enter, exit, critical)` thresholds, trait/mood intra-band weights, Situation role constraints.
4. **`ReactionPolicy` IR:** Archetype perception profiles (including precomputed `cos(fov/2)`), shocking-event `(event, archetype, relTier) -> intent` tables, agitation trigger/stage tables, secondary bark priorities.
5. **`WorkDef & Scenario` IR:** Work operations, required/forbidden capability tags, tool/input requirements, fatigue-gate flags, 5-step Toil chains, time-of-day scenario weights.

Compile-time guarantees:

* **Offline Inheritance:** Flatten `"abstract": true` / `"parent"` chains at compile time (no runtime metatable traversal).
* **Two-Pass Cross-IR Linker:** Fail build on any dangling reference across IRs (e.g., `ReactionPolicy` -> `ConvoEngine` act -> `SocialPolicy` memory -> `WorkDef` intent) or Build 42 `AnimSet` / `VoxForge` key drift.
* **Additive Overlays:** Support non-destructive JSON Patch overlays routed via `targets/pz_packages.json` while runtime third-party Workshop mods remain dynamically discovered (`MarketSense`, loaded PZ recipes/items).

## 4. Runtime Execution Invariants

1. **8-Band Semantic Precedence Wall (`PNC.Tasking`):** `HARD_EMERGENCY > CRITICAL_NEED > FORCED_ORDER > NORMAL_NEED > HIGH_WORK > NORMAL_WORK > OPTIONAL > IDLE`. Intra-band trait/mood/distance scoring (`0.0..1.0`) and `SAME_BAND_MARGIN = 0.08` hysteresis never breach band walls. Hard cap: `MAX_CANDIDATES_PER_PROVIDER = 64`.
2. **Orthogonal Non-Interrupting Secondary Channel:** Stationary `faceLocationF`, Build 42 `AnimSet` state variables (`character:setVariable`), and conversation-priority-gated barks (with recent-line decay) run without tearing down primary `PNC.TaskLeaseService` leases.
3. **Dual-Executor Live/Abstract Parity:** `PNC.Tasking`, `WorkToilRunner`, `PsychopatzSocial`, and `ConvoEngine` evaluate identical compiled plans for Live and Abstract actors and invoke the exact same authoritative domain mutations (`WorldEffectService` for unloaded tiles).
4. **Shared Server-Authoritative SP/MP Path:** `client request -> server validates -> server mutates -> domain delta replicated`. Clients never run authoritative perception, agitation, work, or social writes, and private social graphs never replicate broadly.
5. **Performance Complexity Contract (`LightweightNPCRuntime` Aligned):**
* Compact `SurvivorWorld` storage: `O(N)` (`O(1)` idle tick)
* Promoted Hoomans actors: `O(L)` via single lazy promotion/demotion seam
* Live perception/agitation/combat: `O(live)` with activity-sensitive cadence, local squared-distance + cosine pre-filter, globally budgeted Java `CanSee`/`LosUtil` queue, and lazy-decay agitation/memory
* Tasking & WorkGivers: `O(dirty)` bounded per-pump slices (zero `IsoCell` or per-tick haulable scans)
* Persistence: `O(dirty domains)` deferred coalesced flush (zero synchronous `GlobalModData.save()` on routine mutations)
* Networking: `O(interested recipients * changed domains)` domain-delta sync


6. **Observability & Failure Containment:** Debug OFF incurs effectively zero recurring overhead; Debug ON exposes active band, top candidates + rejection reasons, perception clues/LOS budget, agitation stage, and secondary channel state. Faults in `ConvoEngine`, `Agitation`, or optional `PBrainZ` degrade locally without breaking combat, inventory, or tasking.
