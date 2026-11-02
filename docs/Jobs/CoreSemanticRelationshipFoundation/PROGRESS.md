# Progress — Core Semantic & Relationship Foundation

**State:** READY FOR USER LIVE TEST — P13, P14, and P15 complete and independently verified across production modules.

## Current repository snapshot

- `psychopatzCore`: `main @ 092c72d`, 9 commits ahead of `origin/main`, clean.
- `DynamicTrading`: `main @ 80dd24fd`, 7 commits ahead, with the preserved pre-existing tracked local edit in `DTHoomans_Conversation.lua` untouched.
- `ProjectHoomans`: `main @ d7544b76`, 14 commits ahead, clean.

## Resolved boundary fixes (P13 - P15)

### P13 — Trusted DT-First Player Identity Adoption
- **Problem:** When starting with Core + DT, Core generated a player UUID and canonical target `player:sp_slot_X:<uuid>`. Later enabling Project Hoomans caused `PNC.PlayerCharacters.EnsureIdentity` to reject the UUID as `unknown_uuid` and generate a replacement UUID/key, forking the relationship identity.
- **Fix:**
  - `psychopatzCore` (`PsychopatzPlayerIdentity.lua`): Added cryptographic-style provenance signing `SignProvenance(uuid, accountKey)` and verification `VerifyProvenance(player, claimedUUID, expectedAccountKey)`. Stored in modData `Core_CharacterSignature` and `Core_CharacterAccountKey`. Auto-attests and mirrors to `PNC_CharacterUUID`.
  - `ProjectHoomans` (`PNC_PlayerCharacterService_EnsureIdentity.lua` & `IdentityCreation.lua`): Added `canAdoptCoreIdentity(player, claimedUUID, accountKey)`. When encountering `unknown_uuid`, Hoomans verifies Core provenance via `CoreIdentity.VerifyProvenance`. Upon verification, adopts the exact Core-issued UUID into the Hoomans registry with reason `"core_adopted"`, maintaining exact target key parity.
- **Verification:** `tests/pnc_core_player_identity_adoption_smoke.lua` verifies SP adoption, MP adoption, reconnect stability, untrusted claim rejection, cross-account claim rejection, and idempotent re-adoption.

### P14 — Production Conversation Capability Isolation
- **Problem:** `PsychopatzActorConversationService:Submit` computed `effectiveContext` with sanitized capabilities, but passed un-isolated `options` into `ParseTurn(text, options)`. Foreign adopter grammars (e.g. Hoomans `COMMAND` like "follow me") leaked into DT-only conversations when both packs were installed.
- **Fix:**
  - `psychopatzCore` (`PsychopatzActorConversationService.lua`): Added capability normalization and intersection helpers. Ensured `ParseTurn`, `Preview`, `Process`, and `Submit` propagate `effectiveContext.capabilities` into candidate collection and compound turn splitting. Options cannot broaden privileges beyond the conversation context.
  - `PsychopatzSemanticDialogueRouter.lua` & `PsychopatzSemanticParser.lua`: Router forwards capabilities into candidates and options; parser validates capabilities supporting both map and list schemas.
- **Verification:** `tests/psychopatz_conversation_capability_isolation_smoke.lua` verifies DT-only conversations reject Hoomans COMMAND, DT trade parses, Hoomans-only conversations reject DT trade, compound turns block smuggled clauses, caller options cannot broaden capabilities, and unregistration leaves zero residue.

### P15A & P15B — Standalone DT Semantics & Factual Response Grounding
- **Problem:** Standalone DT was missing mandatory semantic families (`where is the trader`, `where is the settlement`, `what settlement are you going to`, `road news`, `tell me a caravan story`, `goodbye`). Furthermore, whereabouts returned hardcoded static sentences ("southern outpost / central market") rather than grounding in real `DTCommon.WorldKnowledge` or expressing bounded uncertainty.
- **Fix:**
  - `DynamicTrading` (`DTCommon_SemanticPack.lua`): Added concepts and speech acts for story, destination, origin, settlement, trader location, farewell, and greetings. Added clean `Pack.Register()` and `Pack.Unregister()` methods and updated `Pack.Init()` to verify registry status.
  - `DynamicTrading` (`DTCommon_TalkService.lua`): Updated `responsePlanner` to ground queries using `context.policy`, `context.worldKnowledge`, and `context.npcGossip`. When evidence is present, delivers grounded text with evidence refs; when absent, returns bounded uncertainty ("I cannot confirm where we are heading next...", "I haven't heard any news lately."). Delivered rich storytelling for caravan stories.
