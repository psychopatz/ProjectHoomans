# FactionBehavior System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 93 |
| Architecture pressure | 5.4 |
| Graph coverage score | 54.6 |
| Evidence confidence | 44.8 |
| Production files | 1 |
| Production LOC | 833 |
| Rule findings | 2 (0 high, 2 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Return intents rather than mutating faction state directly; keep policy separate from scheduling and execution.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-81699DC5B6` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionBehavior.lua has 833 code lines; review responsibility density. |
| `ARC-379E95413B` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Behavior.ResolveIntent spans 161 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-81699DC5B6` | 833 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionBehavior.lua | — |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

No token-bloat candidate matched the subsystem path heuristic.

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


