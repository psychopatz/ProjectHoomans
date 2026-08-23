# Behaviors System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 96.4 |
| Architecture pressure | 6.6 |
| Graph coverage score | 78.5 |
| Evidence confidence | 62.7 |
| Production files | 21 |
| Production LOC | 2891 |
| Rule findings | 2 (0 high, 2 medium, 0 low) |
| Fan-in / fan-out | 2 / 1 |

## Next-phase disposition

Follow-owner logic contains large tick/target-resolution functions. Split target selection, intent generation, and movement execution; keep ticks bounded.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-01EB4CD9D8` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.TickFollowOwner spans 351 lines. |
| `ARC-0F383ADB5B` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.ResolveHordeAwareFollowTarget spans 131 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large function | `ARC-01EB4CD9D8` | 351 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner.lua:13 | Internal.TickFollowOwner |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 6099 | 874 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionBehavior.lua |
| 2958 | 315 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Facilities/PNC_FacilityJobs_Behavior.lua |
| 2781 | 333 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Behaviors/PNC_Behavior_Treatment.lua |
| 2621 | 364 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowOwner.lua |
| 2423 | 304 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Behaviors/PNC_Behavior_Roaming.lua |
| 2164 | 265 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Behaviors/PNC_Behavior_Targeting.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


