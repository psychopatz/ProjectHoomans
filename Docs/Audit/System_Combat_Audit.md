# Combat System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 91 |
| Architecture pressure | 12 |
| Graph coverage score | 78.5 |
| Evidence confidence | 62.7 |
| Production files | 35 |
| Production LOC | 5489 |
| Rule findings | 5 (0 high, 5 medium, 0 low) |
| Fan-in / fan-out | 2 / 0 |

## Next-phase disposition

Several large decision/effect functions. Separate pure target/tactic decisions from engine effects, hit resolution, and debug observation building.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-072941BC13` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Combat.TryRanged spans 129 lines. |
| `ARC-4D688C1932` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.applyAttackActionHit spans 170 lines. |
| `ARC-7F45C7B855` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Tactics.PreAttackDecision spans 175 lines. |
| `ARC-C444310124` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Combat.TryMelee spans 138 lines. |
| `ARC-EC6C4B47F0` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Resolution.ApplyZombieDamage spans 130 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 4822 | 572 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/PNC_Combat_Firearms.lua |
| 4184 | 563 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/PNC_Combat_Defense.lua |
| 3615 | 420 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/PNC_Combat_ZombieReaction.lua |
| 3437 | 555 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/PNC_Combat_Engagement.lua |
| 2616 | 315 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/PNC_Combat.lua |
| 2451 | 257 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/CombatTactics/PNC_CombatTactics_State.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


