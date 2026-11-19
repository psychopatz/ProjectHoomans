# Agent Runbook — Lightweight NPC Runtime

## Startup

1. Read root `AGENTS.md` in ProjectHoomans and psychopatzCore before editing either repository.
2. Re-verify branch, HEAD, upstream/worktrees and dirty/staged/untracked state. Preserve unrelated work.
3. Read this job's `PROGRESS.md`, then `HANDOFF.md`, then only the active ROADMAP/ARCHITECTURE sections.
4. Read PsychopatzCore `Docs/survivor_world_runtime/README.md`, `ARCHITECTURE.md`, `COMPACT_PERSISTENCE.md`, and current `PROGRESS.md` as the canonical compact-world ownership contract.
5. Treat `SurvivorWorldAuthorityMigration` eager hydration as a superseded transitional implementation detail, not a new invariant.
6. Treat NPCReplicationScaling P1-P4 as accepted protocol work. Change it only when an L3 regression requires a minimal compatible extension.
7. Use exact current source/tests as authority. Do not implement from this audit by filename assumption alone.

## First evidence targets

ProjectHoomans:

- `PNC_Server_Lifecycle.lua`
- `PNC_CoreSurvivorWorldAdapter.lua`
- `PNC_Persistence_CoreProvider.lua`
- `PNC_Registry_LoadDirty.lua`
- `PNC_Registry_StorageCore.lua`
- `PNC_PersistenceCoordinator.lua`
- `PNC_Persistence_Serialize.lua`
- `PNC_Network_Server_Broadcasts.lua`
- `PNC_Network_Server_RosterInterest.lua`
- `PNC_Server_RecordProcessing.lua`
- existing promotion/runtime-view/provider tests

PsychopatzCore:

- `PsychopatzProfiler.lua`
- `PsychopatzProfilerPZAdapter.lua`
- profiler feature registry/bootstrap/config tests
- ActorRegistry/ActorPersistence/ActorProvider/SurvivorWorld contracts

## Performance measurement rule

Never optimize from one deeply instrumented number.

For every performance claim record exact commit/worktree state, scenario and actor/live/zombie counts, whether profiler was OFF/coarse/deep, sample duration/tick count, mean plus tail/peak or another stated distribution, and instrumentation limitations.

Use deep wrappers only for short attribution windows after a clean baseline shows a problem.

## Persistence safety rule

Do not "fix" nil serialization by coercing Core appearance into the retired Hoomans appearance schema. That would preserve duplicate authority.

Instead establish the correct Core-backed persistence boundary. Tests must prove Core canonical domains survive restart, Hoomans-owned extension survives restart, unchanged abstract actors create no Hoomans persistence work, terminal/not-applicable serialization cannot remain infinitely dirty, retryable I/O/serialization failure retries with bounded backoff, and OnSave drains required state without losing unrelated dirty data.

## Lazy-promotion rule

A map/roster/portrait query is not permission to create a Hoomans runtime record. Prefer canonical Core projection.

Every promotion trigger must name the Hoomans responsibility that requires rich state. Every demotion must release scheduler/spatial/body/runtime references and retain canonical identity.

Do not whole-registry poll Core every tick to discover promotion. Use existing interest/provider events and bounded spatial/provider seams.

## Network rule

Before adding a packet, inspect current negotiated capability, incarnation, revision and fallback contracts. Extend the existing record-sync protocol rather than creating a parallel bus.

A domain delta must be smaller and semantically narrower than the full snapshot. A delta that cannot safely converge must fall back to the existing full current baseline.

## Validation

Prefer existing focused smoke/native-harness tests and add explicit regressions for the defects in AUDIT.md. Run touched-subsystem tests first, then the repository's normal full developer suite/baseline gates before accepting a phase.

Do not delete or weaken unrelated failing tests to make the new goal green. Label existing baseline failures separately.

## Git/phase closure

At an accepted developer-side phase: reconcile ROADMAP/PROGRESS/HANDOFF, stage only exact phase-owned paths, commit participant repository changes first, commit ProjectHoomans primary/job docs last with HANDOFF, verify the committed vector and remaining unrelated work, then continue automatically to the next mandatory phase.

Never push, create PRs/tags/releases, amend/rebase/force-update, or publish Steam Workshop content without explicit authorization.
