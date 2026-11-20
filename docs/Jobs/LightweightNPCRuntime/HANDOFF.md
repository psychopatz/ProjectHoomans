---
state: "USER_ACCEPTANCE"
parent_status: "USER_ACCEPTANCE"
phase: "L6-live-follow-combat-abstract-travel-inventory-stutter"
chunk: "L6 developer gates complete — native SP/MP profiler-OFF user acceptance"
retrieval_tier: "verify"
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
participant_repos: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
next_phase: "USER_ACCEPTANCE"
updated_at: "2026-11-20T02:22:00Z"
checkpoint_mode: "phase_committed"
phase_commit: "pending_commit"
phase_commit_phase: "L6-live-follow-combat-abstract-travel-inventory-stutter"
phase_commit_message: "phase(L6): add four-family and combined L6 runtime harness, stutter trace, and measured follow/combat optimizations"
phase_commit_vector: "psychopatz-core=9fdc6b7548f4179ce498836e498933be9c861cd6;project-hoomans=pending"
residual_worktree_fingerprint: "clean"
---

# Session Handoff — Lightweight NPC Runtime (L6 Developer Gates Complete)

## Summary

All developer-side **L6** gates (four isolated workload families, profiler-OFF pre-fix baselines, evidence-backed runtime fixes, off-by-default bounded stutter diagnostic ring, and the mandatory 12-scenario cross-system composition matrix) pass alongside all accepted **L0–L5**, **Core-backed recruitment**, and **NPCReplicationScaling** gates. The parent objective is ready for user-owned native SP/MP profiler-OFF feel verification.

## Measured Causes & Evidence-Backed Fixes

1. **Trait catalog deep-copy on hot companion ticks (`PNC_NPCTraitRegistry.lua`, `PNC_NPCTraitEffects.lua`, `PNC_ConditionStats.lua`):**
   - Profiling `FOLLOW_WALK_OPEN n=6` measured `Traits.GetDefinitions()` deep-copying the entire catalog as ~40% of live follow tick CPU.
   - Added read-only `Traits.GetDefinitionsView()` cached by `Traits.Revision` and switched hot simulation readers to it while preserving `Traits.GetDefinitions()` for mutable callers.
2. **Unnecessary inventory hydration on no-op lease release (`PNC_Equipment_Leases.lua`):**
   - `ReleasePrimaryLease()` called `EnsureRecordInventory(record)` on every follow movement tick even when `"combat"` held no lease.
   - Added a fast-path no-op return when `not state.entries[owner] and type(record.inventory) == "table"`.
3. **30-second periodic `player_identity_bound` party path reset & FullSnapshot storm (`PNC_FactionBehavior_OrderPlanning.lua`):**
   - `desiredOrder()` omitted existing `ORDER_FOLLOW` metadata, causing periodic 30s lifecycle sweeps to reset `PathService`, mark dirty 3x, wake all 6/12 companions into one tick, and broadcast `FullSnapshot`s for the whole party.
   - Preserved unchanged player `ORDER_FOLLOW` specs when `ownerUsername` and `ownerOnlineID` match.
4. **Synchronized MP moving-target replan bursts (`PNC_EnginePathPlanner_Steering.lua`, `PNC_EnginePathPlanner_Context_RoutePolicy.lua`):**
   - Moving-target replans previously bypassed `ConsumeRequestBudget(now)` on MP authority (`maxFrEng=6` at `n=6`, `12` at `n=12`).
   - Enforced `ConsumeRequestBudget(now)` for moving-target replans with MP authority capped at `math.max(2, ENGINE_PATH_REQUEST_BUDGET_PER_WINDOW)` per window (`maxFrEng` dropped `6 -> 2` and `12 -> 2` without increasing `n=6` follow lag).
   - Combined Family A result (`FOLLOW_WALK_OPEN n=6`, profiler OFF): `tickAvg 4.678ms -> 1.65–1.74ms (-64%)`, `p95 10.503ms -> 2.78–2.95ms (-73%)`, `psReset 12 -> 6`, `maxFrEng 6 -> 2`.
5. **Synchronized NPC -> player combat sync fan-out & global witness scans (`PNC_CombatResolution_Player.lua`, `PNC_Server_Tick.lua`, `PNC_Server_SubsystemPumps.lua`, `PNC_SocialEventHooks_DamageAdapter_Recorders_Player.lua`):**
   - Authoritative body-part damage/wounds remain immediate; native `BodyDamage:Update()` and `sendPlayerStatsChange(player)` now coalesce to once per damaged player per server tick inside `Server.OnTick` (flushed in `FinishTick`, immediate outside ticks).
   - `COMBAT_NPC_PLAYER_HIT n=6 sync=Y rounds=6`: `36` authoritative hits applied, `BodyDamage:Update()` and `sendPlayerStatsChange()` dropped `36 -> 6` (-83%); at `n=12 rounds=4`: `48 -> 4` (-92%).
   - `RecordPlayerHurtWitnesses` now queries `PNC.SpatialIndex.QueryNPCs(px, py, WITNESS_RADIUS)` when built (with `Registry.ForEachLive` fallback) and coalesces distinct attackers within the same tick while preserving per-attacker `witness_cooldown`.
6. **Off-by-default bounded stutter diagnostic ring (`PNC_StutterTrace.lua`, `PNC_SharedComposition_Foundation.lua`, `PNC_Server_Tick.lua`):**
   - Zero-wrapper, allocation-light ring buffer (`RingCapacity=32`, `MaxSpikeWindows=8`, `PreWindowFrames=3`, `PostWindowFrames=3`, default `ThresholdMs=16`, `Enabled=false`).
   - Native verification usage: `PNC.StutterTrace.SetEnabled(true, 16)` then `PNC.StutterTrace.FormatRecentSpikes()`.

## Verified Developer Gates

- `lua tests/pnc_stutter_trace_smoke.lua`: PASS
- `lua tests/pnc_lightweight_runtime_simulation_smoke.lua`: PASS (L0–L5 + `COMBINED_MATERIALIZE_COMBAT` + `PLAYER_FAST_INTEREST_JUMP`)
- `lua tests/pnc_lightweight_runtime_l6_smoke.lua`: PASS (Families A/B/C/D + `OBSERVATION_PROJECTION_LOAD`)
- `lua tests/benchmarks/lightweight_npc_runtime.lua`: PASS (`ALL L5 + L6 BENCHMARK MATRIX ASSERTIONS PASSED`, Sections A–F + G1–G5 including all 12 combined scenarios and `LONG_WORLD_ENDURANCE`)
- `lua tests/benchmarks/npc_replication.lua 1 patch`: PASS
- `python3 tests/run_tests.py --jobs 8`: `1080/1084` PASS (only the 4 pre-existing unrelated baseline failures: `pnc_animation_scene_debug_routes_smoke`, `pnc_context_debug_smoke`, `pnc_population_director_smoke`, `pz_custom_translation_manager_smoke`)
- Kahlua2 static check on all modified/created production Lua files: CLEAN
- Root-owned paths: `ProjectHoomans=0`, `psychopatzCore=0`

## Next Step (User-Owned)

Run native Project Zomboid SP/MP gameplay verification with profiler **OFF** (optionally enabling `PNC.StutterTrace.SetEnabled(true, 16)` if capturing any native-engine-specific frame spike).
