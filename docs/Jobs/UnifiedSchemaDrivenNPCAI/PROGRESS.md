# Progress: UnifiedSchemaDrivenNPCAI

Parent goal: IN PROGRESS
Current phase: Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze

Accepted:

* Cross-game architectural synthesis (Sims, Façade, GTA V/RDR2 behavioral reactivity, RimWorld work/Defs) and Adopt/Adapt/Reject ownership specification approved.
* Canonical job documentation drafted under `docs/Jobs/UnifiedSchemaDrivenNPCAI/`.

Current evidence:

* Architectural design grounded in prior workspace audits (`PNC.Tasking`, `NeedFacilityTriggers`, `ConvoEngine v1`, `LightweightNPCRuntime`, `Portable Social State`, `ModularWorkFoundationAndFarming`).
* Live Git HEADs: VERIFIED on disk for all three repositories (main; worktrees clean). Prerequisite phase states: NOT YET SOURCE-VERIFIED.

Known gap:

* Prerequisite roadmaps (`LightweightNPCRuntime`, `Portable Social State`, `ModularWorkFoundationAndFarming`) must be checked against actual current HEADs before locking implementation order for U1–U5.
* Line-level internals of `PNC_SocialEventHooks_CombatAdapter_Awareness.lua`, `SceneAdopters.lua`, `PNC_AmbientFacilityService.lua`, combat executors, and Build 42 `AnimSets` require read-only `codebase-memory-mcp` inspection.

Next Chunk: Chunk U0A — Run read-only workspace discovery across `ProjectHoomans`, `psychopatzCore`, and `DynamicTrading` to record verified HEAD/worktree fingerprints, audit live status of prerequisite jobs, inspect high-pressure target modules, and freeze the Phase U1–U6 manifest.

Immediate acceptance:

* Verified HEAD/branch/status table stamped into `HANDOFF.md` and `ROADMAP.md`.
* Source-verified prerequisite readiness report (which phases of L0–L5, P0–P9, and F1–F5 are already complete vs. open).
* Frozen non-overlapping file-ownership manifest ready for Phase U1/U2 execution.
