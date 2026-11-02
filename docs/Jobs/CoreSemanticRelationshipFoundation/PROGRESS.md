# Progress — Core Semantic & Relationship Foundation

**State:** READY FOR USER LIVE TEST — All developer phases P0A, P0B, P1, P2, P3, P4, P5, P6, and P7 complete and verified across all three repositories.

## Planning & Audit Evidence

Verified on 2026-11-02:

- Exact branch/HEAD/status across all three repos confirmed:
  - `psychopatzCore`: `main` @ `03fd546`, clean, 4 commits ahead of origin.
  - `DynamicTrading`: `main` @ `30e745f6`, 3 commits ahead of origin, 1 tracked modification in `DTHoomans_Conversation.lua` preserved.
  - `ProjectHoomans`: `main` @ `48f95c67`, clean, 4 commits ahead of origin.
- Core Actor Social stores canonical approval/respect/familiarity/personality/memories with server-authorized events.
- Core Social (`PsychopatzSocial.lua`) features namespaced `extensions` dictionary on relationship entries and top-level social state with non-destructive preservation of inactive adopter payloads.
- Mapped field-by-field ownership between Core Social and Hoomans `record.social`:
  - Shared Core: approval (-100..100), respect (-100..100), familiarity (0..100), memories, personality, recentEventIDs.
  - Hoomans extensions: durable bond (romance/family), morale/moraleBaseline, conduct, saturation, cooldowns, interactionJournal.
- Standalone Dynamic Trading operates without Project Hoomans:
  - `DTCommon` and `DTAbstract` require only `PsychopatzCore,MarketSense`.
  - `DTCommon_TalkService` uses PsychopatzCore Semantics dialogue blocks and action providers.
  - `DTCommon_TraderService` resolves physical/abstract actors through `PsychopatzCore.Actors.Registry`.
  - `DTCommon_CoreActorPolicy.PriceContext` reads canonical Core Social for relationship discounts.
- Dynamic Trading trade execution (`DTCommon_TraderService.ExecuteTradeBasket`) records commercial events into canonical Core Social.
- Project Hoomans registered as additive adopter via `PNC_CoreSemanticPack.lua` registering `pack.projecthoomans.social_core`.
- Automated Hot-Plug matrix test (`psychopatz_hotplug_save_matrix_smoke.lua`) proves bidirectional mod addition/removal/re-addition, idempotence, and non-destructive quarantine of conflicts.

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
- [x] **P4 — Project Hoomans additive adopter** (Accepted: 2026-11-02)
  - Created `PNC_CoreSemanticPack.lua` registering `pack.projecthoomans.social_core` with PsychopatzCore Semantics.
  - Capability-gated action providers (`hoomans.companion`, `hoomans.inventory`, `hoomans.social`) preventing companion/command action leaks to non-companion actors.
  - `PNC_ConversationSelector.SelectBlock` integrates Core Semantics dialogue blocks fallback.
  - Tests `pnc_core_semantic_adopter_smoke.lua` and full Hoomans test suite passing.
- [x] **P5 — Boundary enforcement and capability isolation** (Accepted: 2026-11-02)
  - Removed hidden caller assumptions: `DTCommon_TraderService` locates live actors through `PsychopatzCore.Actors.Registry`.
  - Verified `PsychopatzCore` has zero runtime imports of `DynamicTrading` or `ProjectHoomans`.
  - Verified strict capability filtering and fault-resilient action collection.
  - Test `psychopatz_boundary_isolation_smoke.lua` passing in Core.
- [x] **P6 — Hot-plug save migration and removal matrix** (Accepted: 2026-11-02)
  - Automated complete 8-step matrix in `psychopatz_hotplug_save_matrix_smoke.lua`:
    1. Core + DT create/save/reload.
    2. Add Hoomans to existing save -> exact same actor IDs, identity, base relationship, memories, zero duplicate actors.
    3. Exercise Hoomans extensions/capabilities -> coexistence of DT and Hoomans extensions.
    4. Remove Hoomans and reload -> DT remains healthy, shared state unchanged, inactive Hoomans extension preserved in Core Social.
    5. Re-add Hoomans -> extension data recovered intact, latest DT trade deltas observed.
    6. Reverse matrix: Core + Hoomans -> Add DT -> Remove DT -> Re-add DT.
    7. Repeated load/migration is strictly idempotent (5 iterations).
    8. Migration conflicts fail visibly with quarantine rather than destructive reset.
  - Test `psychopatz_hotplug_save_matrix_smoke.lua` passing.
- [x] **P7 — Final convergence verification and user handoff** (Accepted: 2026-11-02)
  - Full test suites passing across all three repositories (12 Core tests, 33 DT tests, 8 Hoomans tests).
  - Clean `git diff --check` across all repositories.
  - Preserved untracked local edits in `DTHoomans_Conversation.lua`.
  - Ready for User Live In-Game Test.

## Parent Goal Status

**COMPLETE (Developer Gates Finished)** — Handing off to user for native in-game testing.

IN PROGRESS until P0-P7 acceptance passes.
