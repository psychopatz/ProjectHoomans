# FactionIncident System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 90.5 |
| Architecture pressure | 7.2 |
| Graph coverage score | 54.6 |
| Evidence confidence | 44.8 |
| Production files | 1 |
| Production LOC | 800 |
| Rule findings | 3 (0 high, 3 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Incident functions combine recording and mutation. Separate normalization, storage, and downstream faction effects; keep duplicate-event handling and ordering explicit.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-31CE77B967` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionIncidentService.lua has 800 code lines; review responsibility density. |
| `ARC-898F7C4214` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Service.RecordAttack spans 252 lines. |
| `ARC-F46DDEB323` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Service.AddIncident spans 204 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-31CE77B967` | 800 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionIncidentService.lua | — |
| Large function | `ARC-898F7C4214` | 252 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionIncidentService.lua:440 | Service.RecordAttack |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 6065 | 833 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionIncidentService.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


