# Inventory System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 84.3 |
| Architecture pressure | 28.6 |
| Graph coverage score | 74.5 |
| Evidence confidence | 63.4 |
| Production files | 18 |
| Production LOC | 3356 |
| Rule findings | 4 (1 high, 2 medium, 1 low) |
| Fan-in / fan-out | 3 / 3 |

## Next-phase disposition

Has a high-severity unbounded-loop finding in the persistence bridge and participates in a Colony/Composition cycle. Separate canonical item state, serialization, equipment hydration, and UI transfer commands; preserve item identity and save compatibility.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-69A4CDC173` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> Colony -> Inventory -> (composition) |
| `ARC-286E29BBB7` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | Potential unbounded loop in Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreBridge.lua. |
| `ARC-AA875A653A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | transferNPCToPlayer spans 126 lines. |
| `ARC-9AD2B75E96` | `HOT_PATH_EVENT_RISK` | LOW | LOW (52%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations.lua publishes events and contains a recurring hot-path signal. |
| `ARC-A4FB3615D3` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (70%) | Repeated test setup appears across 3 tests (~12 repeated LOC). |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 9041 | 1003 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Inventory/PNC_InventoryWindow.lua |
| 4481 | 537 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Inventory/PNC_Inventory/Model/PNC_Inventory_Items.lua |
| 3735 | 445 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations.lua |
| 3220 | 391 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Inventory/PNC_InventoryUI_Model.lua |
| 2078 | 207 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Inventory/PNC_InventoryUI_List.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


