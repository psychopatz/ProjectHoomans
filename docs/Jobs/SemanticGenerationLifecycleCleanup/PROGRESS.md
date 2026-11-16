# Progress — Semantic Generation Lifecycle Cleanup

**Status:** IN_PROGRESS.
**Current phase:** G1 — Generation recipe and desired-artifact ledger.
**Primary repository:** ProjectHoomans.
**Participant implementation repository:** psychopatzCore.
**Conditional participant:** DynamicTrading/DTCommon.

## Accepted phases

### G0 — Baseline inventory and ownership classification (`ACCEPTED`)

Evidence: `CODE_VERIFIED`, `GENERATED_OUTPUT_VERIFIED` (`docs/Jobs/SemanticGenerationLifecycleCleanup/G0_SURFACE_INVENTORY.json`).

- Audited exact workspaces across `ProjectHoomans` (`02c7fb18e714`), `psychopatzCore` (`e3eb7ddce389`), and `DynamicTrading` (`9c8cb3dead56`) without deleting any runtime or generated files.
- Classified all semantic generation surfaces (`conversation_lua`, `conversation_ui`, `conversation_text`, `conversation_translations`, `lexicon_lua`):
  - `ConvoEngine` Lua roots contain 264 desired generated Lua files (`PsychopatzCore`: 41, `ProjectHoomans`: 218, `DTCommon`: 5) alongside 12 preserved hand-authored Lua runtime modules (`PsychopatzCore`: 11, `ProjectHoomans`: 1).
  - Verified 27 active hash-suffixed generated modules (`__*`) in the desired runtime plan; none are stale.
  - Identified concrete active retired leftovers in `ProjectHoomans`:
    - `Contents/mods/ProjectHoomans/common/media/translation/{EN,TL}/Conversation/Command.json` (571 legacy `conversation.content.semantic.*` keys each; superseded by ConvoEngine inline registration in `e7e44b80`).
    - 7 obsolete formerly generated UI keys in `Contents/mods/ProjectHoomans/common/media/translation/{EN,TL}/Conversation/UI.json` (`UI_PNC_Conversation_SemanticSuggestions_Title`, `UI_PNC_Conversation_Suggestion_Back_Label`, `UI_PNC_Conversation_Suggestion_Identity_{Lie,Real,Rude}_Utterance`, `UI_PNC_Conversation_Suggestion_Trade_{Label,Utterance}`).
  - Classified 10 active non-`Text/` Conversation translation catalog pairs in `ProjectHoomans` (`Flows`, `Patterns`, `Identity/Responses`, `Journal/Events`, `PBrainZ/Interface`, `Semantic/{Addressing,Availability,Realizations,Responses}`, `Telemetry/Diagnostics`, `WorldEvents/Events`) as preserved package-maintained catalogs referenced by runtime Lua/tests.
  - Identified a key-ownership lookup bug in `conversation_translation_catalogs_by_owner()` where `question.wellbeing` and `question.activity` UI suggestion keys resolved against `model["locations"]` before `model["uiLocations"]`, misattributing Core UI keys to `ProjectHoomans`.

## Parent completion boundary

The parent goal remains IN PROGRESS until G0–G6 are accepted.

## Next Chunk

**G1 — Add the compact CodeBuilder generation recipe, schema validator, and desired-artifact ledger in PsychopatzCore.**

1. Create `psychopatzCore/tools/semantic_harness/codebuilder/generation_recipe.json` and recipe loader/validator failing closed on unknown owners, generators, or policies.
2. Fix the `uiLocations` lookup precedence in `conversation_translation_catalogs_by_owner` so Core UI keys are owned by `PsychopatzCore`.
3. Build the effect-free desired-artifact ledger (`owner`, `surface`, `path`, `artifact_kind`, `source_lineage`, `cleanup_policy`, `content_fingerprint`, `generated_keys`) covering all enabled owners and artifact families before any filesystem mutation.
4. Validate with unit tests in `psychopatzCore`.
