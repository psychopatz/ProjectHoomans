# Production System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 96.7 |
| Architecture pressure | 5.4 |
| Graph coverage score | 79.5 |
| Evidence confidence | 64.6 |
| Production files | 19 |
| Production LOC | 3598 |
| Rule findings | 2 (0 high, 1 medium, 1 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Work service processing has a hot-path event risk. Separate claim lifecycle, production calculation, completion mutation, and event emission; make cancellation/release semantics explicit.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-B007FB9F54` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/PNC_WorkService.lua has 840 code lines; review responsibility density. |
| `ARC-1CF6E5A6A8` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/PNC_WorkService.lua publishes events and contains a recurring hot-path signal. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-B007FB9F54` | 840 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/PNC_WorkService.lua | — |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 8558 | 898 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/PNC_WorkService.lua |
| 4890 | 485 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/PNC_ResearchService.lua |
| 3772 | 395 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/PNC_CraftingService.lua |
| 3010 | 329 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/PNC_HomeDutyService.lua |
| 2973 | 307 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/ConstructionService/PNC_ConstructionService_Lifecycle.lua |
| 2421 | 268 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Production/PNC_RecipeCatalog.lua |
| 2013 | 195 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/ConstructionService/PNC_ConstructionService_Queueing.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


