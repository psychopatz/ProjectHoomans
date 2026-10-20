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

## EXACTLY ONE CURRENT EXECUTION CHUNK

**B2 — authoritative offline backstory fact-provider bridge.**

1. Audit the existing `PNC_Conversation_Memory_BackstoryContext`, Semantic Dialogue fact providers, and current B2 conversation consumers with graph traces plus direct source checks.
2. Expose former profession, hometown, hobby, family, fear, and established-event facts through the existing offline provider contract using stable IDs and localized text resolution; keep immutable background separate from current residence, medical state, inventory, and live events.
3. Add deterministic provider tests for identity seed/reload, missing definitions, resolver-backed facts, EN/TL labels, and no fabricated facts. Preserve the B1 metadata/persistence contract and avoid a second profile or fact database.
4. Verify with the real Core+Hoomans worker, focused/full relevant Lua suites, Kahlua checks, and source coverage; commit the coherent B2 slice, record exact SHA/results, then continue to B3.

**Authoritative design:** `GROUNDED_PERSONAL_DIALOGUE_B.md`. Continue using existing identity, persistence, Knowledge, relationship, dossier, ContextState, response-plan and PBrainZ boundaries. No parallel backstory store, player-knowledge root, per-tick profile scan, fake memory or client truth leak.
