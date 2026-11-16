# Audit — Semantic Generation Lifecycle Cleanup

**Evidence class:** `CODE_VERIFIED`, `GENERATED_OUTPUT_VERIFIED` (G0 baseline inventory in `G0_SURFACE_INVENTORY.json`).
**ProjectHoomans anchor:** `02c7fb18e714`
**PsychopatzCore anchor:** `e3eb7ddce389`
**DynamicTrading anchor:** `9c8cb3dead56`

## 1. Surface Classification Summary

### `conversation_lua` (`owned_fileset` with generated-header marker)
- **PsychopatzCore** (`Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine`):
  - 41 desired generated `.lua` modules (including `FoundationRegistry.lua` and 2 active hash-suffixed shards).
  - 11 hand-authored runtime `.lua` modules (`ActionContract.lua`, `Affordance.lua`, `DialogueFlow.lua`, `DialogueRouter.lua`, `DialogueState.lua`, `DialogueState_Events.lua`, `DialogueState_References.lua`, `DialogueTurn.lua`, `Foundation.lua`, `Offer.lua`, `TextBinding.lua`) lacking `-- Generated` headers — classified as **authored/preserved**.
- **ProjectHoomans** (`Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine`):
  - 218 desired generated `.lua` modules (including `Registry.lua`, `Manifest.lua`, `UI/StaticSuggestions.lua`, `Index/**`, and 25 active hash-suffixed shards).
  - 1 hand-authored adapter module (`DialogueBlocks.lua`) — classified as **authored/preserved**.
- **DTCommon** (`Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine`):
  - 5 desired generated `.lua` modules (`Registry.lua`, `Manifest.lua`, `Dialogue/Trading.lua`, `Packs/Dialogue/Trading.lua`, `UI/Dialogue/Trading.lua`). Currently `Registry.lua` and `Manifest.lua` have uncommitted `wholeModelFingerprint` drift in the worktree that matches the current desired plan.

### `conversation_ui` (`mixed_key_catalog`)
- `Contents/mods/<Owner>/common/media/translation/{EN,TL}/Conversation/UI.json` across `PsychopatzCore`, `ProjectHoomans`, and `DTCommon`.
- **UI key owner lookup defect discovered in G0:** `conversation_translation_catalogs_by_owner()` looked up `suggestion["id"]` in `model["locations"]` instead of `model["uiLocations"]`. Because `question.wellbeing` and `question.activity` exist in both `dialogue/core_check_in/` (Core UI) and `adopters/hoomans/dialogue/core_semantic_responses/` (Hoomans dialogue), `model["locations"]` returned `ProjectHoomans`, omitting 4 Core-generated UI keys (`UI_PNC_Conversation_Suggestion_{Activity,Wellbeing}_{Label,Utterance}`) from `PsychopatzCore`'s generated UI key set.
- **ProjectHoomans `UI.json` key breakdown (89 existing keys per locale):**
  - 42 currently desired generated suggestion keys (20 Core + 6 Hoomans + 16 DTCommon composed into adopter registry).
  - 40 active Hoomans suggestion/group/tooltip keys (`UI_PNC_Conversation_Suggestion_*`) actively consumed by `PNC/ConvoEngine/Dialogue/Suggestions_*.lua` and `PNC/ConvoEngine/Suggestions/*.lua` — classified as **authored/preserved**.
  - 7 obsolete formerly generated keys (`UI_PNC_Conversation_SemanticSuggestions_Title`, `UI_PNC_Conversation_Suggestion_Back_Label`, `UI_PNC_Conversation_Suggestion_Identity_{Lie,Real,Rude}_Utterance`, `UI_PNC_Conversation_Suggestion_Trade_{Label,Utterance}`) left behind when `ui/suggestion_text_{actions,context}.json` were retired in `e3e1cab8` and identity utterances were removed in `fdee7542` — classified as **confirmed retired** (zero callers across all repositories).

