---
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "L3"
chunk: "Domain-delta replication"
retrieval_tier: "verify"
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
participant_repos: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
next_phase: "L4"
updated_at: "2026-11-19T21:19:00.663687Z"
checkpoint_mode: "committed_handoff"
phase_commit: "self"
phase_commit_phase: "L3"
phase_commit_message: "phase(L3): route mutation events to narrow domain deltas with incarnation, revision-gap repair, and mixed-capability fallback"
phase_commit_vector: "psychopatz-core=2fc8e5e8c237caa9507a93272896cf87b75e295a;project-hoomans=self;dynamic-trading=2b66a9583fcbe3d9e915b6c16ab9d6851d053eab"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
---





# Session Handoff

## L3 Closed
- Added `PNC_NetworkSnapshots_DomainDeltas.lua` (`BuildCombatStateDelta`, `BuildHealthWoundsDelta`, `BuildEquipmentDelta`, `BuildDomainDelta`, `ResolveEventDeltaKind`, `StampDomainMetadata`) and explicit `deltaKind` tags across `presence`, `combat_damage`, `combat_state`, `health_wounds`, `equipment`, and `full` snapshots while preserving `NPCReplicationScaling` P1–P4 lean `portraitRef` vs inline `portrait` negotiation and wrapping the 3 new delta builders in coarse profiler boundaries (`13 <= 15` total).
- Negotiated `DOMAIN_DELTA_PROTOCOL = 1` via `CMD_FULL_SYNC_REQUEST` (`NetworkCommands.lua`, `PNC_ClientRequests_Bootstrap.lua`, `PNC_ServerCharacterReplicationCommandHandler.lua`, `PNC_Network_Server_Portraits.lua`) and partitioned broadcast recipients in `PNC_Network_Server_Broadcasts.lua` so modern clients receive narrow domain deltas and legacy clients lazily receive full fallback snapshots.
- Enforced `replicaIncarnation` and per-domain `domainRevision`/`baseDomainRevision` monotonicity on the client (`PNC_ClientRosterCommands_{Snapshots,Deltas,Sync}.lua`) with stale/older-incarnation drops and 1s-throttled targeted `CMD_REQUEST_RECORD_REPAIR` convergence (`Network.SendRecordRepair`).
- Verified across `pnc_lightweight_domain_delta_replication_smoke.lua`, `pnc_lightweight_runtime_simulation_smoke.lua` (`FullSnapshots: 157 -> 18` in `OFF`, `NET_DLT` fallback+repair convergence pass), `tests/benchmarks/npc_replication.lua` (P1–P4 pass), `tests/benchmarks/lightweight_npc_runtime.lua` (`N100/N500 FullSnap=18`), 11 focused Lua suites, `luac -p`, and `pz_verify.py --kahlua --severity WARNING` (`0` errors/warnings, zero `next()` calls).

## Next Chunk
- **L4 — measured runtime cadence and allocation optimization:** Capture a fresh clean profiler-OFF/coarse breakdown after L0–L3, eliminate the measured extra per-NPC/non-census zombie scans (`extraZScans=102`), re-audit hot paths (`FollowOwner`, stamina, body cleanup/audit, census/spatial, zombie aggro, materialization, scheduler) using existing throttles/caches/budgets, and verify zero responsiveness regressions with measurable improvement against clean L0/L3 baselines.
