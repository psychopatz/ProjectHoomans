# PersistenceCoordinator System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 97.7 |
| Architecture pressure | 2.5 |
| Graph coverage score | 57.7 |
| Evidence confidence | 47.1 |
| Production files | 1 |
| Production LOC | 182 |
| Rule findings | 1 (0 high, 1 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Keep commit orchestration thin over persistence codecs; make transaction ordering and failure handling explicit.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-8FD0F155E0` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Coordinator.Commit spans 145 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

No token-bloat candidate matched the subsystem path heuristic.

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


