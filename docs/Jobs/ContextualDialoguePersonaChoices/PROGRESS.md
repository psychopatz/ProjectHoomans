# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-22  
**Parent status:** IN PROGRESS — P0/P1/P2 accepted; continue P3–P7.
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

## P2 evidence — accepted 2026-10-22

- Added the bounded shared `PNC.Semantics.ActorConversationContext` projection.
  It reads existing identity, registered trait, Social Profile, directed
  relationship, actor-authority/role, and situation fields without calling
  mutating owner APIs or writing ModData.
- Wired the projection into the server authority context, Conversation
  Composer context, client semantic input projection, and the real Lua worker.
  The existing suggestion route exposes only `PublicView`; detailed scores,
  trait IDs, personality dials, provenance, and revisions remain in the
  privileged worker context trace.
- The projection explicitly omits orientation, romance style, jealousy style,
  undiscovered facts, and other private profile values. It carries bounded
  revisions/provenance and a privacy declaration for future safe caching and
  inspection.
- Added `tools/semantic_harness/tests/test_contextual_actor_context_p2.py`:
  production-worker tests passed **3/3**, covering owner-field projection,
  transient context changes with stable semantic candidate IDs, redacted
  player-facing summaries, and absence of persisted persona/choice state.
- P0 + P1 + P2 + S1 + S3 worker suite passed **24/24**; Semantic Lab
  Xvfb/S4 passed **5/5**; embedded worker smoke passed **2/2**. `luac5.3`,
  `pz_verify` Kahlua ERROR checks for every changed Lua file, Python
  compilation, and `git diff --check` passed. Codebase-memory coverage was
  checked for all P2 paths; modified/new paths were read directly because the
  indexed generation predates this slice.

## P3 exact Next Chunk

Derive a transient `SpeechStyleContext` from the canonical actor context using
only the documented bounded dimensions (warmth, formality, directness,
verbosity, hostility, openness, and deference). Add deterministic clamping,
neutral fallback, provenance, and tests showing personality/relationship/
trait/role/situation inputs affect HOW a response is realized while the
semantic response plan, candidate IDs, click frames, and gameplay authority
remain unchanged. Do not add localization variants or persona-aware ranking
until this style contract is frozen.

## Handoff condition

Only after P1–P7 developer gates pass: **READY FOR USER LIVE TEST**.

Native PZ SP/MP remains user-owned and must be reported `UNTESTED` unless the user provides evidence.
### P3 evidence — accepted 2026-10-22

- Added transient `PNC.Semantics.SpeechStyleContext` and bounded whole-phrase `PNC.Semantics.SpeechRealization` families. The resolver uses existing public personality, traits, directed relationship, roles and situation only; gender/private profile fields are explicitly excluded, and the semantic response plan/action frame remains authoritative.
- Realization is applied at the final presentation adapter to a bounded copy. Decision responses, candidate IDs, plan semantics and gameplay authority are not rewritten. UI labels and spoken utterances remain separate translation keys; EN/TL uses the same semantic family and IDs with deterministic neutral fallback diagnostics.
- The real worker now exposes bounded speech-style and realization observations. Added `tools/semantic_harness/tests/test_contextual_speech_style_p3.py` covering neutral/warm/terse/guarded variants, gender invariance, semantic-plan preservation and EN/TL family parity.
- Focused P3 tests passed **3/3**; combined P0–P3 plus S1/S3/S4 and C1/C3/C4A worker contracts passed **40/40**. `luac5.3`, `pz_verify` Kahlua ERROR checks for the new style modules, translation JSON parsing and `git diff --check` passed. Existing S1/C1/C3/C4A behavior regressions introduced by the first integration point were fixed by moving realization to presentation-only rendering and preserving complete response plans.
- Codebase-memory coverage was checked for all P3 paths. The indexed generation predates these edits/new files, reported no recorded coverage gaps, and all flagged sources were read directly; claims are therefore based on current source and worker evidence rather than stale graph freshness.

### P4 exact Next Chunk

