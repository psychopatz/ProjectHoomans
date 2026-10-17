# Modular custom translation catalog — internal phase of ONE goal

## Current source truth
Inspected Hoomans `105dadedd31c57be64a3622c4a1f6d2d6f402d35`: `common/media/translation/EN/Conversation/Conversation.json` = **521 keys / 45,222 bytes**; `TL/Conversation/Conversation.json` = **521 keys / 47,704 bytes**; currently no missing/extra key **names** between these two. Preserve values and placeholders as well as keys when migrating.
`PNC_TranslationBootstrap.lua` registers 15 top-level custom systems. Core `PsychopatzCustomTranslationManager.lua` currently loads one `media/translation/<LANG>/<SYSTEM>/<SYSTEM>.json` per registered system, with lazy caching and English fallback. No recursive shard discovery. The separate authored `common/media/conversation/**` and native PZ `common/media/lua/shared/Translate/**` stay untouched.

## Target (illustrative; inventory/call-site ownership decides exact split)
```text
Contents/mods/ProjectHoomans/common/media/translation/
  manifests/Conversation.json
  EN/Conversation/
    Identity/Responses.json
    Semantic/Wellbeing.json
    Semantic/Social.json
    ToolReplies/Commands.json
    Flavor/Emotes.json
    Flavor/Greetings.json
    WorldEvents/Zombies.json
    Telemetry/Diagnostics.json
  TL/Conversation/
    (identical relative shard paths and expected key ownership)
```

## Migration architecture
1. Baseline the **latest** EN/TL full key->value and placeholder signatures, including new semantic replies; classify keys by actual consumer/owner instead of only prefixes.
2. Extend **PsychopatzCore** with an *optional, backwards-compatible* finite manifest/multi-file reader only after focused Core tests prove old `registerSystem`, `get`, lazy read, fallback, diagnostics and language-switch contracts. Never scan directories at runtime or on each dialogue turn.
3. Hoomans adopts an explicit manifest mode. Use bounded safe relative paths, unique bundle ownership, max shard/file/entry limits, deterministic ordering and duplicate-key failures. English must be available; missing TL keys use visible audited English fallback.
4. One small shard pilots actual Hoomans `PNC.Translation.GetKey/TrFormat` and the real Semantic Lab worker in EN and TL. No two simultaneously editable sources: an explicit source-mode switch selects exactly one canonical catalog during migration.
5. Migrate the remaining 521-key *current baseline* in bounded families while retaining stable key/value/placeholder parity. Remove old monolith only **after** full audited migration and native game check where required.
6. A new dialogue module thereafter adds/edits the appropriate small bundles, not the giant Conversation.json. Core continues supporting legacy external mods.

## Mandatory assertions
- Union of every EN/TL key before/after, exact value parity (unless a separately reviewed editorial change), numbered/printf/brace placeholder signatures and no duplicate ownership; same relative shard-file layout across languages.
- Existing Hoomans non-Conversation custom systems and Core consumers resolve without regressions; inspect the EN/TL `Trading/Trading.json` registration question with an actual consumer/lookup test before calling it a bug.
- Core real Lua loader tests for malformed manifest, traversal, missing EN shard, duplicate key, missing TL translation, language change, cache invalidation, warmed lookup (no extra reader IO) and audit coverage.
- Production Lua Semantic Lab resolves identity, wellbeing, tool reply and existing response variation keys in EN/TL. Mock worker must use real loader modules, not Python-only JSON merges.
- Native Build 42 SP/MP packaged-mod translation, language switch/restart and fallback are separate acceptance.
