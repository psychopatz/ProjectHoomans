# Settlement System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 98.1 |
| Architecture pressure | 4.3 |
| Graph coverage score | 69.2 |
| Evidence confidence | 56.9 |
| Production files | 18 |
| Production LOC | 3042 |
| Rule findings | 2 (0 high, 1 medium, 1 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Separate validation/facility processing from persistence and event hooks; normalize once at the boundary.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-E457E2A6FE` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Validation.NormalizeComponent spans 138 lines. |
| `ARC-E2E6F97AA2` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Settlement/PNC_FacilityService.lua publishes events and contains a recurring hot-path signal. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 7927 | 781 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Settlement/PNC_FacilityService.lua |
| 3786 | 415 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Settlement/PNC_FacilityDefinitions.lua |
| 2904 | 305 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Settlement/PNC_FacilityValidationService.lua |
| 2513 | 251 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Settlement/PNC_BaseValidationService.lua |
| 2389 | 252 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Settlement/PNC_FacilityReservations.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


