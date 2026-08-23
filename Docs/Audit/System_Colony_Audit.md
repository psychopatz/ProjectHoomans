# Colony System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 88.2 |
| Architecture pressure | 20.7 |
| Graph coverage score | 70.5 |
| Evidence confidence | 56.7 |
| Production files | 12 |
| Production LOC | 1928 |
| Rule findings | 1 (1 high, 0 medium, 0 low) |
| Fan-in / fan-out | 4 / 2 |

## Next-phase disposition

Coupled to Inventory through the composition graph. Isolate colony state and lifecycle from inventory transfer and UI concerns; make cross-system operations explicit commands.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-71235C8519` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> Colony -> Inventory -> (composition) |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 3582 | 387 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Production.lua |
| 3154 | 374 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_SourceAdapters.lua |
| 3030 | 310 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Deposits.lua |
| 2374 | 251 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Internal.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


