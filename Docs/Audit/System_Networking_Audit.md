# Networking System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 91 |
| Architecture pressure | 14.4 |
| Graph coverage score | 78.1 |
| Evidence confidence | 62.4 |
| Production files | 39 |
| Production LOC | 5352 |
| Rule findings | 5 (0 high, 5 medium, 0 low) |
| Fan-in / fan-out | 2 / 3 |

## Next-phase disposition

Large snapshot/debug builders span client and shared code. Separate wire schemas, authority checks, snapshot assembly, transport, and diagnostics; keep debug payloads out of core replication.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-2DB0EDE118` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Parts.BuildCombatDebugState spans 165 lines. |
| `ARC-8EF9CF2B90` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Parts.BuildCombatDebugObservations spans 144 lines. |
| `ARC-A8CDC4473F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Parts.BuildVisualState spans 181 lines. |
| `ARC-E503E46465` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Network.BuildSnapshot spans 196 lines. |
| `ARC-F500F82AB8` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Client.SendDebug spans 220 lines. |
| `ARC-20161E1F32` | `TEST_HARNESS_EXTRACTION_CANDIDATE` | LOW | MEDIUM (74%) | Repeated test setup appears across 5 tests (~54 repeated LOC). |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large function | `ARC-F500F82AB8` | 220 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Networking/PNC_ClientActions.lua:28 | Client.SendDebug |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 6361 | 789 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Networking/PNC_ClientRequests.lua |
| 5379 | 714 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Networking/PNC_Network_Server.lua |
| 4740 | 552 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Networking/PNC_ClientActions.lua |
| 2789 | 373 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Networking/Handlers/PNC_ServerLegacyDebugCommandHandler.lua |
| 2009 | 225 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


