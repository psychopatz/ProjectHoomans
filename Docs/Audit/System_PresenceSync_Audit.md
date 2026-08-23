# PresenceSync System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 92.8 |
| Architecture pressure | 9 |
| Graph coverage score | 78.5 |
| Evidence confidence | 62.7 |
| Production files | 25 |
| Production LOC | 3603 |
| Rule findings | 4 (0 high, 4 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Native path control, snapshots, body application, and action motion need explicit ownership between server state, client/native control, animation, and network snapshots.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-770C315477` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | updateWindowSmash spans 125 lines. |
| `ARC-7C119FB848` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.UpdateNativePathController spans 172 lines. |
| `ARC-99D5CA6A7B` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | applyActionMotion spans 149 lines. |
| `ARC-A645D377B0` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | applySnapshotToBody spans 156 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 4402 | 543 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage.lua |
| 2872 | 403 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/PresenceSync/PNC_ClientZombieAggroController.lua |
| 2318 | 261 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/PresenceSync/PNC_ClientPresenceBodies.lua |
| 2271 | 283 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/PresenceSync/PNC_ClientPresenceTick.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


