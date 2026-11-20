# Roadmap: Unified Schema- & Compiler-Driven NPC AI

## Parent Objective

Deliver a modular, schema- and compiler-driven NPC AI and asset production architecture across `psychopatzCore` and `ProjectHoomans` (preserving standalone `DynamicTrading`/`DTAbstract` compatibility) that synthesizes Sims-style band-gated autonomy, RimWorld-consistent colony labor, GTA V/RDR2 behavioral environment reactivity, and Façade-inspired micro-beat dialogue while strictly maintaining Build 42 Kahlua performance budgets, Live/Abstract parity, and SP/MP server authority.

## Why

Current NPC autonomy, colony chores, ambient loops, reactivity, and authoring definitions remain partially split across standalone Lua tables and polling services (`AmbientFacilityService`, `RoamAmbientService`, legacy chore loops, monolithic awareness hooks). Expanding NPC immersion without offline compilation, unified dirty-state providers, and strict `O(L)`/`O(live)` scaling would degrade frame pacing and create cross-mod maintenance drift.

## Verified Baseline & Hard Prerequisites (Verify Fresh in Phase U0)

* `PNC.Tasking` (8-band precedence, `SAME_BAND_MARGIN = 0.08`, 64-candidate cap), `NeedFacilityTriggers`, `ConvoEngine v1` (470 families / 396 reconciled targets), and `SemanticSocialConversationDirector` (D0–D8) exist in `ProjectHoomans`/`psychopatzCore`.
* **Prerequisite Active Roadmaps (audit live completion status in U0 before dependent phases):**
* `LightweightNPCRuntime` (L0–L5): required before reactive AI load (U4) to guarantee clean profiler-OFF baselines, lazy Core promotion, deferred persistence, and domain-delta replication.
* `Portable Social State` (P0–P9): required before U3/U4/U5 social features to guarantee single-authority `PsychopatzSocial` tiered lazy-decay storage and `SocialPolicy IR`.
* `ModularWorkFoundationAndFarming` (F1–F5): directly integrated as Phase U1.



## Non-Goals

* No Euphoria ragdoll physics, physics-bone combat, or procedural motion-matching engines.
* No parallel AI controller, second relationship history store, or runtime XML/XPath parser.
* No global Aristotelian story-arc Drama Manager or distributed ABL multi-agent negotiation planner.
* No mandatory LLM dependency (entire system operates deterministically with zero LLM calls; `PBrainZ` remains optional surface rephrasing only).
* No artificial NPC population cap reductions to mask scaling defects.

## Phases & Acceptance Gates

### Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze

* **Purpose:** Verify live Git state (`ProjectHoomans`, `psychopatzCore`, `DynamicTrading`), audit real completion state of prerequisite jobs (`LightweightNPCRuntime`, `Portable Social State`, `ModularWorkFoundationAndFarming`), inspect high-pressure modules (`PNC_SocialEventHooks_CombatAdapter_Awareness.lua`, `SceneAdopters.lua`, `PNC_AmbientFacilityService.lua`, `PNC_CommunityExcursionService.lua`, Build 42 `AnimSets`), and freeze the cross-repo Phase U1–U6 manifest.
* **Acceptance Gate:** Source-verified prerequisite table and frozen file-ownership manifest recorded; zero speculative claims; zero production edits during U0.

### Phase U1 — RimWorld Work Foundation Unification (`ModularWorkFoundationAndFarming` Closure)

* **Dependencies:** U0.
* **Responsibilities:** Verify/complete `WorkDefinitions`, `WorkItemService`, `WorkInputService`, `WorkOutputService`, `WorkZoneService`, and 5-step `WorkToilRunner` backed by `PNC.Tasking.Claims`; migrate Farming, Lumber, Fishing, and CorpseHaul onto dirty-state `WorkGivers` with Live/Abstract parity and automated claim cleanup on abort.
* **Acceptance Gate:** All four colony chores run through `WorkService` + `WorkToilRunner` with zero standalone polling loops or hardcoded `isFarmer` gates; focused work/farming/hauling smoke tests pass; Live/Abstract mutations converge identically.

### Phase U2 — `CodeBuilder` Multi-IR Expansion (`psychopatzCore` Primary)

* **Dependencies:** U0, `ConvoEngine` S12 closure, `SocialPolicy IR` (P3) contract alignment.
* **Responsibilities:** Extend `CodeBuilder` with offline `abstract`/`parent` flattening, two-pass cross-IR symbol validation, JSON Patch overlays, deterministic SHA-256 reconciliation, and flat Lua emitters for `AutonomyAd IR`, `ReactionPolicy IR`, and `WorkDef & Scenario IR` routed via `targets/pz_packages.json`. Add static validation for Build 42 `AnimSet` variable keys and `KnoxVox` bark keys.
* **Acceptance Gate:** Compiler unit tests prove inheritance flattening, dangling cross-IR reference failure, deterministic output, clean `reconcile` (`missing=0, drifted=0, stale=0, ambiguous=0`), `activeCurrentPsdlIdentityCount = 0`, and zero regressions to the 470-family `ConvoEngine v1` closure.

