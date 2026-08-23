# Relationships System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 88 |
| Architecture pressure | 10.1 |
| Graph coverage score | 54.6 |
| Evidence confidence | 44.8 |
| Production files | 16 |
| Production LOC | 4021 |
| Rule findings | 4 (0 high, 4 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Large stateful relationship service/event mutation code. Separate graph math, event application, persistence, and debug snapshots; make mutation ordering explicit.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-20C687BEA0` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_RelationshipService.lua has 906 code lines; review responsibility density. |
| `ARC-8FB1D9BD8C` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Debug.BuildSnapshot spans 167 lines. |
| `ARC-B7411C9325` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Math.ModifySocialEvent spans 153 lines. |
| `ARC-E8AF593A4E` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Relationships.ApplyEventMutation spans 141 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 6428 | 954 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_RelationshipService.lua |
| 6171 | 875 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Relationships/PNC_RelationshipDebugWindow.lua |
| 6074 | 776 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Relationships/PNC_RelationshipDebugModel.lua |
| 5136 | 732 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_RelationshipDebug.lua |
| 3048 | 487 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Relationships/PNC_RelationshipTypes.lua |
| 3039 | 431 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Relationships/PNC_RelationshipGraphPanel.lua |
| 2106 | 327 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Relationships/PNC_RelationshipGraph.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


