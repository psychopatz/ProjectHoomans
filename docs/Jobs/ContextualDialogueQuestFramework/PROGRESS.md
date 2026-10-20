# Contextual Dialogue & Quest Framework — CURRENT B-phase Progress

**Updated:** 2026-10-20 after B6 acceptance. **B0–B6 DEVELOPER-ACCEPTED; READY FOR USER LIVE TEST.**
**Working checkout:** `codex/contextual-dialogue-quest-framework-0a`, implementation commit `1a10ac0a9f6d868e1a84dcde1710ca4bb99928e0` (B6 acceptance).
**Paired PsychopatzCore:** `2179ee19307a993e186e6da661ad4212e984e0b4` on clean `main`.
**Parent completion contract:** B0–B6 developer acceptance is complete. Native Project Zomboid SP/MP/live validation remains user-owned and is explicitly not claimed here.

## Historic acceptance (preserve unchanged)

C7A–C7G previously marked READY FOR USER LIVE TEST after the archived agent-reported 244/244 Python harness, 68/68 Lua smoke, 16/16 compiler, reviewed lexicon, doctor and Kahlua evidence. That historic acceptance does not cover B0–B6 personal history, disclosure, dossier or sparse-persistence requirements.

## B0 — ACCEPTED: compliment vs inventory arbitration + backstory replay feasibility

### Source-backed behavior

- `nice dress` now parses as `COMPLIMENT` using the compositional `COMPLIMENT_ADJECTIVE + COMPLIMENT_FEATURE` grammar and produces the actual local NPC response `Oh. Thank you, that's kind of you.` with zero actions and zero transport.
- `you got nice dress` and `you got a nice dress` select the new social possession/evaluation patterns over the competing `pnc.question.inventory_you_got` candidate. The candidate ledger retains both meanings for the colloquial form, but the selected IR is `COMPLIMENT`; no `SemanticInventoryQuery` is sent.
- `have you got a dress?`, `you got any bandages?`, and `you got a dress` remain `QUESTION / INVENTORY` and use the existing `SemanticInventoryQuery` → `SemanticInventoryQueryResult` path and final inventory response.
- `you don't got a dress` and `John said you got a dress` fail closed to bounded clarification with no action or transport. EN/TL use the same semantic boundary; TL produces the translated social response while explicit inventory cues retain inventory transport.
- The fix is vocabulary/compositional grammar data, not a sentence-template list or global compliment-priority raise. Existing parser, policy, inventory adapter and response queue owners remain unchanged.

### Backstory feasibility

- The real worker loads the existing modular `common/media/.../Backstories` registry and `Memory.GetBackstoryProfile()` reconstruction. A fixed seed `90210`, class `colonist`, and NPC ID produce `former_job` and `hometown` facts; the bounded profile projection is identical after a language switch and worker restart.
- The worker’s explicit Build 42 `getDay()` engine seam was missing and is now supplied in the headless fixture; production identity/date code was not bypassed.
- Existing `chooseBackstory()` uses current bucket cumulative weights and insertion order with `PNC.Identity.Range(seed, "pnc:backstory:" .. kind, ...)`. There is no independent catalog epoch or stable selected-definition override. Adding/reordering definitions or changing weights can therefore reroll established NPC history. This is the mandatory B1 migration seam; B0 did not add persistence or Knowledge data.
- Backstory truth remains computed/lazy and no full biography or new ModData root was added.

### Evidence

- Real Core+Hoomans worker: `tools/semantic_harness/tests/test_grounded_personal_dialogue_b0.py` **5/5**; existing `test_conversational_competence_c7a.py` **4/4** in the combined run (**9/9**).
- Focused Lua smoke: `pnc_semantic_social_smoke.lua`, `pnc_semantic_inventory_dialogue_smoke.lua`, `pnc_semantic_nlu_smoke.lua` **3/3**.
- Production Kahlua verification: changed semantic catalog files **0 errors**. The headless worker files intentionally use existing `io` process/file seams and are not production-mod Kahlua targets; the verifier reports those existing harness sandbox warnings separately.
- Full Lua suite: **835/849 passed; 14 baseline failures** in unrelated building/colony UI, constants/presence mock, Kahlua persistence, held-items, MP guard, PBrainZ native-button, persisted-shell, Puppet Opera, and server-inventory presence tests. No B0-focused test failed.
- Native Project Zomboid SP/MP, Workshop installation/publication and live-game acceptance remain user-owned.

