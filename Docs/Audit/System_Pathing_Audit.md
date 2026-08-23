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