### `conversation_text` (`owned_fileset`)
- `Contents/mods/<Owner>/common/media/translation/{EN,TL}/Conversation/Text/**/*.json`.
- Desired per locale: `PsychopatzCore` = 8 (9 text-manifest sources fan into 5 `memory/backstory/*` targets + 3 inline `textTarget` domains), `ProjectHoomans` = 39, `DTCommon` = 2. Zero stale files currently present.

### `conversation_translations` (`owned_fileset` with preserved package catalogs)
- **Confirmed retired files present in `ProjectHoomans`:**
  - `Contents/mods/ProjectHoomans/common/media/translation/{EN,TL}/Conversation/Command.json` (571 `conversation.content.semantic.*` keys each). Companion commands and combat horde reactions migrated to ConvoEngine in `e7e44b80` and now register inline translations via `ConvoPlanFamily.lua` (`RegisterInlineText`), while peer domain catalogs (`Task.json`, `Event.json`, `Social.json`, `Greeting.json`, `Needs.json`, `Health.json`, `Wellbeing.json`) were deleted in S5 (`1c88d83c`..`9f7ea815`). Zero runtime Lua callers remain; only two stale test assertions (`test_semantic_authority_boundaries.py`, `test_semantic_observatory_scale.py`) still reference `Command.json`.
- **Preserved package catalogs in `ProjectHoomans` (`EN` and `TL`):**
  - `Flows.json`, `Patterns.json`, `Identity/Responses.json`, `Journal/Events.json`, `PBrainZ/Interface.json`, `Semantic/Addressing.json`, `Semantic/Availability.json`, `Semantic/Realizations.json`, `Semantic/Responses.json`, `Telemetry/Diagnostics.json`, `WorldEvents/Events.json`. All are actively referenced by runtime Lua (`Input_Presentation_Responses_Translation_*.lua`, `SpeechRealization/Families/*.lua`, `PNC_PlayerKnowledgeCommands_IdentityPresentation.lua`, `PNC_ColonistJournalPresentation.lua`, `PNC_WorldKnowledge_Server.lua`, etc.) and must remain preserved and listed in `manifests/Conversation.json`.

### `lexicon_lua` (`owned_fileset`)
- `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/Generated/Lexicon/**` (17 generated Lua files). Owned by PsychopatzCore WordNet lexicon compiler; preserved intact during conversation-only reconciliation unless WordNet input is supplied.

## 2. Post-G6 corrective audit — 2026-11-16

**Evidence:** `CODE_VERIFIED`, `TEST_VERIFIED`, `GENERATED_OUTPUT_VERIFIED`.

The G0 inventory above remains useful historical evidence, but its `preserved` classification is not automatically a valid steady-state architecture. A post-G6 audit found that some entries are genuine engine/application assets while others are unfinished CodeBuilder migration debt.

### Current behavior that is good

- The real explicit three-repository reconciliation check succeeds with `desired=371`, `missing=0`, `drifted=0`, `stale=0`, `retired_present=0`, `ambiguous=0`, `preserved=38`.
- Focused recipe/check/apply/lifecycle tests pass (`15/15`).
- Generated Lua staleness is discovered dynamically from the current desired ledger plus generated-file header; arbitrary new stale generated Lua does not need a recipe filename entry.
- `Conversation/Text` JSON is treated as a closed generated-owned subtree and stale files are dynamically discovered.
- Active desired hash-suffixed shards are correctly preserved by desired-plan membership.

### Structural debt found

The current `generation_recipe.json` is approximately 250 lines and includes:
- 12 manually enumerated preserved Lua paths;
- 22 manually enumerated preserved translation paths;
- 7 retirement entries;
- one retirement containing 42 individual historical translation paths;
- one retirement containing 7 individual old generated UI keys.

That is safe migration scaffolding, but it is not the desired long-term policy-driven recipe.

### Authored versus generated classification defect

The term `authored/preserved` currently combines different ownership classes.

Legitimate hand-written engine/adaptor examples include:
- `PsychopatzCore/ConvoEngine/ActionContract.lua`;
- `PsychopatzCore/ConvoEngine/DialogueFlow.lua`;
- `PNC/ConvoEngine/DialogueBlocks.lua`.

