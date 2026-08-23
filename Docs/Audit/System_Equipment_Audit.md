# Equipment System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 93 |
| Architecture pressure | 5.8 |
| Graph coverage score | 54.6 |
| Evidence confidence | 44.8 |
| Production files | 3 |
| Production LOC | 2059 |
| Rule findings | 2 (0 high, 2 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Equipment application is concentrated in a large module/function. Separate item classification, worn-item mutation, and engine adapter calls; preserve ordering and fallbacks.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-0974E0697C` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Equipment/PNC_Equipment.lua has 1229 code lines; review responsibility density. |
| `ARC-83E03B7963` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | applyWornItems spans 157 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-0974E0697C` | 1229 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Equipment/PNC_Equipment.lua | — |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 9816 | 1327 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Equipment/PNC_Equipment.lua |
| 6374 | 843 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Equipment/PNC_Equipment_Slots.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


