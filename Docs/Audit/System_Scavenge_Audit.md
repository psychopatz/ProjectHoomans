# Scavenge System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 88.2 |
| Architecture pressure | 20.2 |
| Graph coverage score | 71.2 |
| Evidence confidence | 57.3 |
| Production files | 20 |
| Production LOC | 2402 |
| Rule findings | 1 (1 high, 0 medium, 0 low) |
| Fan-in / fan-out | 3 / 2 |

## Next-phase disposition

Participates in a UI cycle. Separate service/action execution from window state, rendering, and status refresh so UI consumes snapshots instead of driving domain work.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-952C4DA277` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: Scavenge -> UI -> Scavenge |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 8188 | 803 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Scavenge/PNC_ScavengeWindow.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


