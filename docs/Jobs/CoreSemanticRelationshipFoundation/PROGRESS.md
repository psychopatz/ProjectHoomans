# Progress — Core Semantic & Relationship Foundation

**State:** IN PROGRESS — P0A, P0B, P1, P2, P3 completed; proceeding to P4 (Project Hoomans Additive Adopter).

## Planning & Audit Evidence

Verified on 2026-11-02:

- Exact branch/HEAD/status across all three repos confirmed:
  - `psychopatzCore`: `main` @ `45b24f6`, clean, ahead of `origin/main` by 2 commits.
  - `DynamicTrading`: `main` @ `f0d97c50`, ahead of `origin/main` by 2 commits, 1 tracked modification in `DTHoomans_Conversation.lua` preserved.
  - `ProjectHoomans`: `main` @ `aac59627`, clean, ahead of `origin/main` by 2 commits.
- Core Actor Social already stores approval/respect/familiarity/personality/memories with server-authorized events.
- Audit identified critical foundation gap: Core Social (`PsychopatzSocial.lua`) currently drops unknown fields and lacks a namespaced `extensions` dictionary on relationship entries and top-level social state.
- Audit mapped field-by-field ownership between Core Social and Hoomans `record.social`:
  - Shared Core: approval (-100..100), respect (-100..100), familiarity (0..100), memories, personality, recentEventIDs.
  - Hoomans extensions: durable bond (romance/family), morale/moraleBaseline, conduct, saturation, cooldowns, interactionJournal.
- Audit identified Dynamic Trading standalone vs DTHoomans dependencies:
  - `DTCommon` and `DTAbstract` have zero hard dependencies on Project Hoomans (`mod.info` requires only `PsychopatzCore,MarketSense`).
  - `DTCommon_TalkService` provides a standalone bridge to `PsychopatzActorConversationService`.
  - `DTCommon_CoreActorPolicy.PriceContext` already reads `PsychopatzCore.Actors.Social` directly for relationship discounts.
  - Trade/referral choices are currently registered only in `DTHoomans_Conversation.lua` via Hoomans-specific block APIs.
- Comprehensive classification of Hoomans semantic modules completed in `AUDIT.md`.
- Baseline test suites in all three repositories verified passing.

## Completed Chunks

- [x] **P0A — Cross-repository convergence audit** (Accepted: 2026-11-02)
  - Detailed source truth, API inventory, field-by-field matrix, DT dependency map, semantic module classification, and migration hazard ledger documented in `AUDIT.md`.
- [x] **P0B — Freeze public contracts** (Accepted: 2026-11-02)
  - Namespaced `extensions` dictionary on Core Social state and relationship records, with `Social.GetExtension` and `Social.SetExtension`.
  - Generic Semantic Pack and capability-gated Action Provider contracts in `PsychopatzSemanticPackRegistry`.
  - `PsychopatzActorConversationService` relationship projection and action collection.
  - Tests `psychopatz_social_extension_smoke.lua` and `psychopatz_semantic_pack_smoke.lua` passing in Core.
- [x] **P1 — Make Core canonical shared relationship authority** (Accepted: 2026-11-02)
  - Replaced duplicate relationship authority in Hoomans `RelationshipService` with Core Actor Social authority using `SyncToCore`, `SyncFromCore`, `ToCoreSocial`, `FromCoreSocial`.
  - DT `ExecuteTradeBasket` and `DTCommon_CoreActorPolicy.RecordTradeEvent` record commercial events to Core Actor Social.
  - Tests `dt_trade_relationship_event_smoke.lua` and `pnc_core_social_convergence_smoke.lua` passing.
- [x] **P2 — Generic Core semantic dialogue flow and block selector** (Accepted: 2026-11-02)
  - Generic condition evaluator, gate evaluator, choice filter, deterministic outcome resolution in `PsychopatzSemanticDialogueFlow.lua`.
  - Dialogue block registry and selector in `PsychopatzSemanticPackRegistry.lua`.
  - Facade exports in `PsychopatzSemantic.lua`.
  - Test `psychopatz_semantic_dialogue_flow_smoke.lua` passing in Core.
- [x] **P3 — Standalone Dynamic Trading semantic/story pack** (Accepted: 2026-11-02)
  - Created `DTCommon_SemanticPack.lua` registering `pack.dynamictrading.trader_story`.
  - Concepts, speech acts, patterns, dialogue blocks, action providers (`dynamictrading.trade`, `dynamictrading.referral`, `dynamictrading.rumors`).
  - `DTCommon_TalkService` uses Core Semantic blocks and collects capability-gated actions for DT traders standalone without Hoomans.
  - Test `dt_standalone_semantic_story_smoke.lua` passing.

## Current Phase: P4 — Project Hoomans Additive Adopter

### Next Chunk — P4
Convert Project Hoomans into an additive semantic/social adopter:
1. Register Hoomans content, dialogue blocks, and action providers against Core Semantics (`pack.projecthoomans.social_core`).
2. Keep Hoomans-specific action providers (Follow, Camp, Guard, Task commands, Inventory access) gated by `"hoomans.companion"` / `"hoomans.command"` capabilities so they never leak to DT-only traders.
3. Wire Hoomans conversation engine to leverage Core Dialogue blocks / packs while preserving the full Hoomans dialogue corpus and server authority.
4. Verify all Hoomans conversation and relationship test suites pass.

## Parent Goal Status

IN PROGRESS until P0-P7 acceptance passes.
