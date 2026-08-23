# Health System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 92.9 |
| Architecture pressure | 9.5 |
| Graph coverage score | 67 |
| Evidence confidence | 55.2 |
| Production files | 5 |
| Production LOC | 2540 |
| Rule findings | 4 (0 high, 3 medium, 1 low) |
| Fan-in / fan-out | 1 / 1 |

## Next-phase disposition

Large wound update/damage functions and a hot-path event risk. Split wound state, attack resolution, event emission, and persistence so update ticks remain bounded.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-B87BB30AA7` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_NPCWounds.lua has 1258 code lines; review responsibility density. |
| `ARC-A813C86819` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Wounds.ApplyResolvedZombieAttack spans 138 lines. |
| `ARC-DCCE18C7DA` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Wounds.Update spans 140 lines. |
| `ARC-1321C4888B` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_NPCWounds.lua publishes events and contains a recurring hot-path signal. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-B87BB30AA7` | 1258 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_NPCWounds.lua | — |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 12844 | 1350 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_NPCWounds.lua |
| 4648 | 563 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_Health.lua |
| 3240 | 393 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_PlayerDamage.lua |
| 2980 | 356 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_Treatment.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


