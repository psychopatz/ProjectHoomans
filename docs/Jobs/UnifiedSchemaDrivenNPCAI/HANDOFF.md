# Handoff: UnifiedSchemaDrivenNPCAI

State: PLAN_READY_HEADS_VERIFIED_PREREQUISITES_PENDING
Parent goal status: IN PROGRESS
Primary repository: /home/psychopatz/Zomboid/Workshop/ProjectHoomans
Participant repositories:

* /home/psychopatz/Zomboid/Workshop/psychopatzCore (required: CodeBuilder Multi-IR, ShockingEventBus, PsychopatzSocial)
* /home/psychopatz/Zomboid/Workshop/DynamicTrading (compatibility guard: standalone Core + DTCommon + DTAbstract)
Branch: main (verified in all participant repositories)
Baseline HEADs (before this documentation-only commit):
* ProjectHoomans: `69959a2c8d09f53e9a714e1c3656753f69b7b41f`
* psychopatzCore: `e7149129f10da87c28b56d6359aac3ff461eba09`
* DynamicTrading: `2b66a9583fcbe3d9e915b6c16ab9d6851d053eab`
Current phase: Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze
Current chunk: Chunk U0A

What was verified:

* Cross-game AI triage (Sims, Façade, GTA V/RDR2 behavioral reactivity, RimWorld work/Defs) and 5-IR CodeBuilder design approved by user.
* Live read-only Git check: all three repositories on `main` with clean worktrees at the baseline HEADs above; prerequisite phase completion remains unverified.
* Architecture and roadmap aligned to existing `PNC.Tasking`, `WorkToilRunner`, `PsychopatzSocial`, `ConvoEngine v1`, and `LightweightNPCRuntime` invariants.

What changed this session:

* Created canonical job documentation under `ProjectHoomans/docs/Jobs/UnifiedSchemaDrivenNPCAI/` (`ARCHITECTURE.md`, `ROADMAP.md`, `PROGRESS.md`, `AGENT_RUNBOOK.md`, `HANDOFF.md`).

Current failure/blocker:

* None; awaiting live Stage 0 / Chunk U0A repository inspection to verify prerequisite roadmap status (`LightweightNPCRuntime`, `Portable Social State`, `ModularWorkFoundationAndFarming`) before production edits.

Worktree:

* Relevant paths: `docs/Jobs/UnifiedSchemaDrivenNPCAI/*`
* Unrelated paths: Preserve all existing unrelated dirty/untracked files across all three repos untouched.

Exact resume action:

1. Verify live `git status`, branch, `HEAD`, and active PZ build directory across `ProjectHoomans`, `psychopatzCore`, and `DynamicTrading`.
2. Stamp verified HEADs into `HANDOFF.md` and check completion state of `LightweightNPCRuntime`, `Portable Social State`, and `ModularWorkFoundationAndFarming`.
3. Run read-only `codebase-memory-mcp` discovery on awareness, `SceneAdopters`, ambient services, combat executors, `CodeBuilder`, and Build 42 `AnimSets`.
4. Freeze the Phase U1–U6 ownership manifest and proceed automatically through accepted phases.
