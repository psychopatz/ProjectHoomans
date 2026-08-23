# Presence System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 94.6 |
| Architecture pressure | 6.9 |
| Graph coverage score | 76.3 |
| Evidence confidence | 61.1 |
| Production files | 16 |
| Production LOC | 2705 |
| Rule findings | 3 (0 high, 3 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

No rule-level production finding was emitted for this subsystem. That is a triage result, not proof of absence. Keep its boundary small, preserve its current contract, and use the graph and token indexes before expanding it.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-7757687A84` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.prepareCorpseItems spans 209 lines. |
| `ARC-AA4EB3353A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Presence.Materialize spans 165 lines. |
| `ARC-E5F973E668` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Lifecycle.AuditLoadedBodies spans 163 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 4765 | 582 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup.lua |
| 4490 | 576 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Presence/PNC_Presence.lua |
| 2230 | 272 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseItems.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


