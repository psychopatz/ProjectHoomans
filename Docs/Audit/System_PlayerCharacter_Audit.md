# PlayerCharacter System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P3`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 93.5 |
| Architecture pressure | 5.5 |
| Graph coverage score | 57.7 |
| Evidence confidence | 47.1 |
| Production files | 2 |
| Production LOC | 1028 |
| Rule findings | 2 (0 high, 2 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

No rule-level production finding was emitted for this subsystem. That is a triage result, not proof of absence. Keep its boundary small, preserve its current contract, and use the graph and token indexes before expanding it.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-9E1E60DE47` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_PlayerCharacterService.lua has 941 code lines; review responsibility density. |
| `ARC-22D4C2D150` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PlayerCharacters.EnsureIdentity spans 157 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-9E1E60DE47` | 941 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_PlayerCharacterService.lua | — |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 7110 | 1020 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_PlayerCharacterService.lua |
| 2425 | 317 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Identity/PNC_PlayerCharacterTypes.lua |
| 2256 | 334 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_PlayerCharacterLifecycle.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


