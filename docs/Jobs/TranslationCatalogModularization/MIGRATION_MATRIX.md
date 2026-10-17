# Conversation catalog migration inventory and ownership plan

## Baseline (source-inspected, not runtime verified)
ProjectHoomans main at `c96cadda`: `common/media/translation/EN/Conversation/Conversation.json` 495 keys / 42,644 bytes; TL 495 keys / 44,998 bytes. Implementation branch at `fd852d74`: EN 521 / 45,222 bytes and TL 521; current agent must recompute all values after safely choosing an integration base. Do not migrate only 495 keys and silently drop new phase-related variants.

Main EN family sample counts (classed by key prefixes; reclassify against actual source and consumers):

| Candidate bundle owner | Observed key count | Notes |
| --- | ---: | --- |
| Flavor/Emotes | 144 | `UI_PNC_Flavor_VanillaEmote_*` |
| ToolReplies/* | 76 | `UI_PNC_Conversation_ToolReply_*`; split by actual action owners |
| Flavor/Greetings | 48 | `UI_PNC_Flavor_SocialGreeting_*` |
| Telemetry/* | 40 | `UI_PNC_Conversation_Telemetry_*` |
| Semantic/* | 36 | `UI_PNC_Conversation_Semantic_*`; count larger on newer branch |
| WorldEvents/ProjectALife | 20 | `UI_PNC_Conversation_ProjectALife_*` |
| WorldEvents/Zombies | 26 | ZombieHorde and ZombieRetreat |
| Other flavor/journal/medical/UI | remainder | Inspect call sites to assign ownership; no blind automated guessing |

## Mandatory before/after extraction record
Build a machine-readable manifest/table in the *implementation* stage (not a new runtime truth source) listing `key, owner bundle, EN value, TL value, placeholders, original path, consumer(s)`. Record global key count, duplicates, missing/extra keys, changed values and drift across the latest semantic branch. Do not check in a generated mega-JSON in lieu of intended fragments.

## Ordering
0. Capture exact HEAD EN/TL system inventories and current registered systems/segment mappings; locate Trading consumers.
1. Prove Core loader's optional manifest mechanism independently with fixture and old-system regressions.
2. Migrate one small representative conversation shard first (e.g. Identity), toggled explicitly and tested with real production Semantic Lab; keep old source canonical until activation is proved.
3. Migrate remaining `Conversation` families in independently verifiable patches: wellbeing/social -> tool replies -> flavor -> world events -> telemetry/journal/medical. Keep existing calls/key identifiers.
4. Only after exact parity and EN/TL native lookup checks, retire old Conversation monolith and record published manifest/translation ownership.
5. Consider `Debug.json` / `Settlement.json` later as optional independent owner projects, **not** within this first goal's mandatory scope.

## Do not conflate systems
The 53 EN/TL authored conversation bundles and 724 conversation keys reported in historical `docs/Systems/TranslationAudit.md` belong to a **different** conversation loader. Do not count or migrate these as entries of `Conversation/Conversation.json`; preserve both systems' baseline counts separately.
