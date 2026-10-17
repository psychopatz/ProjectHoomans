# Translation Catalog Modularization — stable architecture proposal

## Source of truth and loader contract
- Source catalogs remain **flat JSON key/string objects**, now in explicit EN/TL *nested shards*. One canonical home per key.
- Author an exact ordered **language-neutral manifest** containing a system ID, format version and an array of relative paths or explicit key-prefix ownership; no unbounded filesystem recursion and no ad-hoc runtime directory enumeration.
- PsychopatzCore offers an **optional multi-file catalog registration**/manifest reader without changing legacy `registerSystem`, `scope.get`, `load`, fallback, diagnostics or native engine contracts. API signature is a proposal until Core tests approve it.
- On request, a system can read manifest once, construct bounded key-to-shard ownership, and load/cache the requested shard. Full audit/coverage may intentionally enumerate all declared shards. If no cheap exact key map is feasible, load the system manifest's shards once on first system use and cache results; measure both approaches before choosing.
- All files read with `getModFileReader(modID, path)`; explicitly bound sizes, file count, key count, path traversal and duplicate-key behavior. `EN` must be available; selected language falls back per-key to `EN` with original warning provenance.
- If manifest and original monolithic system catalog both exist during migration, an explicit activation mode chooses exactly **one** source; never silently merge/shadow duplicate keys across them. Keep rollback possible until gates pass; remove old source only after parity and runtime proof.

## Project Hoomans folder proposal
    Contents/mods/ProjectHoomans/common/media/translation/
      manifests/Conversation.json
      EN/Conversation/
        Identity/Responses.json
        Semantic/Wellbeing.json
        Semantic/Social.json
        ToolReplies/Identity.json
        ToolReplies/Commands.json
        Flavor/Greetings.json
        Flavor/Emotes.json
        WorldEvents/Zombies.json
        Telemetry/Diagnostics.json
        Journal/Events.json
      TL/Conversation/
        (same relative paths as EN)

Folder names are **illustrative**, not a prescribed split; recompute actual key families on the selected revision and use one file per meaningful owner/variant family. Preserve stable original keys such as `UI_PNC_Conversation_Semantic_QuestionWellbeingUnknown`.

## Registration and routing
Hoomans `PNC_TranslationBootstrap.lua` must continue supporting `PNC.Translation.GetKey`, `Get`, `Tr`, `TrFormat` and legacy system handles. Its existing `SegmentSystems` first-prefix mapping can remain as a compatibility route but must not require adding hundreds of entries per response variant. New flow bundles can declare prefix or explicit key ownership through stable reviewed metadata. Generic Core loader does not contain PNC-specific prefixes.

## Localization requirements
- EN/TL **same relative paths** and expected key/placeholder parity; no silent deletion/rewriting of English or Tagalog authored lines.
- Validate `%1`, `%s`, `{name}`, numbered/named placeholders, syntax and escaping in every shard.
- Preserve correct active language from native `Translator` or harness override, lazy cache invalidation on language changes, explicit EN fallback and warning audit provenance.
- Keep authored `common/media/conversation/` bundles distinct; they use a separate ConversationText registration system.
- Keep native `common/media/lua/shared/Translate/<LANG>/*.json` undisturbed for engine-owned keys.
- Do not create a new giant generated consolidated JSON as the only editable source; if a packaging compatibility artifact is absolutely needed, it must be deterministic generated output with verified parity, never edited directly.
- Avoid file-watcher temporary **directories** under live Build 42 `media/`; use repository `AGENTS.md`.

## Cross-job API
Read-only `docs/Jobs/SemanticDialogueOrchestrator/INTEROP.md` is the canonical shared contract. Orchestrator chooses **stable translation keys**; this job chooses owning shard/path and localized wording. Neither owns the other's decision policies.

## Performance
Index manifests on initialization or first use, bounded cache by mod/system/language/shard; no disk reads or JSON parsing per utterance. Record cache hit/miss, files read and memory/latency delta in a real Lua test; no new per-NPC per-tick translation polling.
