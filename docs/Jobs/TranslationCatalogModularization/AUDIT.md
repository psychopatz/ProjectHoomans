# Translation system source audit — 2026-10-17

## Evidence class
Static GitHub inspection only for this goal. ProjectHoomans main `c96cadda1570f59810552f9d3fc55d5c957ba670`, existing semantic implementation branch `fd852d746241d7e2f61df1c349ff63754afbe5ed` (unmerged at audit), PsychopatzCore main `efac85a182c86fdb07e7da7ccd693e1a6e66ccc6`. Historical validations in `docs/Systems/TranslationAudit.md` are **recorded**, not newly run here.

## Verified existing design
- Project Hoomans custom system catalogs live at `Contents/mods/ProjectHoomans/common/media/translation/EN|TL/<System>/<System>.json`. Fifteen systems are listed in `PNC_TranslationBootstrap.lua` and the 422-line `PNC_TranslationBootstrap_Segments.lua` maps many first-key segments to those systems.
- `Conversation/Conversation.json` on main has **495 EN keys**, about **42,644 bytes**, and the TL file **495** keys, about **44,998 bytes**. The active semantic feature branch has **521 EN and 521 TL** keys, EN ~45,222 bytes. The feature branch has newer variations and must be reconciled before migration; never extract main's older catalog in place of that work.
- Main Conversation top-family counts include vanilla emotes 144, tool replies 76, social greetings 48, conversation telemetry 40, semantic responses 36, and Project A-Life 20. These are appropriate shard candidates. Authoring segments and exact counts must be recomputed on selected implementation HEAD.
- `Trading/Trading.json` has EN/TL keys but `Trading` is absent from bootstrap's declared `SYSTEMS` and `Trading`/`Trade` is absent from its segment map. Runtime call-site reachability/actual lookup result are **unverified**; capture a failing or passing worker case before repairing.
- PsychopatzCore `PsychopatzCustomTranslationManager.lua` creates one path `media/translation/<LANG>/<SYSTEM>/<SYSTEM>.json` per registered system, with a flat legacy fallback. It uses `getModFileReader`, guarded JSON validation, lazy system-load caching, EN fallback, localization coverage diagnostics and language overrides. No nested manifest/shard discovery is implemented.
- Limits include 1 MiB/file, 4096 catalog entries, 160-character keys and bounded coverage snapshots. Existing Core `registerSystem`/scoped `get` APIs must remain compatible.
- Project Hoomans `tests/pnc_translation_catalog_smoke.lua` explicitly expects one file per system; update its baseline requirements as part of migration.
- Existing `common/media/conversation/**/EN|TL/*.json` is already a separate authored-dialogue system with explicit pathPattern registration and `PNC_ConversationTextLoader`. The two systems have different ownership. PZ does not recursively discover either.
- `tools/semantic_harness/lua/worker/Translations.lua` already instruments production translation lookups/language/fallback traces. Use it rather than building a Python-only resolver.

## Audit risks
- Moving files before registering support breaks lookups and can cause silent English fallbacks.
- Merely retaining old plus new copies risks diverging text and ambiguous key provenance; use a versioned/explicit migration mode.
- A new multi-file Core reader can regress unrelated mods, translation coverage, localized fallback and packaged-mod file reading.
- Hardcoded first-prefix segment ownership does not scale when new subsystems have multiple keys; preserve old aliases while introducing declarative ownership.
- File-system recursive scans are unsuitable for packaged PZ; use an explicit finite manifest.
- Translation parity is not *semantic dialogue acceptance*: the exact production response must still resolve in both EN and TL.

## Audit verdict
Add an optional, explicitly registered, backwards-compatible Core multi-file catalog capability first; then migrate Project Hoomans Conversation in reviewable groups. Do not rewrite old translations or treat a shard tree as implemented until real Core and Project Hoomans workers load it. Native SP/MP localization acceptance is separate.