### Phase U3 — Sims Band-Gated Autonomy & Co-Presence Unification

* **Dependencies:** U1, U2 (`AutonomyAd IR`), `PsychopatzSocial` read seam.
* **Responsibilities:** Refactor `PNC_AmbientFacilityService`, `PNC_RoamingSeatService`, and `PNC_RoamAmbientService` into registered `OPTIONAL`/`IDLE` `PNC.Tasking` providers; wire compiled `AutonomyAd IR` curves, hysteresis locks, failure cooldowns, and intra-band trait/mood/distance scoring; add lightweight Co-Presence Situations submitting bounded social opportunities into `SceneAdopters.lua`; wire auto-satisfy hydration at lazy promotion; expose full diagnostics in Colonists Debug GUI.
* **Acceptance Gate:** Zero bypassed 5-second `Registry.ForEach` ambient loops; intra-band scoring never overrides higher semantic bands; Colonists Debug GUI displays active band, top candidates, modifiers, and rejection reasons at zero cost when Debug OFF.

### Phase U4 — GTA V / RDR2 Behavioral Reactivity & Secondary Channel

* **Dependencies:** U2 (`ReactionPolicy IR`, `WorkDef & Scenario IR`), U3, `LightweightNPCRuntime` (L0–L3).
* **Responsibilities:** Implement bounded spatial `ShockingEventBus` in `psychopatzCore`; implement activity-sensitive `PerceptionService` (local squared-distance + precomputed cosine azimuth filter, globally budgeted `CanSee`/`LosUtil` queue, `WorldSoundManager` hooks) and bounded `ClueMemory` last-known-position search; wire compiled `ReactionPolicy IR` decision tables and non-lethal shocking-event providers (`StopAndAssess`, `BackAway`, `Investigate`, `WarnGroup`, `SmartFlee`); implement sparse lazy-decay `AgitationService` (loitering front/behind/vehicle, bump, weapon draw); wire time-of-day scenario chaining; build orthogonal Non-Interrupting Secondary Layer (`faceLocationF`, Build 42 `AnimSets` variables, speech-priority-gated barks with line-exhaustion decay and recycle/demotion audio cleanup).
* **Acceptance Gate:** Zero per-tick world-tile scans or decay loops; alerted NPCs investigate clues rather than tracking through walls; secondary gaze/barks never cancel active `PNC.Tasking` leases; SP/MP server authority and domain-delta replication verified.

### Phase U5 — Façade-Inspired Dialogue Director & RDR2 Street Interaction

* **Dependencies:** U2, U3, U4, `Portable Social State` (P2/P4/P7).
* **Responsibilities:** Build deterministic zero-LLM Dialogue Director atop `ConvoEngine v1` and `SemanticSocialConversationDirector`: 5-stage micro-beats (`transition_in`, `body`, `local_or_global_mixin`, `wait_with_timeout`, `transition_out`), ephemeral local scene tension tracking, causally independent global mix-in interruptions, atomic server-owned `JointSceneLease` (2–4 participants with listener secondary reactivity and emergency abort cleanup), RDR2-style `GREET`/`ANTAGONIZE`/`DEFUSE` pragmatic acts linked to `AgitationService`, and witness-only `PsychopatzSocial` memory/hearsay propagation.
* **Acceptance Gate:** Multi-NPC scenes and player `GREET`/`ANTAGONIZE`/`DEFUSE` flows execute deterministically with zero LLM calls; global mix-ins cleanly interrupt/interleave; unobserved events never leak into non-witness memories; `Core + DTCommon + DTAbstract` continues passing with `ProjectHoomans` disabled.

### Phase U6 — Cross-Tier Scale Proof, Diagnostics & Harness Acceptance

* **Dependencies:** U1–U5, `LightweightNPCRuntime` L4/L5 benchmarks.
* **Responsibilities:** Run full unit, compiler, production-Lua harness, Colonists Debug GUI, and `pz-runtime-harness` JVM suites across the L5 scale matrix (small live party + large abstract `SurvivorWorld`, dense crowd entry/exit, shocking-event combat bursts, sustained colony farming/hauling, co-presence micro-beats, save/reload, reconnect/domain repair, profiler-OFF vs. coarse capture). Reconcile all architecture and system map docs.
* **Acceptance Gate:** Complexity targets (`O(N)` storage, `O(L)` promoted, `O(live)` perception/AI, `O(dirty)` work/persistence, domain-delta MP replication) verified under clean profiler-OFF baselines; zero mandatory verifier findings; parent marked `READY FOR USER LIVE TEST` for native SP/MP acceptance.
