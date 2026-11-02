# Progress — Core Semantic & Relationship Foundation

**State:** IN PROGRESS — P0A accepted; proceeding to P0B contract implementation.

## Planning & Audit Evidence

Verified on 2026-11-02:

- Exact branch/HEAD/status across all three repos confirmed:
  - `psychopatzCore`: `main` @ `0100bf4`, clean, up to date with `origin/main`.
  - `DynamicTrading`: `main` @ `c97ee132`, up to date with `origin/main`, 1 tracked modification in `DTHoomans_Conversation.lua` preserved.
  - `ProjectHoomans`: `main` @ `02ab2b41`, clean, up to date with `origin/main`.
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

## Current Phase: P0B — Freeze Public Contracts

### Next Chunk — P0B
Implement and test the smallest stable, reusable public contracts in `PsychopatzCore` without loading Project Hoomans:
1. **Core Relationship Extension & Query Contract:**
   - Update `PsychopatzSocial.lua` to support namespaced adopter `extensions` on both top-level social state and individual relationship entries.
   - Preserve unknown/inactive adopter extension payloads across `normalizeRelationship`, `NewState`, `Validate`, `ToPayload`, and `RecordAuthorizedEvent`.
   - Add `Social.GetExtension(state, targetKey, extensionID)` and `Social.SetExtension(state, targetKey, extensionID, payload, authority, expectedRevision)`.
2. **Core Semantic Pack & Capability Contract:**
   - Add generic Semantic Pack registration in `PsychopatzCore.Semantics` (`PsychopatzSemanticPackRegistry.lua`):
     - `Semantics.RegisterPack(spec)` / `UnregisterPack(packID)` / `GetPack(packID)` / `ListPacks()`.
   - Add capability-gated action provider contract and filtering helper in `PsychopatzCore.Semantics`.
3. **Relationship-Aware Conversation Context Helper:**
   - Ensure `PsychopatzActorConversationService` and `PsychopatzSocialFlavor` provide clean projection of shared relationship and adopter extensions into conversation context.
4. **Focused Unit Tests:**
   - Create `tests/psychopatz_social_extension_smoke.lua` and `tests/psychopatz_semantic_pack_smoke.lua` in `psychopatzCore` verifying these contracts standalone.
   - Verify all existing Core, DT, and Hoomans baseline tests remain passing.

## Parent Goal Status

IN PROGRESS until P0-P7 acceptance passes.
