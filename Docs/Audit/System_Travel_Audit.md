# Travel System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 98.2 |
| Architecture pressure | 3.9 |
| Graph coverage score | 78.5 |
| Evidence confidence | 62.7 |
| Production files | 8 |
| Production LOC | 1978 |
| Rule findings | 1 (0 high, 1 medium, 0 low) |
| Fan-in / fan-out | 1 / 1 |

## Next-phase disposition

Small footprint but cycle-prone directory/projection logic. Keep travel projection read-only and route mutation behind a narrow service.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-D4EA8CEAFB` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Directory.GetProjected spans 126 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 5100 | 659 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Travel/PNC_Travel_Service.lua |
| 2559 | 342 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Travel/PNC_TravelDirectory.lua |
| 2041 | 273 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Travel/PNC_Travel_Model.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


