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
