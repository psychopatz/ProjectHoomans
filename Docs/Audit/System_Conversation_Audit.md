# Conversation System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P1`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 64.2 |
| Architecture pressure | 53.1 |
| Graph coverage score | 80.4 |
| Evidence confidence | 67.2 |
| Production files | 53 |
| Production LOC | 6640 |
| Rule findings | 9 (2 high, 7 medium, 0 low) |
| Fan-in / fan-out | 3 / 2 |

## Next-phase disposition

Conversation is coupled to UI and Composition through multiple cycles. Separate definitions, validation, authority, and scene presentation; pass immutable outcomes into UI and keep server mutation behind authority boundaries.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-27BB8B419F` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: Conversation -> UI -> Conversation |
| `ARC-DCBC824FD8` | `DEPENDENCY_CYCLE` | HIGH | DETERMINISTIC (99%) | Subsystem participates in dependency cycle: (composition) -> Composition -> Conversation -> UI -> (composition) |
| `ARC-C29D33EF83` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | Potential unbounded loop in Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Conversation/Blocks/PNC_ConversationTextLoader.lua. |
| `ARC-1B3D64488A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Composer.ReceiveOutcome spans 123 lines. |
| `ARC-4566A1342F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Scene.Begin spans 122 lines. |
| `ARC-53830E5F68` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Model.BuildSandboxDefinition spans 197 lines. |
| `ARC-7BE4C73EAA` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Composer.ReceiveGiftResult spans 125 lines. |
| `ARC-911520AD7C` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Registry.ValidateBlock spans 166 lines. |
| `ARC-B7FCF9DEC7` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Authority.HandleChoice spans 129 lines. |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 5278 | 616 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Conversation/Blocks/PNC_ConversationRegistry.lua |
| 4958 | 585 | Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Conversation/PNC_ConversationAuthority.lua |
| 4829 | 627 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/Debug/PNC_ConversationDebugModel.lua |
| 4150 | 514 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Conversation/Blocks/PNC_ConversationRules.lua |
| 4005 | 536 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Conversation/PNC_ConversationScene.lua |
| 3591 | 385 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/Debug/PNC_ConversationDebugWindow.lua |
| 3317 | 430 | Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/PNC_ConversationDefinition.lua |
| 2306 | 259 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Conversation/Blocks/PNC_ConversationTextLoader.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.


