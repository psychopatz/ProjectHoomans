# Perception System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 95.5 |
| Architecture pressure | 3.7 |
| Graph coverage score | 54.6 |
| Evidence confidence | 43.7 |
| Production files | 2 |
| Production LOC | 1146 |
| Rule findings | 1 (0 high, 1 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Large module with a compact surface. Separate sensing/input normalization from scoring and observation publication.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-5533AD6464` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Perception/PNC_Perception.lua has 950 code lines; review responsibility density. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-5533AD6464` | 950 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Perception/PNC_Perception.lua | — |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 7421 | 1022 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Perception/PNC_Perception.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


