# SocialEvent System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 95 |
| Architecture pressure | 4.4 |
| Graph coverage score | 54.6 |
| Evidence confidence | 44.8 |
| Production files | 2 |
| Production LOC | 745 |
| Rule findings | 2 (0 high, 2 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Separate eligibility checks, event construction, and side effects.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-85690F8F2F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | preflightObserver spans 129 lines. |
| `ARC-FDB1AB84ED` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | SocialEvents.Process spans 214 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

No token-bloat candidate matched the subsystem path heuristic.

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