- **Verification:** `tests/dt_standalone_semantic_story_smoke.lua` passed all tests. Full DT runner `tests/run_tests.py` passed 43/43.

### P15C — True Production Hot-Plug Acceptance Matrix
- **Implementation:** `ProjectHoomans/tests/pnc_real_cross_adopter_hotplug_matrix_smoke.lua` updated to exercise the real production modules across 6 comprehensive sequences:
  1. **Sequence 1 (DT First):** DT-only save with real provenance-signed Core UUID -> DT trade -> Save/Reload -> Add Hoomans -> Real `EnsureIdentity` adopts UUID and key (`core_adopted`) -> Hoomans mutates social state (+10 approval, friend bond, memory) -> Save/Reload -> Remove Hoomans -> DT trade executes while Hoomans inactive (Hoomans bond and memories preserved) -> Re-add Hoomans -> Full recovery of shared and adopter-owned state.
  2. **Sequence 2 (Hoomans First):** Hoomans-first save with real `EnsureIdentity` -> Colonist relationship established -> Save/Reload -> Add DT -> DT trade executed (DT extension created, Hoomans bond preserved) -> Save/Reload -> Remove DT -> Hoomans interacts while DT inactive -> Re-add DT -> DT trade executed (both extensions and memories intact).
  3. **Sequence 3 (Conversation Capability Isolation):** With both real production packs installed, DT-only capabilities reject Hoomans COMMAND and parse DT TRADE; Hoomans-only capabilities reject DT TRADE and parse Hoomans COMMAND.
  4. **Sequence 4 (Grounded DT Whereabouts & News):** Real `DTCommon.TalkService` turn execution verifies seeded evidence yields grounded answers, unseeded yields bounded uncertainty, and stories yield rich narrative.
  5. **Sequence 5 (Pack Lifecycle Residue Check):** Unregistering DT or Hoomans packs removes all owned patterns with zero residue; re-registering restores them cleanly.
  6. **Sequence 6 (Migration & Sync Idempotence):** Repeated `SyncToCore` operations produce zero memory duplication and zero score inflation.
- **Verification:** `tests/pnc_real_cross_adopter_hotplug_matrix_smoke.lua` PASSED with 0 errors.

## Overall Test Verification

- `psychopatzCore`: All focused tests PASS (`psychopatz_player_identity_smoke.lua`, `psychopatz_actor_conversation_service_smoke.lua`, `psychopatz_conversation_capability_isolation_smoke.lua`, `psychopatz_semantic_pack_lifecycle_smoke.lua`, `psychopatz_semantic_pack_smoke.lua`, `psychopatz_semantic_dialogue_flow_smoke.lua`, `psychopatz_social_extension_smoke.lua`, `psychopatz_boundary_isolation_smoke.lua`).
- `DynamicTrading`: 43/43 tests PASS (`tests/run_tests.py`).
- `ProjectHoomans`: All focused tests PASS (`pnc_core_player_identity_adoption_smoke.lua`, `pnc_real_cross_adopter_hotplug_matrix_smoke.lua`, `pnc_non_destructive_social_mutation_smoke.lua`, `pnc_core_semantic_adopter_smoke.lua`). Full suite passes with 982/987 (only the 5 documented pre-existing baseline failures remain).
- Syntax: `luac5.3 -p` passed across all modified Lua files.
- Diffs: `git diff --check` passed clean across all repositories.

## Next Step

**READY FOR USER LIVE TEST.**
The implementation satisfies all architectural invariants and developer acceptance gates. The user may now proceed with live in-game testing in Project Zomboid SP/MP saves.
