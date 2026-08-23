# SocialEncounterTracker System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 97.2 |
| Architecture pressure | 3.5 |
| Graph coverage score | 54.6 |
| Evidence confidence | 46 |
| Production files | 1 |
| Production LOC | 718 |
| Rule findings | 2 (0 high, 1 medium, 1 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Hot-path tracker pump. Bound work per tick and separate candidate collection, deduplication, and publication.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-D49C26D3BF` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Tracker.Pump spans 134 lines. |
| `ARC-6668AB5FFF` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_SocialEncounterTracker.lua publishes events and contains a recurring hot-path signal. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 5437 | 760 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_SocialEncounterTracker.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


