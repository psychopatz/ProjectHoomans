---
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "L1"
chunk: "Lazy Core -> Hoomans promotion/demotion"
retrieval_tier: "verify"
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
participant_repos: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
next_phase: "L2"
updated_at: "2026-11-19T20:49:21.796748Z"
checkpoint_mode: "committed_handoff"
phase_commit: "self"
phase_commit_phase: "L1"
phase_commit_message: "phase(L1): phase(L1): implement lazy Core-to-Hoomans promotion, reversible demotion, and sparse ActorExtension authority"
phase_commit_vector: "psychopatz-core=2fc8e5e8c237caa9507a93272896cf87b75e295a;project-hoomans=self;dynamic-trading=2b66a9583fcbe3d9e915b6c16ab9d6851d053eab"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
---



# Session Handoff

## L1 Closed
- Added lazy incremental 32-tile `_spatialIndex`, `QueryNearPosition` / `HasActiveActor` / `GetExtension` / `ListWithExtension` / `ListMaterialized`, and identity-unchanged `Commit()` fast path in `psychopatzCore` `PsychopatzActorRegistry` / `PsychopatzActors`.
- Replaced eager bulk `HydrateCoreActors()` with `RestoreActiveCoreActors`, bounded interest promotion (`CORE_PROMOTE_MAX_PER_REFRESH = 4`), idempotent `PromoteCoreActor`, `HasActiveHoomansResponsibility` (ignoring standby `GuardAnchor` / `HuntNearestPlayer` without active orders/combat/facilities), reversible `DemoteCoreActor`, and bounded `PumpDemotions`.
- Established `actor.extensions["ProjectHoomans.ActorExtension"]` (`schemaVersion = 1`) via `PNC_CoreActorExtension.lua` as the single sparse durable extension authority (0 bytes for unmodified bystanders; Core-backed records skip legacy `PNC_npc_<id>` ModData and legacy directory dirtying).
- Updated presence override (`DebugForceLive` / `DebugRelease`), unique NPCs, abstract/mobile groups, and `StartingCompanionService` to preserve canonical Core actor IDs without eager promotion or duplication.
- Verified with simulator & benchmarks (`N=100` & `N=500` `OFF`: `startProm=0`, `Promoted=9`, `DirtyEnd=0`, `serAttempts=18` vs L0 `600/3000`; `DEPART`: `9 -> 0`; `MASS40`: bounded promotion/materialization; `N=100 vs N=300` bit-identical operational counts) plus full focused regression suites across both repos.

## Next Chunk
- **L2 — single-authority persistence and deferred physical flush:** Remove duplicate Core-domain serialization and Core-appearance-vs-`schemaVersion==2` nil retry; classify serializer/flush outcomes (`WRITTEN`, `TERMINAL_OR_NOT_APPLICABLE`, `RETRYABLE_FAILURE` with bounded retry/backoff); decouple logical `PersistenceCoordinator.Commit()` from synchronous `GlobalModData.save()` and whole-registry `MarkSnapshotChanges()` via dirty-domain queueing and a coalescing persistence pump (full drain on `OnSave`/shutdown).
