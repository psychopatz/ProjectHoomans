# Visuals System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 88.5 |
| Architecture pressure | 8.9 |
| Graph coverage score | 54.6 |
| Evidence confidence | 44.8 |
| Production files | 6 |
| Production LOC | 3000 |
| Rule findings | 3 (0 high, 3 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Animation and AnimationScenes are large modules. Split bump/lease handling, scene dispatch, trace/debug helpers, and XML-variable access while preserving animation variables and timing.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-3A3505DBD7` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_Animation.lua has 952 code lines; review responsibility density. |
| `ARC-9D98D9632D` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_AnimationScenes.lua has 866 code lines; review responsibility density. |
| `ARC-A14E57F9BB` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Animation.PlayBump spans 163 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-3A3505DBD7` | 952 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_Animation.lua | — |
| Large module | `ARC-9D98D9632D` | 866 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_AnimationScenes.lua | — |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 9100 | 1050 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_Animation.lua |
| 6234 | 919 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_AnimationScenes.lua |
| 3603 | 540 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_AnimationTrace.lua |
| 2475 | 345 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_AnimationSceneDefinitions.lua |
| 2134 | 303 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_Visuals.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


