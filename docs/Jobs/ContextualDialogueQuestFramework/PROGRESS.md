# Contextual Dialogue & Quest Framework — CURRENT B-phase Progress

**AUDIT REFRESH 2026-10-20 (GitHub read-only):** ProjectHoomans existing goal branch `9b123bd352b0` / main `bc9c64d0fbf6`, Core main `298df66381b7`, DynamicTrading main `2d1ee62a2270`. **Core Foundation P1–P9 code/adapter commits exist and are developer-accepted per Core ledger, but native game integration remains unverified.** Hoomans B0–B6 is NOT implemented/accepted on audited remote HEAD and remains the entire mandatory parent goal. Do not conflate Foundation acceptance with personal-dialogue acceptance. The previous snapshot below is historical evidence, not the current repository HEAD.

**NO-NEW-BRANCHES POLICY:** Follow root AGENTS and `GIT_INTEGRATION_AND_NO_NEW_BRANCHES.md`. PR #4 remains open; existing goal branch is 144 ahead/1 behind main. No new branches for sync, code, tests or docs. Safely review/converge existing history onto existing main before claiming main integration; don't skip product implementation while awaiting a safe integration window.

**ONE CURRENT CHUNK: B0. FULL PARENT ASSIGNMENT: B0–B6 WITHOUT STOPPING BETWEEN CHUNKS.** Finish the compliment-vs-inventory false dispatch and read-only identity-seed replay, then automatically continue B1–B6. The developer goal is NOT READY until offline semantic backstory facts, Knowledge disclosure, dossier, conversations, PBrainZ privacy and ModData/MP gates are satisfied.


**Updated:** 2026-10-20. Documentation-only approved phase transition; NO new source implementation or runtime test passes.
**Audited remote:** `263c132ea87678024cd81f8310bb85608dec28df`, branch `docs/contextual-dialogue-quest-framework-20261018`, PR #4 OPEN/unmerged at inspection. Local Codex checkout/Core state/parallel changes unknown: verify before edits.
**Status:** **B PHASE — IN PROGRESS, NOT READY FOR USER LIVE TEST FOR THE EXPANDED PERSONAL-KNOWLEDGE GOAL.**
**PARENT COMPLETION CONTRACT:** Finish ALL developer-owned B0–B6 features and integration/MP privacy/ModData acceptance; after B0 immediately continue B1 and so forth within the SAME /goal. Subphase success is not parent-goal completion. Final developer handoff only after B6, absent a genuine blocker.
**EXACTLY ONE CURRENT EXECUTION CHUNK: B0 — Compliment vs Inventory arbitration + identity-seeded backstory read/replay feasibility.**

## Historic acceptance (preserve unchanged)

C7A–C7G previously marked READY FOR USER LIVE TEST after *agent-reported* 244/244 Python harness, 68/68 Lua smoke, 16/16 compiler, 1/1 reviewed lexicon, doctor PASS and 0 Kahlua/i18n errors. That prior progress record, including SHA evidence and native PZ user boundary, is archived unmodified in `HISTORY_C7_20261020.md`. Older R/S/C ledgers remain. This is NOT a new failure of all previous work, nor proof of the newly proposed personal dialogue integration.

## New user observation and code-backed findings

The newer Semantic Lab screenshot: `nice dress` → "I'm not sure what you mean"; `you got nice dress` → "I don't have any nice dress." and erroneous `query_inventory [SemanticInventoryQuery] · sent`. Trace shows `QUESTION/INVENTORY`, `pnc.question.inventory_you_got`, confidence 0.88. Source has permissive `you got [any_phrase]` inventory matching and narrower compliment grammars; exact arbitration cause needs fresh current-worker trace, not speculative priority tweak.

Existing `Memory.GetBackstoryProfile` and `BuildBackstoryFacts` derive NPC history lazily from seed/class; current `chooseBackstory` weighted bucket selection could shift with catalog edits. Existing PBrainZ path uses generated backstory facts, but offline semantic disclosure to the **server player-scoped Knowledge** store was not established in read-only audit. Current `PNC_NPCKnowledge` already owns descriptor-level CanDisclose/familiarity/approval/direct evidence and discovered-only Dossier snapshots. Do not duplicate those owners.

## B0 exact implementation

1. Inspect local HEAD, branch/upstream, Core pairing, dirty files/parallel agent edits; read root AGENTS then job docs and phase design, PROGRESS LAST. Confirm genuine production Lua worker/Catalog version and existing test fixtures.
2. In a single actual worker scenario capture candidate IR, question evidence, selected rule, final NPC reply and transport for `nice dress`, `you got nice dress`, `you got a nice dress`, `have you got a dress?`, `you got any bandages?`, `you got a dress`, with negation, quotes/third party and EN/TL as applicable.
3. Correct **existing** social-vs-inventory semantic arbitration with reusable meaning/grammar evidence; prevent false inventory transport for positive apparel evaluations; explicit inventory questions must still route normally; ambiguous statements clarify if warranted. No hack that globally privileges compliments or adds dozens of literal scripts. Preserve STAY/INSULT/GIFT/QUEST/NEWS and Preview purity.
4. Independently run read-only backstory feasibility in worker: same npcID/identitySeed/class resolves stable former_job/hometown under same catalog, survives reload and has no extra full-profile persistence. Record any existing version/weighted-bucket risk and proposed migration owner; do NOT implement B1 epoch/deltas, B2 providers, B3 Knowledge gates or B4 UI in B0.
5. Run real Lua worker tests and final displayed replies + effect counts, focused semantic/social/inventory tests, Lua smoke, EN/TL/doctor/Kahlua/`pz_verify`, source and generated-diff sanity. Record exact Core/repo SHA, mock-vs-native authority, current failures and saved bytes baseline where possible.
6. Commit coherent code/tests/PROGRESS on authorized current branch with safety checks. If accepted select ONLY **B1 — seed and catalog-revision stability**, otherwise B0 remains open with exact reproducible blocker. Never use user-owned native PZ/Workshop acceptance as a developer step.

**Authoritative design:** `GROUNDED_PERSONAL_DIALOGUE_B.md`. No new parallel player knowledge root, per-tick profile scans, fake memories or client server-truth leaks.
