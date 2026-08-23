# Director System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 98.3 |
| Architecture pressure | 5.2 |
| Graph coverage score | 81.5 |
| Evidence confidence | 65 |
| Production files | 36 |
| Production LOC | 6000 |
| Rule findings | 1 (0 high, 1 medium, 0 low) |
| Fan-in / fan-out | 1 / 1 |

## Next-phase disposition

Generation and combat resolution are broad orchestration functions. Keep directors as coordinators and move policy/calculation into pure services.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-55AA9C9BE4` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Combat.Resolve spans 126 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 6028 | 563 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Director/Population/PNC_PopulationDirector.lua |
| 4819 | 347 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Director/PNC_DirectorDebugModel.lua |
| 4161 | 352 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Director/PNC_DirectorConfig.lua |
| 4146 | 420 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Director/PNC_AbstractWorldTypes.lua |
| 4136 | 448 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Director/Population/PNC_PopulationSectorManager.lua |
| 3778 | 514 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_MobileGroupDirector.lua |
| 3445 | 369 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Director/PNC_AbstractGroupManager.lua |
| 3389 | 283 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Director/PNC_AbstractEncounterResolver.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