Use the existing canonical actor context and registry candidates to add semantic precedence classes and contextual ranking/presentation at the current candidate projection boundary. Preserve provider eligibility, privacy redaction, stable semantic IDs, click-frame stale/replay validation and existing action ownership. Add production-worker tests proving relationship/personality/role/situation can change rank or realization without changing authority, and that private/undiscovered data never changes candidate existence, disabled labels, ranking, or diagnostics. Continue automatically after the bounded P4 slice.

### Current handoff state

Parent goal remains **IN PROGRESS**. P3 passing does not satisfy P4–P7; do not report **READY FOR USER LIVE TEST** until the complete roadmap and developer-side validation are finished. Native Project Zomboid SP/MP acceptance remains **UNTESTED** unless supplied by the user.
### P4 evidence — accepted 2026-10-22

- Added reusable `PNC.Semantics.DialogueChoiceRanking` behind the existing suggestion projection. It applies the documented precedence classes (`BRANCH_CONTINUATION`, `DIRECT_RESPONSE`, `CONTEXTUAL_SOCIAL`, `ACTIVE_TOPIC`, `GAMEPLAY_ACTION`, `GENERAL_TOPIC`, `UTILITY`) with deterministic context fit, authored/provider order and stable-ID tie-breaks.
- Ranking consumes canonical actor context and transient style only after existing eligibility/privacy checks. It emits bounded class/order/privacy diagnostics; it does not inspect private profile fields, alter semantic IDs/frames, authorize effects, or create a second click/action path.
- Added `tools/semantic_harness/tests/test_contextual_ranking_p4.py`: production-worker tests passed **3/3** for precedence, injured-situation reordering with unchanged semantic IDs and accepted click, and private-field projection/ranking invariance. P0–P4 focused worker contracts passed **43/43** when combined with the accepted P0–P3/S1/S3/S4/C1/C3/C4A slice. `luac5.3`, `pz_verify` Kahlua ERROR, and `git diff --check` passed for the P4 slice.
- Codebase-memory coverage was checked for the P4 ranking, suggestion, context, style, architecture and test paths. The current checkout is newer than the indexed generation; no recorded gaps were reported and current source was read directly.

### P5 exact Next Chunk

Audit the actual current Dynamic Trading checkout and its provider/role/capability ownership, then add an optional Dynamic Trading choice provider through the shared registry contract. Keep trader orthogonal to companion/ordinary NPC roles; do not copy trade state, inventory, prices or effects into Project Hoomans/Core. Add dependency-present, dependency-absent and disabled-provider worker tests proving ordinary conversations and existing action authority are unchanged. Continue automatically after the bounded P5 slice.
### P5 evidence — accepted 2026-10-22

- Audited the actual Dynamic Trading checkout at `/home/psychopatz/Zomboid/Workshop/DynamicTrading`: `main` `5b97302e39c482682f4fed0c083ad6764b9eee41`, clean and aligned with its configured upstream before this slice. DTCommon owns trader records, stock, budget, storage, transaction validation/effects, and DTHoomans owns its conversation adapter; Project Hoomans does not copy those fields.
- Added optional `dynamictrading.trader` provider registration through the existing `DialogueChoiceRegistry` and normalized candidate contract. The provider contributes `dynamictrading.trade` only when DTHoomans is activated and the actor is a trader; trader remains an orthogonal role/capability.
- Reused Hoomans’ existing `projecthoomans:trade` category and category-authority route. Dynamic Trading contributes the DTHoomans-owned `dthoomans:trade_basic` block and existing outcome path without adding a parser, UI, click lane, dispatcher, or effect owner.
- Worker dependency loading is opt-in and real-source: it loads DTCommon/DTHoomans from the sibling checkout only for `runtime.availableMods.DTHoomans`, and the worker fixture seeds a trader through DTCommon’s own registry/storage APIs. Disabled/absent scenarios do not load or expose the provider.
- Added `tools/semantic_harness/tests/test_contextual_dynamic_trading_p5.py`: dependency-present provider/source/ownership, existing category-authority click to the DTHoomans block, absent/disabled ordinary-candidate parity, and EN/TL semantic-ID plus separate label/utterance localization passed **4/4**.
- Combined focused production-worker regression (P0–P5, S1/S3/S4, C1/C3/C4A, Semantic Lab profiles) passed **49/49**. Doctor passed required Python, repository/Core, Lua, worker syntax, boot/PING/CAPABILITIES checks. Changed Lua passed `luac5.3 -p`; targeted `pz_verify` Kahlua checks reported 0 errors; translation/conversation JSON parsed; both repositories passed `git diff --check`.
- Codebase-memory coverage was checked for current Hoomans paths and Dynamic Trading. The graph generation predates this slice and marks changed/new Hoomans paths stale or not tracked; current source was read directly. Dynamic Trading’s relevant media directories are excluded from its graph by design, so dependency claims are source-audited rather than graph-complete.

