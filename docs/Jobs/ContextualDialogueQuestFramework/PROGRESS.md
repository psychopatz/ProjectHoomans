# Contextual Dialogue & Quest Framework — CURRENT B-phase Progress

**Updated:** 2026-10-20 after B0 implementation. **B0 ACCEPTED; B PHASE IN PROGRESS.**
**Working checkout:** `codex/contextual-dialogue-quest-framework-0a`, implementation commit `3f263757bc07cfa25b4d3e3dd16ca4c5d4d20890`.
**Paired PsychopatzCore:** `2179ee19307a993e186e6da661ad4212e984e0b4` on clean `main`.
**Parent completion contract:** B0–B6 remain mandatory. This ledger records the current safe chunk only; after each accepted chunk continue immediately to the next unaccepted chunk in the same goal. The parent goal is not complete until integrated developer acceptance passes B6.

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