## B1 — ACCEPTED: identity-seeded backstory stability and sparse persistence

- Source commit: `9049a464cd5dcdc52d58dc1a793e4fb6c2285acc`.
- `GetBackstoryProfile()` now pins a compact identity metadata delta containing only catalog version, selection class, stable fact IDs, and optional authored stable-ID overrides. Definitions remain authoritative for values, tags, resolvers, and localized text; no biography, `facts`, `value`, or `textKey` payload is serialized.
- Existing selections remain stable when definitions are added, reordered, reweighted, or the catalog epoch advances. Removed/unavailable IDs are not silently replaced. Legacy records without metadata still reconstruct from seed/catalog and become pinned on the next profile read or durable save. Mutable residence/medical fields remain outside immutable identity metadata.
- Save/reload sanitizes the metadata contract and preserves stable IDs. Save-time pinning also covers NPCs whose backstory has not yet been queried. Client-side profile reads do not create a new truth store; server-authoritative dirty marking uses the existing registry.
- Paired PsychopatzCore SHA remains `2179ee19307a993e186e6da661ad4212e984e0b4`; no Core or DynamicTrading source change was required for this bounded Hoomans persistence slice.
- Evidence: `python3 tests/run_tests.py pnc_backstory_persistence_stability_smoke pnc_npc_foundation_normal_persistence_smoke pnc_persistence_v5_smoke` **3/3**; B0 worker suite **5/5**; focused B0 plus C7A suite **9/9**; production Kahlua verification for the four changed persistence/backstory files **0 errors**. The previously recorded full Lua baseline remains **835/849**, with the same 14 unrelated failures.

## B2 — ACCEPTED: authoritative offline backstory fact-provider bridge

- Source commit: `ffff2107fab6310381f3c2f4008029a5e2548c08`.
- Added the server-composed `npc_backstory` provider to the existing `PNC.Semantics.DialogueFacts` registry. It resolves one requested former profession, hometown, education, hobby, family, value, fear, tragedy, survival-origin, or birth fact from the authoritative NPC record and existing Memory definitions. Results carry stable fact ID, localized content, immutable marker, confidence, and provenance; unavailable authority or unspecified kinds remain unknown/ambiguous.
- Mutable residence, medical state, inventory, roster projections, and live events remain separate providers and are not accepted as immutable backstory. The existing text loader now honors an explicit EN/TL lookup while preserving English-key validation, so stable IDs survive language changes while labels localize.
- The real semantic worker now exercises the same production provider through a bounded `BACKSTORY_FACT` command. No second biography store or client truth channel was added.
- Paired PsychopatzCore SHA remains `2179ee19307a993e186e6da661ad4212e984e0b4`; DynamicTrading remains untouched.
- Evidence: real Core+Hoomans B2 worker **1/1**; combined B0+B2+C7A worker **10/10**; focused Lua fact/translation/conversation regressions **5/5**; B2 provider and server composition Kahlua checks **0 errors**; B1 persistence regressions remain **3/3**.

## EXACTLY ONE CURRENT EXECUTION CHUNK

**B3 — gradual Knowledge-backed disclosure and evidence authorization.**

1. Audit the existing `PNC_NPCKnowledge` normalization, persistence, familiarity/approval/privacy resolution, evidence, disclosure authorization, and player snapshot paths with graph traces and direct source checks; preserve their sparse per-player-character ownership.
2. Add a backstory-fact disclosure adapter that uses stable fact IDs and the existing Knowledge record, relationship familiarity, approval/privacy thresholds, evidence confirmation, refusal/uncertainty, and server authority. Threshold eligibility must never itself reveal a hidden fact.
3. Ensure authoritative semantic answers and optional PBrainZ context receive only an authorized disclosure projection, never the full NPC backstory profile or raw identity seed on an unauthorized client path. Keep current residence/medical/live facts on their existing providers.
4. Add focused server/Lua and worker tests for low/high familiarity, privacy refusal, legitimate NPC disclosure, evidence confirmation, uncertainty, server/client authority, and per-player divergence; commit, record exact SHA/results, then continue to B4.

