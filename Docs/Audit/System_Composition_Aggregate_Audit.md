# (composition) System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P1`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 61.1 |
| Architecture pressure | 54.3 |
| Graph coverage score | 77.2 |
| Evidence confidence | 63.8 |
| Production files | 7 |
| Production LOC | 467 |
| Rule findings | 4 (3 high, 1 medium, 0 low) |
| Fan-in / fan-out | 3 / 3 |

## Next-phase disposition

An aggregate composition cluster rather than one source directory. Use it as a migration map for the Composition, Conversation, UI, Colony, and Inventory cycles; do not create another catch-all dependency bucket.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-0EDF6D6B17` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> Conversation -> UI -> (composition) |
| `ARC-C8B9D83754` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> (composition) |
| `ARC-FC2F389B9F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> Colony -> Inventory -> (composition) |
| `ARC-D88AB9E97F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | processRecord spans 120 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 2267 | 154 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Composition/PNC_SharedComposition.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


