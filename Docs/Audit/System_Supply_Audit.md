# Supply System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 98 |
| Architecture pressure | 6.9 |
| Graph coverage score | 67.9 |
| Evidence confidence | 55.9 |
| Production files | 9 |
| Production LOC | 1434 |
| Rule findings | 2 (0 high, 1 medium, 1 low) |
| Fan-in / fan-out | 1 / 4 |

## Next-phase disposition

Supply processing has a hot-path event risk. Keep calculations pure and bounded, then isolate mutation, scheduling, and event publication.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-D321034C2E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Service.Process spans 176 lines. |
| `ARC-4A9D290636` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Supply/PNC_NPCSupplyService.lua publishes events and contains a recurring hot-path signal. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 4369 | 481 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Supply/PNC_NPCSupplyService.lua |
| 3147 | 378 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Supply/PNC_SupplyInventory.lua |
| 2329 | 250 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Supply/PNC_ItemUtility.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