**Authoritative design:** `GROUNDED_PERSONAL_DIALOGUE_B.md`. Continue using existing identity, persistence, Knowledge, relationship, dossier, ContextState, response-plan and PBrainZ boundaries. No parallel backstory store, player-knowledge root, per-tick profile scan, fake memory or client truth leak.

## B3 — ACCEPTED: gated disclosure, uncertainty, and player-private backstory projections

- Source commit: `2ae41e8ac770c3ab89f6bbddabd7fbfac56638cd` on the existing `codex/contextual-dialogue-quest-framework-0a` checkout. Paired source SHAs: PsychopatzCore `2179ee19307a993e186e6da661ad4212e984e0b4` (clean `main`), DynamicTrading `2d1ee62a227062457e8b233e37a7e288c6351a66` (clean); neither dependency changed.
- Added ten immutable `history.backstory.*` Knowledge descriptors with private disclosure gates, familiarity threshold 50, translated dossier labels, and the existing `pnc_backstory` truth provider. Direct disclosure enters the ordinary `direct_disclosure` evidence path and resolves to confirmed facts; familiarity only makes a fact eligible and never auto-reveals it.
- Added `PreviewBackstory`/`DiscloseBackstory` service seams and an API topic boundary (`backstory.<kind>`). The existing sparse per-character Knowledge persistence and dossier snapshot remain the only learned-fact store; snapshots contain no identity seed or generated biography. Two player-character fixtures demonstrate divergent knowledge for one NPC.
- Added compositional semantic question patterns for former work, hometown, education, hobbies, family, values, fears, tragedy, survival origin, and birthday. Undisclosed questions resolve to `unknown / backstory_not_disclosed`; authorized snapshot projections resolve to the requested fact. Optional PBrainZ context now receives only `BuildAuthorizedBackstoryFacts` from the local player dossier.
- Evidence: focused Lua suite **10/10** (`pnc_backstory_knowledge_disclosure_smoke`, persistence, semantic fact, Knowledge, PBrainZ, dialogue safety and regression tests); real Core+Hoomans worker B0+B2+B3 **7/7**; production Kahlua verifier **0 errors** across 30 server Knowledge files and 103 shared Semantic files; Python `compileall` passed; translation JSON parsed with `jq`.

## Next mandatory chunk: B4 — NPC Dossier acceptance

Exercise the existing dossier presentation with confirmed/suspected backstory evidence, EN/TL labels, per-player snapshots, and unauthorized-snapshot assertions. Verify no raw backstory truth or undisclosed descriptor crosses the client command boundary, then commit and record the exact source SHA before continuing to B5.

## B4 — ACCEPTED: dossier rendering and client privacy acceptance

- Source commit: `d9ef8f09eb517870d47993502a620b7de956748b` (test-only acceptance extension on top of B3 `2ae41e8ac770c3ab89f6bbddabd7fbfac56638cd`). The existing dossier and snapshot production seams were sufficient; no duplicate UI or truth store was introduced.
- The acceptance smoke verifies confirmed backstory rows render in the existing descriptor-driven dossier, suspected rows retain uncertainty (`Possibly ...`), EN/TL `labelKey` translation is used, per-player snapshots diverge, and snapshot descriptors contain no identity seed or biography table. Existing client/server presentation code remains snapshot-only.
- Evidence: `python3 tests/run_tests.py pnc_backstory_knowledge_disclosure_smoke pnc_knowledge_smoke` **2/2**; the complete B3 focused set remains **10/10** and the real worker B0+B2+B3 remains **7/7**.

## B5 — ACCEPTED: personal conversation continuity

