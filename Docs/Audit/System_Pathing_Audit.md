# Pathing System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 69.1 |
| Architecture pressure | 36.1 |
| Graph coverage score | 78.5 |
| Evidence confidence | 63.7 |
| Production files | 18 |
| Production LOC | 8362 |
| Rule findings | 15 (0 high, 15 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Main NPC traversal hotspot. The companion NPC_Traversal_Refactor_Audit.md has deeper findings. Split query/planning, motion execution, door/window interaction, native body control, and debug visualization while preserving the action/fence state machine and load order.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-B02C57D6F6` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | Potential unbounded loop in Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_VehicleAvoidance.lua. |
| `ARC-0CC8E7E74C` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua has 1090 code lines; review responsibility density. |
| `ARC-C77890DC7D` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_TraversalQuery.lua has 881 code lines; review responsibility density. |
| `ARC-D9CAB72F7F` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua has 1130 code lines; review responsibility density. |
| `ARC-235E33C8F5` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PathService.Pump spans 478 lines. |
| `ARC-291C2A4C7A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.updateTraversalAction spans 173 lines. |
| `ARC-3B2802244A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | FakeLocomotion.StepTowardGoal spans 279 lines. |
| `ARC-492A940991` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.consumeMoveIntent spans 140 lines. |
| `ARC-6709B9C271` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.ensureMoveLane spans 136 lines. |
| `ARC-7175C54441` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.repairInvalidBodyPosition spans 134 lines. |
| `ARC-A19719929D` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.updateActiveMove spans 357 lines. |
| `ARC-AC61D87996` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.tryDoorOrWindowInteraction spans 480 lines. |
| `ARC-B3EEEE5E3F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Planner.Pump spans 277 lines. |
| `ARC-D14A09349C` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.beginTraversalAction spans 146 lines. |
| `ARC-FEC418A93A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Planner.GetSteeringTarget spans 133 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-D9CAB72F7F` | 1130 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua | — |
| Large module | `ARC-0CC8E7E74C` | 1090 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua | — |
| Large module | `ARC-C77890DC7D` | 881 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_TraversalQuery.lua | — |
| Large function | `ARC-AC61D87996` | 480 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Interactions.lua:279 | Internal.tryDoorOrWindowInteraction |
| Large function | `ARC-235E33C8F5` | 478 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua:650 | PathService.Pump |
| Large function | `ARC-A19719929D` | 357 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua:214 | Internal.updateActiveMove |
| Large function | `ARC-3B2802244A` | 279 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_FakeLocomotion.lua:271 | FakeLocomotion.StepTowardGoal |
| Large function | `ARC-B3EEEE5E3F` | 277 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_EnginePathPlanner.lua:292 | Planner.Pump |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 10302 | 1248 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua |
| 9333 | 1157 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua |
| 7249 | 941 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_TraversalQuery.lua |
| 7139 | 770 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Interactions.lua |
| 5839 | 682 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Context.lua |
| 5820 | 598 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Lane.lua |
| 5080 | 676 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_EnginePathPlanner.lua |
| 4077 | 551 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_EnginePathPlanner_Context.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.
- Companion deep report: `NPC_Traversal_Refactor_Audit.md`.

## Completed work — shared traversal-action contract

**Completion date:** 2026-08-23

This pass completed the first recommended traversal slice: the duplicated
low-fence `up -> cross_pending -> cross` phase and timing policy now lives in
the pure shared `PNC.TraversalAction` contract. The scripted PathService and
client-native controller remain separate side-effecting executors.

### Files changed

Production:

- `shared/PNC/Core/Pathing/PNC_TraversalAction.lua` — new pure action creation
  and phase/timing evaluation contract.
- `shared/PNC/Core/Pathing/PNC_PathService.lua` — loads the contract before
  PathService consumers.
- `shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_TraversalRuntime.lua`
  — delegates action creation and phase evaluation while retaining scripted
  body movement, animation, interaction, and lane mutation.
- `client/PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController.lua`
  — loads the contract before native-controller consumers.
- `client/PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage.lua`
  — delegates fence phase evaluation while retaining multiplayer ownership,
  native body control, cooldowns, and retry state.

Tests:

- `tests/pnc_traversal_action_contract_smoke.lua` — native/scripted phase and
  progress parity plus evaluator purity.
- `tests/pnc_client_native_fence_passage_smoke.lua` — contract loading and a
  characterization of stable same-side/server-correction behavior.
- `tests/pnc_split_fence_traversal_smoke.lua` — missing transfer/finish event
  deadline behavior.
- `tests/pnc_window_break_traversal_smoke.lua` — explicit contract loading for
  the isolated runtime test.
- `tests/pnc_pathing_presence_boundary_smoke.lua` — provider-first PathService
  load-order contract.

Paths above are relative to `Contents/mods/ProjectHoomans/42.20/media/lua`
unless they begin with `tests/`.

### Behavior and compatibility preserved

- Public functions remain unchanged: `Internal.beginTraversalAction`,
  `Internal.updateTraversalAction`, `Controller.UpdateWindowSmash`, and
  `Controller.TryNativePassage` are compatibility executors/wrappers.
- Existing action phases, state keys, animation variables, profile timings,
  50 ms transition settle, lane fields, finish reasons, SP/MP ownership split,
  engine invalidation, body control, cooldowns, and retry fields are retained.
- No save format, network payload, engine API call, or unrelated production
  file changed.

### Before/after architecture metrics

The current architecture-audit CLI groups this repository as one `PNC`
subsystem, so its whole-project baseline/diff is reported alongside direct
Pathing function measurements rather than compared with the older 92-system
health score above.

| Metric | Before | After |
|---|---:|---:|
| Whole-project production findings | 131 | 128 |
| Targeted large-function findings | 3 | 0 |
| `beginTraversalAction` span | 146 lines | 100 lines |
| `updateTraversalAction` span | 173 lines | 110 lines |
| native `updateWindowSmash` span | 125 lines | 100 lines |
| Pathing call cycles | 2 | 2 |
| Graph coverage gaps in changed files | 0 recorded | 0 recorded |

The three targeted `LARGE_FUNCTION` findings resolved with no introduced
architecture findings. Existing Pathing cycles in `NavigationRouter` and
`EnginePathPlanner` were outside this slice and remain unchanged.

### Before/after token metrics

Measured with local `tiktoken 0.14.0` and `o200k_base`:

| Scope | Before | After | Delta |
|---|---:|---:|---:|
| scripted traversal runtime | 3,933 | 3,132 | -801 (-20.4%) |
| client-native passage executor | 4,402 | 4,086 | -316 (-7.2%) |
| new shared action contract | 0 | 1,056 | +1,056 |
| full shared Pathing + native-controller scope | 84,062 | 84,031 | -31 |

The total scoped code is slightly smaller, while the duplicated executor
logic dropped by 1,117 tokens and the extracted contract fits independently
in a 1,056-token context.

### Tests and validation

```text
python3 tests/run_tests.py pnc_traversal_action_contract_smoke \
  pnc_client_native_fence_passage_smoke \
  pnc_split_fence_traversal_smoke \
  pnc_traversal_route_edges_smoke pnc_door_interaction_smoke \
  pnc_native_path_stall_smoke pnc_fake_locomotion_stall_smoke
PASS 7/7

python3 tests/run_tests.py
PASS 240/240

pz_verify --kahlua (19 shared Pathing files + 9 native-controller files)
0 errors, 0 warnings

pz_verify --i18n (19 shared Pathing files)
0 hardcoded UI strings
```

The refreshed `project-hoomans` graph generation is
`2026-08-23T11:11:23Z`; all changed production/test files report no recorded
coverage issue. This remains best-effort static evidence and does not replace
an in-game SP/MP traversal session.

### Remaining risks and recommended next refactor

- Characterization exposed a pre-existing discrepancy: when a stable server
  correction keeps the native body on the approach side, the executor keeps
  returning `native_fence_climb` after `finishAt`; it does not reach the
  advertised same-side retry branch. This behavior was preserved rather than
  silently fixed during the architecture pass. Add an explicit desired-
  behavior test and fix it as a separate runtime change.
- The highest-value next architecture slice is T-02: split geometry/probing
  and suppression/progression policy from the 480-line
  `tryDoorOrWindowInteraction()` compatibility wrapper. Keep door, window,
  and fence execution adapters separate and retain all current return reasons.
- `TraversalQuery`, `PathService_Motion`, `LiveBodyControl`, and the two
  existing Pathing call cycles remain follow-up work. No in-game SP/MP smoke
  session was available in this pass.

