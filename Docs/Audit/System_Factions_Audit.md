# Factions System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 80.5 |
| Architecture pressure | 24.5 |
| Graph coverage score | 81.5 |
| Evidence confidence | 65 |
| Production files | 13 |
| Production LOC | 7275 |
| Rule findings | 9 (0 high, 9 medium, 0 low) |
| Fan-in / fan-out | 1 / 3 |

## Next-phase disposition

FactionService, FactionTypes, and debug code concentrate state, validation, persistence, and diagnostics. Split membership/index maintenance, diplomacy/incidents, serialization, and debug snapshots behind stable contracts.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-41E7BB0AA0` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Factions/PNC_FactionTypes.lua has 910 code lines; review responsibility density. |
| `ARC-4E1C2EEC83` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionDebug.lua has 933 code lines; review responsibility density. |
| `ARC-9E8A515BF6` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionService.lua has 3540 code lines; review responsibility density. |
| `ARC-2ED1B12DBC` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Validation.RunScenario spans 135 lines. |
| `ARC-73E1FFFF63` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Debug.PerformAction spans 366 lines. |
| `ARC-7C7225D4C6` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Debug.BuildSnapshot spans 211 lines. |
| `ARC-A0B3BF09EE` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | rebuildIndexes spans 203 lines. |
| `ARC-A92CC5D2AA` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Factions.Archive spans 124 lines. |
| `ARC-F620D4BC37` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Intent.Resolve spans 125 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-9E8A515BF6` | 3540 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionService.lua | — |
| Large module | `ARC-4E1C2EEC83` | 933 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionDebug.lua | — |
| Large module | `ARC-41E7BB0AA0` | 910 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Factions/PNC_FactionTypes.lua | — |
| Large function | `ARC-73E1FFFF63` | 366 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionDebug.lua:531 | Debug.PerformAction |
| Large function | `ARC-7C7225D4C6` | 211 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionDebug.lua:319 | Debug.BuildSnapshot |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 26655 | 3690 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionService.lua |
| 7706 | 872 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugWindow.lua |
| 7321 | 994 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugModel.lua |
| 6856 | 964 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Factions/PNC_FactionTypes.lua |
| 5464 | 792 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionDebugOverlay.lua |
| 3759 | 618 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionMemberWindow.lua |
| 2852 | 353 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Factions/PNC_FactionEmblemEditor.lua |
| 2176 | 243 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Factions/PNC_FactionEmblems.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