These are program logic and should remain hand-written.

By contrast, some preserved translation files contain dialogue/semantic wording. Concrete proof:

- `ProjectHoomans/.../translation/EN/Conversation/Flows.json` contains `UI_PNC_Conversation_Semantic_AuthoredFollowAccepted = "Okay, I'll come with you."`;
- canonical CodeBuilder source `tools/providers/pnc/codebuilder/sources/conversation/dialogue/companion_flows/follow.json` already contains the same EN/TL wording and template identity.

Therefore at least part of the preserved translation set is migration debt, not a permanent authored asset class.

Other preserved catalogs such as identity/semantic responses must be classified by exact callers/purpose. Dialogue/semantic wording should move into canonical family source; diagnostics/journal/provider UI may remain ordinary package translations outside generated ownership.

### Receipt/default workflow limitation

Generation receipts can remember previously generated files and mixed-catalog generated keys, but `receipt_root` is optional and the documented simple canonical workflow does not universally persist one. Therefore prior ownership for non-self-identifying ordinary translation files/mixed keys is not guaranteed by the simplest default invocation.

G7 should prefer structural generated ownership so cleanup does not depend on optional historical state.

### Canonical CLI acceptance defect

The short command stored in the recipe (`reconcile.py ... --check`) was executed from PsychopatzCore and failed because the external ProjectHoomans conversation source root was not resolved. The explicit README command with `--repository ../ProjectHoomans --core-repository . --hoomans-repository ../ProjectHoomans --dynamic-trading-repository ../DynamicTrading` succeeds.

The current G6 discoverability test only checks that command strings contain expected tokens; it does not execute the advertised canonical command. G7 must make the advertised command truthful and test it end-to-end.

### Corrective conclusion

Reopen the parent goal for G7. Do not replace the existing reconciler; finish the structural migration around it.

The permanent model is four ownership classes:
1. hand-written engine/adaptor code;
2. canonical CodeBuilder semantic source;
3. generated runtime output;
4. ordinary application/tooling translations.

There is no steady-state class for hand-authored runtime dialogue content.

G7 must preserve the accepted ConvoEngine naming/sharding contracts in `CONVO_ENGINE.md` and `NAMING_AND_LAYOUT.md`; structural cleanup is not permission to rename semantic identities, flatten coherent families, create `PartNN` shards, or delete desired hash-suffixed generated chunks.

## G7A — Preserve Exception & Structural Ownership Classification Audit (`CODE_VERIFIED`)

The machine-readable classification artifact is stored at `docs/Jobs/SemanticGenerationLifecycleCleanup/G7A_PRESERVE_CLASSIFICATION.json`. Zero files were deleted during G7A.

### 1. Hand-written ConvoEngine Lua Neighbors (12 files)
All 12 preserved Lua paths (`11` in `PsychopatzCore/ConvoEngine/*.lua` and `1` in `PNC/ConvoEngine/DialogueBlocks.lua`) are classified as `hand_written_engine_or_adapter`. They never carry the CodeBuilder `-- Generated` header and can be structurally distinguished from generated ConvoEngine Lua without a 12-item per-file preserve list in `generation_recipe.json`.

