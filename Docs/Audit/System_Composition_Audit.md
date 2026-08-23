# Composition System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P1`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 61.1 |
| Architecture pressure | 75.6 |
| Graph coverage score | 73 |
| Evidence confidence | 59.7 |
| Production files | 3 |
| Production LOC | 308 |
| Rule findings | 6 (3 high, 3 medium, 0 low) |
| Fan-in / fan-out | 1 / 85 |

## Next-phase disposition

A 3-file composition surface with 85 outbound dependencies. Treat it as a composition root, not a general utility layer. Add narrow client/server/shared contracts and stop feature modules from depending back on the root.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-055A4BF464` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> Conversation -> UI -> (composition) |
| `ARC-356137E6D7` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> Colony -> Inventory -> (composition) |
| `ARC-A222F5958F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> (composition) |
| `ARC-BEF3CF98FE` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Composition/PNC_SharedComposition.lua directly depends on 52 foreign subsystems. |
| `ARC-D4C5436FC8` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Composition/PNC_ClientComposition.lua directly depends on 13 foreign subsystems. |
| `ARC-FC8906F331` | `CROSS_SUBSYSTEM_COUPLING` | MEDIUM | HIGH (82%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Composition/PNC_ServerComposition.lua directly depends on 43 foreign subsystems. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 2267 | 154 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Composition/PNC_SharedComposition.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


