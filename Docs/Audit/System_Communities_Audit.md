# Communities System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 88.9 |
| Architecture pressure | 10.3 |
| Graph coverage score | 57.7 |
| Evidence confidence | 47.1 |
| Production files | 7 |
| Production LOC | 2960 |
| Rule findings | 4 (0 high, 4 medium, 0 low) |
| Fan-in / fan-out | 2 / 0 |

## Next-phase disposition

Service, validation, directors, and debug snapshots mix lifecycle, registry validation, and diagnostics. Split canonical state from generation, validation, and debug projection.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-ACC16C7F7B` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunityService.lua has 1414 code lines; review responsibility density. |
| `ARC-5CD651A836` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Debug.PerformAction spans 213 lines. |
| `ARC-E235381A6C` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Validation.ValidateRegistry spans 317 lines. |
| `ARC-E7458C7209` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Debug.BuildSnapshot spans 126 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-ACC16C7F7B` | 1414 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunityService.lua | — |
| Large function | `ARC-E235381A6C` | 317 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunityValidation.lua:104 | Validation.ValidateRegistry |
| Large function | `ARC-BCF055DA60` | 221 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunityDirector.lua:206 | Director.GenerateForFaction |
| Large function | `ARC-5CD651A836` | 213 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunityDebug.lua:234 | Debug.PerformAction |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 10018 | 1494 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunityService.lua |
| 4248 | 559 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Communities/PNC_CommunityDebugWindow.lua |
| 3487 | 527 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunitySiteResolver.lua |
| 3339 | 461 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Communities/PNC_CommunityTypes.lua |
| 3133 | 472 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunityDebug.lua |
| 2774 | 429 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunityDirector.lua |
| 2318 | 427 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_CommunityValidation.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