### 2. Preserved `ProjectHoomans` Translation Catalogs (11 EN/TL pairs = 22 files)
- **`codebuilder_semantic_dialogue_to_migrate` (6 EN/TL pairs = 12 files)**:
  - `Conversation/Flows.json` (`2` keys): 100% duplicated in canonical `tools/providers/pnc/codebuilder/sources/conversation/dialogue/companion_flows/{follow,lab_stay_with_you}.json`.
  - `Conversation/Patterns.json` (`44` keys): 100% represented across `21` canonical `tools/providers/pnc/codebuilder/sources/conversation/dialogue/core_semantic_responses/*.json` files.
  - `Conversation/Semantic/Realizations.json` (`104` keys): `100` keys already represented in canonical ConvoEngine families (`PsychopatzCore` + `ProjectHoomans`); `4` keys (`UI_PNC_Conversation_Semantic_RealizationCompanionFollow*`) map to `dialogue/companion_commands_replies/command_reply_follow.json`.
  - `Conversation/Semantic/Responses.json` (`116` keys): `36` keys already represented in canonical ConvoEngine sources; `80` ConvoEngine dialogue response keys to be authored in canonical ConvoEngine family sources under `tools/providers/pnc/codebuilder/sources/conversation/dialogue/` and emitted as generated runtime text.
  - `Conversation/Identity/Responses.json` (`4` keys): NPC spoken identity-exchange lines (`UI_PNC_Conversation_Identity_FalseName`, `UI_PNC_Conversation_Identity_Evasion_Rude_{1..3}`) to migrate into canonical ConvoEngine `dialogue/identity_exchange/` source.
  - `Conversation/Semantic/Availability.json` (`11` keys): Companion/camp suggestion availability tooltips (`UI_PNC_Conversation_Suggestion_*_Tooltip`) to migrate into canonical `dialogue/static_suggestion_text/` sources alongside existing `ui_suggestion_unavailable_tooltip.json`.
- **`ordinary_application_or_tooling_translation` (4 EN/TL pairs = 8 files)**:
  - `Conversation/Semantic/Addressing.json` (`34` keys): Relationship/character terminology (`UI_PNC_SemanticAddress_*`, `UI_PNC_SemanticAddressing_*`) → move to `Character/Character.json` and route `SemanticAddress` / `SemanticAddressing` to `"Character"` in `PNC_TranslationBootstrap_Segments.lua`.
  - `Conversation/Journal/Events.json` (`12` keys): Colonist/settlement journal UI strings (`UI_PNC_Journal_*`) → move to `Debug/Debug.json` and route `Journal` to `"Debug"` in `PNC_TranslationBootstrap_Segments.lua` (matching `ColonyJournal` and `Colonist`).
  - `Conversation/PBrainZ/Interface.json` (`4` keys): Inline chat UI chrome (`UI_PNC_PBrainZ_*`) → move to `Debug/Debug.json` and route `PBrainZ` to `"Debug"` in `PNC_TranslationBootstrap_Segments.lua`.
  - `Conversation/Telemetry/Diagnostics.json` (`40` keys): Telemetry diagnostic modal labels (`UI_PNC_Conversation_Telemetry_*`) → move to `Debug/Debug.json` and route `^UI_PNC_Conversation_Telemetry_` to `"Debug"` in `PNC_TranslationBootstrap.lua`.
- **`obsolete` (1 EN/TL pair = 2 files)**:
  - `Conversation/WorldEvents/Events.json` (`51` keys): Caller-zero historical leftover whose 4 world-event families (`MedicalBandage`, `ProjectALife`, `ZombieHorde`, `ZombieRetreat`) were already migrated to canonical ConvoEngine sources and whose old Lua callers were removed in commit `b8531783`.

### 3. `Conversation/UI.json` Across All 3 Owners
- `DTCommon`: `16/16` keys are 100% CodeBuilder-generated.
- `ProjectHoomans`: `42` keys currently generated + `40` `UI_PNC_Conversation_Suggestion_*` keys already authored in `dialogue/static_suggestion_text/ui_suggestion_*.json`; once emitted into `ProjectHoomans` `UI.json` (with the `11` availability tooltip keys), `ProjectHoomans` `Conversation/UI.json` is 100% CodeBuilder-generated (`owned_fileset`).
- `PsychopatzCore`: `20` generated `UI_PNC_Conversation_Suggestion_*` keys + `117` Core `UI_PsychopatzConversation_*` keys (including concurrent dirty worktree changes). Structural key-prefix partitioning (`UI_PNC_Conversation_Suggestion_*` / `UI_DT_Conversation_Suggestion_*` vs `UI_PsychopatzConversation_*`) + persisted receipt preserves all Core keys while pruning obsolete generated suggestion keys without a manual key list.

