# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-22  
**Parent status:** IN PROGRESS — P0 current-path contract baseline accepted; continue P1–P7.
**Remote source audit baseline:** ProjectHoomans `main` at `765bc4076ab82ec2c1eca6ca52cef1c6bf177597`.  
**Dynamic Trading source inspected:** `5b97302e39c482682f4fed0c083ad6764b9eee41`.  
**Local implementation baseline:** ProjectHoomans `main` at `eaaed7767c2d41b2cc4db5df346ebc2c34b6b5be`; PsychopatzCore `main` at `443b3a86d097b8fd17fa10caafa545f959dc913f`; DynamicTrading `main` at `5b97302e39c482682f4fed0c083ad6764b9eee41`. All three local branches matched their configured `origin/main` at audit time.

## Verified foundation

Source audit confirms:

- existing typed semantic suggestions already use stable candidates/frames, localized label + utterance keys, privacy predicates, stale/duplicate protection, and the existing DialogueInput/action authority path;
- active-flow offers, response-plan offers, authored Conversation choices/root already supply dynamic candidates;
- the current static semantic/capability catalogs remain centralized in `PNC_SemanticDialogueSuggestions.lua`;
- `PNC_SemanticDialogueInput_ContextProjection.lua` already projects relationship, knowledge, gossip, flow/topic, world/situation and entity context but does not yet expose one canonical complete actor/persona/speech context;
- persistent Social Profile, NPC Traits and directed Relationships already own the needed personality/social data;
- Semantic Lab scenario state already supports traits, relationship, actor authority, health/activity and language/runtime fields;
- Dynamic Trading already has portable conversation/NPC-foundation adoption material suitable for a later trader provider.

These are source-level findings. This documentation task did not rerun Lua/Python suites or native Project Zomboid.

## Known product gap

The existing systems need to be connected, not duplicated:

1. modularize choice definitions/providers;
2. project canonical actor conversation context;
3. derive transient speech style;
4. realize semantic responses/choices through localization-safe variants;
5. apply contextual ranking/privacy without changing authority;
6. integrate Dynamic Trading through the provider seam;
7. expose/tune/test all of it in the real Semantic Lab.

## Current mandatory phase

**P0 — Current-path contract baseline**

### Exact Next Chunk

On the user's actual local checkout:

1. read root `AGENTS.md` and this job;
2. verify ProjectHoomans/Core/DynamicTrading local branches, HEADs, upstream/divergence and concurrent/user changes; do not create a branch;
3. inspect the exact current local `PNC_SemanticDialogueSuggestions.lua`, predicate module, DialogueInput click route, response/branch offers, Conversation root/choice projection, translation catalogs and Semantic Lab worker/UI;
4. add/strengthen focused behavior-contract tests that freeze the current candidate/frame/localization/click behavior before refactoring;
5. run the real worker for representative initial-root, response-plan/branch, companion-capability and EN/TL cases;
6. update this ledger with exact revisions/tests and proceed directly into P1 if P0 passes.

### P0 acceptance

- no behavior-changing refactor bundled into the baseline test slice;
- real worker reproduces the current path;
- label and utterance translation keys remain separate and stable;
- stale/duplicate/capability authority cases are covered;
- current dynamic branch/root choices are covered;
- source ownership and safe local Git state are recorded.

## P0 evidence — accepted 2026-10-22

- Added `tools/semantic_harness/tests/test_contextual_dialogue_persona_choices_p0.py`, a production-worker contract fence covering initial root → authored block projection, active-flow and response-plan offers, companion capability frames, separate label/utterance keys, EN/TL resolution, stale/duplicate rejection, and companion authority absence.
- Real Lua worker: the new P0 contract suite passed **4/4**; existing contextual suggestion suites passed **14/14**; existing Semantic Lab Tk/Xvfb interaction suite passed **5/5**.
- Focused embedded Lua worker smoke tests passed **2/2** (`pnc_semantic_harness_worker_modules_smoke`, `psychopatz_conversation_choices_hover_smoke`).
- Direct worker evidence confirmed root candidates at revision `0`, flow/response-plan candidates at revision `1`, `FOLLOW` action admission through `pnc:companion.follow`, duplicate receipt rejection, and EN/TL `question.wellbeing` label/utterance resolution with the same semantic ID/frame candidate ID.
- No behavior-changing production refactor was bundled into P0.

## After P0

Continue autonomously P1 -> P7 according to `ROADMAP.md`. Do not wait for another user prompt merely because a phase passed.

### P1 exact Next Chunk

On the same existing `main` checkout, introduce the smallest reusable,
versioned choice-provider contract behind the current suggestion builder. Keep
the current static/capability definitions and all existing dynamic projections
behaviorally identical while routing them through one bounded normalization,
dedupe, and provider-order seam. Add provider-contract tests through the real
Lua worker before moving persona or realization policy into the path.

## P1 evidence — accepted 2026-10-22

- Added the bounded `DialogueChoiceRegistry` mechanism plus dedicated static-question and capability providers under `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/SemanticDialogueSuggestions/`.
- The existing `PNC_SemanticDialogueSuggestions.lua` remains the compatibility entry path, but no longer owns duplicate static/capability definition tables. Root/block, active-flow, response-plan, static, and capability rows now carry `candidateSchema = "semantic.choice.v1"`, stable provider IDs, and normalized source provenance.
- Provider registration is deterministic and bounded; the existing candidate order, dedupe, translation fields, semantic frames, and click/action route remain unchanged. The registry only contributes declarative normalization and diagnostics; it does not dispatch effects.
- Real Lua worker P1 tests passed **3/3**; the combined P0 + P1 + S1 + S3 worker suite passed **21/21**; affected Tk/Xvfb/provider-parity tests passed **9/9**; focused embedded Lua smoke tests passed **2/2**.
- `luac5.3`, Kahlua ERROR checks, Python compilation, and `git diff --check` passed for the changed slice.

## P2 exact Next Chunk

Build the bounded read-only `ActorConversationContext` projection from existing
identity, traits, Social Profile, directed relationship, role/capability, and
situation owners. Keep it optional and revision-aware, expose safe provenance
for the Semantic Lab, and add worker contract tests proving no duplicate
persistent personality/relationship state is created before deriving any
speech-style or persona-aware ranking behavior.

## Handoff condition

Only after P1–P7 developer gates pass: **READY FOR USER LIVE TEST**.

Native PZ SP/MP remains user-owned and must be reported `UNTESTED` unless the user provides evidence.