- Source commit: `e0b7a47c653dc5c95fab97823d38725b4e862670`. ContextState now retains the last backstory kind as a bounded conversational pointer, including snapshot/reload and reset behavior; it stores no fact value or biography.
- Grounded local responses now answer known, suspected, ambiguous, and undisclosed backstory questions with kind-specific actual NPC text, fact references, uncertainty and deterministic `FACT_ANSWER` metadata. Hometown follow-ups no longer fall through to generic “what do you mean?” clarification: a context reference reuses the last authorized subject and re-runs the existing fact provider against the player-specific snapshot.
- Disclosure-result text from the existing client command route is recorded into the same ContextState as an NPC answer, so a server refusal or successful disclosure remains honest and available to a subsequent follow-up. No raw identity seed, full profile, or unauthorized fact enters the context.
- Evidence: focused Lua `python3 tests/run_tests.py pnc_semantic_local_response_questions_smoke pnc_semantic_fact_smoke pnc_semantic_dialogue_input_smoke pnc_semantic_local_route_smoke pnc_conversation_smoke pnc_backstory_knowledge_disclosure_smoke pnc_semantic_backstory_fact_smoke` **7/7**; real Core+Hoomans worker B0+B2+B3 **7/7**; production Kahlua verifier **0 errors** across 103 shared Semantic files and the changed client lifecycle file. The worker’s existing optional-provider warning remains non-fatal and no B5 test entered the provider route.

## B6 — ACCEPTED: persistence, scaling, compatibility and complete developer acceptance

- Source commit: `1a10ac0a9f6d868e1a84dcde1710ca4bb99928e0`. Added a bounded acceptance smoke around the production `PNC.Persistence.SaveAll` collection serializer and the same deterministic worker encoder used to inspect serialized payload bytes. The test creates 100 persistent NPC records and a 1,000-NPC synthetic population, verifies stable identity-seeded selection IDs, confirms no `value`, `textKey`, `facts`, or generated biography is serialized, and checks approximately linear growth.
- Measured headless serialized payload: **2,664 bytes** for one record, **587 bytes** for the sparse backstory metadata, **269,760 bytes** for 100 records, and **2,706,037 bytes** for 1,000 records. The 1,000-record probe completed in **0.59 seconds** in the bounded Lua test runner. Save pinning invoked `EnsureBackstoryMetadata` without invoking `GetBackstoryProfile`; a profile is reconstructed only on the explicit dialogue/provider read.
- B1 save/reload, catalog-version growth, stable-ID override, legacy reconstruction, and language/reload worker checks remain green; B2 authoritative former job/hometown/hobby/family/fear/tragedy/survival/birthday coverage remains green; B3/B4 verify server authorization, refusal/uncertainty, Knowledge evidence, per-player divergence, dossier labels/status, and no identity-seed/full-biography snapshot leak; B5 verifies grounded response-plan/context continuity and authorized follow-ups. Optional PBrainZ receives only the authorized player snapshot projection.
- Focused integrated Lua suite: **17/17** (`pnc_semantic_social_smoke`, inventory/NLU arbitration, B1 persistence, B2 fact provider, B3 Knowledge/PBrainZ/safety, B4 dossier, B5 continuity, and B6 scaling). Real Core+Hoomans worker B0+B2+B3: **7/7**. Full semantic-harness Python discovery: **passed**. Production Kahlua verification: **0 errors** across 30 server Knowledge files and 24 shared Persistence files; the existing 103-file shared Semantic check also remains **0 errors**.
- Full Lua regression runner: **839/853 passed; 14 known baseline failures**, limited to existing building/colony UI, constants/presence mock, Kahlua persistence, held-items, MP guard, PBrainZ native-button, persisted-shell, Puppet Opera, and server-inventory presence tests. No B0–B6-focused test failed.
- Dependency SHAs remain PsychopatzCore `2179ee19307a993e186e6da661ad4212e984e0b4` on clean `main` and DynamicTrading `2d1ee62a227062457e8b233e37a7e288c6351a66` on clean `main`; neither dependency changed. No new Git branch was created.
- Native Project Zomboid save/load, SP/MP authority, Workshop installation/publication, and live-game dialogue remain user-owned validation. This developer acceptance does not claim those native checks passed.

## Parent goal — DEVELOPER IMPLEMENTATION COMPLETE; READY FOR USER LIVE TEST

B0–B6 developer-implementable requirements are implemented and accepted on the existing checkout above. The parent goal is complete for the developer/test boundary and is ready for the user-owned native Project Zomboid SP/MP live test. It is not claimed to be integrated into `main` or published to Workshop.