### P6 exact Next Chunk

Extend the existing Semantic Lab only. Trace its current scenario, worker, inspector, and Tk UI paths, then add production-backed persona/choice controls and bounded context-matrix/A-B inspection through the real Lua worker: identity/gender, registered-trait multi-select, personality enum/numeric controls, approval/respect/familiarity, derived relationship state, companion/owned/role/trader adapter state, existing health/activity/world controls, EN/TL, ActorConversationContext, SpeechStyleContext, provider/eligibility/privacy/ranking/realization/localization/frame/stale-replay/dialogue/action traces. Preserve the single worker, existing UI, single choice/action/translation lanes, and privacy redaction. Add focused Lab tests before proceeding to P7 regression/performance/handoff.
P5 revisions: ProjectHoomans `12612a92` (`feat: adopt dynamic trading choice provider`); DynamicTrading `5db64cbc` (`feat: expose trader conversation choice provider`). Existing concurrent ProjectHoomans `a9f43b56` remains preserved on `main`.

### P6 evidence — accepted 2026-10-22

- Added `PERSONA_CATALOG` and bounded `semantic.persona.catalog.v1` through the existing production Lua worker. The catalog is populated from the actual `PNC.NPCTraits` registry and `PNC.SocialProfileConstants` social-style/numeric-dimension definitions; no new persistent persona store was introduced.
- Extended the existing Semantic Lab settings dialog with production-backed identity/gender, registered-trait multi-select, social-style and numeric personality controls, approval/respect/familiarity sliders, derived relationship state, companion/owned/authority/role controls, DTHoomans adapter state, and existing health/activity/world/language controls. Apply sends the resulting scenario through the existing worker `CONFIG` path.
- Added bounded `LuaSemanticWorker.context_matrix()` and the existing Semantic Lab `Persona matrix` action. It runs baseline/warm/guarded contexts through the same real Lua worker, reports actor/speech context and candidate/ranking/display projections, and restores the original scenario after the matrix.
- Extended the existing conversation inspector with bounded `personaChoices` traces for ActorConversationContext, SpeechStyleContext, registry/provider/source, eligibility/privacy, ranking, realization family/variant/fallback, separate label/utterance keys/text, semantic frames, stale/replay receipt, dialogue result, and gameplay action/result. The existing conversation-first renderer now includes a `PERSONA + CHOICES` section.
- Added `tools/semantic_harness/tests/test_contextual_semantic_lab_persona_p6.py`: catalog/registry, production worker matrix/style/privacy/restoration, inspector realization/choice traces, and settings mapping. P6-focused tests passed **4/4**; full contextual regression passed **105/105**; app/inspector/profile contracts passed **16/16**. Python compilation, `luac5.3`, translation JSON parsing, `pz_verify` for changed shipped mod Lua, and `git diff --check` passed. The four `pz_verify` findings in harness-only `ProductionModules.lua` are pre-existing sandbox warnings outside the shipped mod path.
- P6 implementation revision: ProjectHoomans `f37b161a` (`feat: extend semantic lab persona choice controls`). Parent goal remains **IN PROGRESS**; native Project Zomboid SP/MP acceptance remains **UNTESTED**.

### P7 exact Next Chunk

Run the complete developer-side regression, performance, persistence, doctor, and handoff gates: focused/impacted Python and embedded Lua suites; real-worker persona/choice matrices, EN/TL, privacy, stale/duplicate, capability/action authority, and Dynamic Trading adoption; doctor, Kahlua/`luac5.3`, bounded performance, and ModData persistence checks. Fix regressions, update this file with exact evidence, and only then complete the parent goal if every P0–P7 requirement is satisfied.
