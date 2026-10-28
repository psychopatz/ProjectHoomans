# Progress — Unified Semantic Evidence Architecture

**Status:** DEVELOPER COMPLETE — E0–E7 accepted; READY FOR USER LIVE TEST.
**Branch:** existing main.
**Planning anchor:** ProjectHoomans `2bc4810f`.
**Implementation head before final E7 commit:** `32ea7359`.
**Current phase:** developer acceptance complete.
**Next authority:** user-owned native Project Zomboid SP/MP verification only. Reopen the smallest owning phase if live evidence contradicts an accepted invariant.

## Final developer acceptance — 2026-10-28

The parent developer objective is complete:

- one normalized semantic-evidence pipeline spans SESSION, TODAY and DURABLE sources through existing InteractionProviders / InteractionContext;
- first-party social-event semantic/retention metadata is canonical rather than separately authored memory metadata;
- retention salience is distinct from confidence, effective strength/decay, recency, contextual relevance and deterministic priority;
- TODAY storage remains the existing bounded numeric `record.memory.s/t` projection and is salience-aware under pressure;
- compact TODAY recall survives detailed relationship-memory pruning/saturation;
- durable evidence is queried through owning Relationship / Conduct domains; `interactionJournal` is not semantic authority;
- generic registered relations drive repair, gratitude and response-family admission without feature-specific memory managers;
- generated player choices and NPC behavior consume the same admitted pragmatic evidence;
- the removable future-mechanic fixture proves promise/commitment-style semantics can adopt the architecture through registration only, with no generic resolver/query branch or new store;
- contextual relevance, plans, realized dialogue, generated choices and transcript text remain runtime-only.

## E7 scale/storage evidence

Recorded in `E7_STORAGE_MEASUREMENTS.json` using canonical JSON serialization of production owner records:

- TODAY event rows plateau at 8;
- compact durable rows plateau at 6;
- Relationship memories plateau at 20;
- Conduct evidence plateaus at 64;
- topic players remain bounded at 4 in the tested store;
- repeated event/target pairs coalesce;
- high-salience rescue evidence survives lower-salience churn;
- day rollover removes TODAY short/topic state while durable rows remain bounded;
- no new ModData root appears;
- source fixture remains immutable;
- no transcript/derived-plan/generated-choice keys appear in persisted owners;
- 200 bounded evidence queries complete well below the 5-second acceptance ceiling while returning at most 16 rows/providers.

## Final verification

Latest acceptance on the staged E7 slice:

- E7 stress suite: **5/5 PASS**;
- combined E0–E7 production-worker suite: **22/22 PASS**;
- full isolated Lua suite: **907/907 PASS**;
- previously known pragmatic P5/R9/R2 regressions: **10/10 PASS**;
- CodeBuilder full Conversation generation: two consecutive passes byte-identical with no generated working-tree delta;
- staged Python modules: `py_compile` PASS;
- installed Project Zomboid Kahlua compiler: **14/14 changed Lua files compile**;
- `git diff --cached --check` and `git diff --check`: PASS.

## Live handoff

Native verification remains user-owned. Validate representative SP/MP conversation flows with emphasis on:

- ungrounded apology asks for context rather than implying forgiveness;
- same-session and same-day grievance → apology remains coherent;
- durable severe grievance remains recallable across day rollover;
- gratitude and pending reply families remain context-grounded;
- generated Response Channel choices match the current pragmatic evidence;
- no abnormal save growth or cross-player evidence leakage.

A native failure should reopen only the owning evidence/provider/relation/presentation layer supported by the captured trace. Do not restart E0–E7 wholesale.

## Safety

No Workshop publication, source-save mutation, new branch, transcript persistence, new semantic ModData root, feature-specific parallel resolver/memory subsystem, or native game launch was used for developer acceptance.
