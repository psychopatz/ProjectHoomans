# Project Hoomans Translation Audit

Build target: Project Zomboid 42.20. Target language: `TL` (Tagalog/Filipino).

## Canonical sources

- Native PZ domains: `common/media/lua/shared/Translate/EN|TL/Sandbox.json` and `ItemName.json`.
- Hoomans custom catalogs: `common/media/translation/EN|TL/<System>/<System>.json`.
- Conversation catalogs: `common/media/conversation/**/EN|TL/*.json`.
- Resolver/bootstrap: `42.20/media/lua/shared/PNC/Translation/PNC_TranslationBootstrap.lua`.
- Reusable manager: PsychopatzCore `CustomTranslationManager`.

The retired Hoomans `UI.json`, flat `Traits.json`, and 42.20 `.txt` translation files are not present. No Hoomans custom catalog is stored under native `Translate`.

## Inventory

| Area | EN | TL | Result |
| --- | ---: | ---: | --- |
| Custom systems | 2,315 | 2,315 | exact key parity |
| Native Sandbox | 151 | 151 | exact key parity |
| Native ItemName | 1 | 1 | exact key parity |
| Conversation files | 53 | 53 | exact file parity |
| Conversation keys | 724 | 724 | exact key parity |

All catalog values are non-empty and preserve their indexed/brace placeholders. Runtime-generated namespaces audited include knowledge categories and journal events, settlement overlay roles, storage reasons, wound types, jobs, skin tones, and flavor stems.

## Call-site audit

- Hoomans UI `UI_PNC_*` lookups use `PNC.Translation.GetKey`/`TrFormat`.
- `PNC_TranslationBootstrap` maps all 407 catalog key segments to one of 15 modular systems.
- `Translator:getLanguage():toString()` selects the active language; English is the file and per-key fallback.
- Genuine PZ-native keys may still use the engine `getText` API through the Hoomans facade.
- No unqualified global `getText(...)` call remains. Widget methods such as `entry:getText()` are input reads and are intentionally unrelated.
- Radio/discovery presentation, native ModOptions labels, traits, conversation files, and tool-only NPC replies are routed through the same translation boundary.
- Custom radio lines carry an owning source and fallback into Core's message selector; the selector resolves the active language before native broadcast and compact client delivery.
- The Core audit setting is runtime-toggleable through Debug Settings as `PsychopatzCore.TranslationAudit`.
- With the audit enabled, Core records and deduplicates `english_key_fallback`, `english_catalog_fallback`, and `english_value_fallback` events. The last category catches a localized entry that exists but is still the same multi-word English prose as its EN counterpart, including conversation text.

## Content audit results

Structural parity does not mean every Tagalog value is translated. The 182 authored prose values among the 184 identified multi-word equal entries were translated in this batch across `whats_up`, greetings, needs, ask-about, trade, relationship, small-talk, goodbye, work-orders, and conversation-category/debugger content. Two technical debugger templates were retained (`SANDBOX persisted=false networked=false` and `{id} [{audiences}] — {status}`). A direct EN/TL comparison now finds 17 identical conversation values: 15 single-word/status or technical values, plus those two templates.

The completed content groups were:

- `whats_up`: 119 values, including local activity, supply pressure, and survivor-rumor exchanges.
- `greetings`: 24 flavor lines.
- `needs`: 8 gift and supply lines.
- `ask_about`, `trade`, `personal`, `relationship`, `small_talk`, `work_orders`, and `goodbye`: 17 values combined.
- `system`: 14 authored category/debugger values; the two remaining debugger templates are technical status output rather than prose.

The other 15 same-value entries are proper names, technical abbreviations, common game terminology, punctuation, or short status values such as `Project Hoomans`, `NPC`, `Telemetry`, `HQ`, `BASE`, `Trade`, `valid`, and `%1 (%2)`. Mixed-language Tagalog values are also present and require editorial review; equality checks intentionally do not classify those automatically.

The static call-site audit also found a smaller legacy UI backlog that is not a catalog-parity problem. The knowledge context menu was migrated in this pass; the remaining items are concentrated in debug/admin and diagnostic surfaces, especially `PNC_NPCMonitor.lua`, base-building rows/catalog, settlement facility browser, scavenge/nameplate debug windows, and a few Character-window relationship labels. These should be migrated in a separate batch because some labels are debug-only while others are player-facing.

## Migration plan

1. Finish the player-facing legacy UI backlog, starting with context-menu labels and Character-window relationship/interaction labels; keep debug-only labels in the same Core-backed catalog but mark them separately for review.
2. Review the remaining mixed-language conversation values and decide whether the two technical debugger templates should stay protocol-shaped or receive localized labels. Do not treat a partially translated sentence as complete.
3. Re-run catalog parity, placeholder, syntax, and focused runtime tests after each branch. With `PsychopatzCore.TranslationAudit` enabled, exercise each branch once and use the deduplicated warning snapshot as the acceptance list.
4. Do the final interactive check in Tagalog for the conversation window, radio contact/discovery window, NPC character tabs, and legacy diagnostic menus. This is needed to catch labels constructed from data or supplied by third-party/native UI APIs.

## Verifier note

`pz_verify` completed with 0 Kahlua findings. Its native translation heuristic reported 105 files / 629 strings because it does not index Core-backed JSON catalogs and therefore counts English fallback literals, PZ-native keys, body-part IDs, and debug/data labels. The report is retained at `/tmp/projecthoomans_pz_verify_current.txt`; the catalog/parity checks above are authoritative for the migrated source of truth.

## Validation

- `jq empty` over all Hoomans JSON: pass.
- `luac -p` over all 42.20 Lua: pass.
- Focused translation/catalog/conversation/traits tests: pass, including the equal-English-value warning path and Core ConversationText integration.
- Full harness: 597/598 pass. The sole failure is the pre-existing `pnc_bump_action_lease_smoke` native passage reset assertion (`climbwindow` remained instead of `idle`); it has no translation-related diff.
- Build 42.20 runtime directory was detected locally. Interactive in-game UI verification was not run by the non-interactive harness.
