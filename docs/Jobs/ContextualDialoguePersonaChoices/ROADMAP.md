# Roadmap — Contextual Dialogue Persona & Choices

**Parent status:** REOPENED — P0-P7 foundation retained; P8 behavioral completion is mandatory.  
Phases are organization and acceptance checkpoints; completing one phase never completes the parent objective.

## P0 — Current-path contract baseline

Verify actual local ProjectHoomans/Core revisions and concurrency, then lock behavior around the existing suggestion path before structural changes.

Required work:

- source-level inventory of current `PNC_SemanticDialogueSuggestions`, branch offers, Conversation root/choice adapters, click path, translations, predicate traces, worker/UI projection;
- contract tests for stable current candidate IDs/frames, EN/TL label-vs-utterance behavior, stale/duplicate click handling, capability authority, branch offers and root choices;
- record exact local baseline and affected tests.

**Gate:** existing behavior is reproducible through real production Lua worker and focused tests; no feature redesign hidden in the baseline slice.

## P1 — Modular Choice Registry & providers

Refactor the centralized static/capability catalog behind a versioned registry/provider contract while preserving externally observed behavior.

Required:

- no second choice execution path;
- normalize static definitions, capability definitions, active-flow offers, response-plan offers and Conversation choices/root into one candidate contract;
- deterministic provider ordering/dedupe/bounds;
- preserve existing `semantic_click_frame` compatibility or provide a tested versioned migration;
- split responsibilities without creating tiny-file churn or a new god registry.

**Gate:** current suggestion scenarios are behaviorally identical where semantics are unchanged; providers can be added without editing a central switch/table; worker and Core choice UI remain green.

## P2 — Canonical Actor Conversation Context

Add the bounded read-only actor projection using existing public owners.

Required inputs where available:

- identity/gender for identity/grammar/compatibility only;
- registered NPC traits;
- Social Profile personality fields;
- directed relationship approval/respect/familiarity/state;
- companion/owned/hostile and other established roles/capabilities;
- relevant health/activity/situation/current topic;
- revisions/provenance for cache invalidation.

No duplicate persistent state.

**Gate:** production game path and worker produce equivalent context for equivalent scenario state; unknown/private fields fail closed; context is bounded and does not poll every NPC per tick.

## P3 — Speech Style Resolver & localized realization families

Implement deterministic derived speech dials and plug them into response realization without changing semantic decisions.

Required:

- documented bounded dials and precedence;
- personality + relationship + trait + role + situation inputs;
- no gender stereotyping;
- base/neutral fallback;
- whole-phrase EN/TL variants using existing translation manager;
- semantic response plan remains authoritative;
- same semantic frame can realize differently under materially different contexts.

**Gate:** real worker demonstrates at least friend/neutral/enemy and friendly/withdrawn or equivalent persona contrasts with unchanged semantic facts; EN/TL both resolve with no unintended fallback.

## P4 — Persona-aware choice policy, ranking & realization

Let candidate eligibility/ranking/presentation consume ActorConversationContext and SpeechStyleContext where justified.

Required:

- semantic ranking classes rather than one global number race;
- context-relevant social choices may appear/disappear/reorder;
- relationship/personality can change presentation variant but not action authority;
- private orientation/backstory/secret facts never leak via candidate existence, label, tooltip, ordering or trace;
- maintain typed/button semantic parity.

**Gate:** production worker matrices prove deterministic candidate sets/ranks across relationship/persona/role boundaries and click-time revalidation remains exact.

## P5 — Dynamic Trading provider adoption

Audit current Dynamic Trading portable-conversation/NPC-foundation implementation at execution time, then integrate trader choices through the common provider contract.

Required:

- no Hoomans copy of trade state;
- trader is orthogonal to companion/relationship/faction role;
- Dynamic Trading owns trade content and effects;
- provider outputs canonical choices and localization;
- provider unavailable => graceful absence, not broken Hoomans conversation.

**Gate:** with DT provider enabled, trader choices appear and route correctly; with DT absent/disabled, Hoomans behavior remains unchanged. Existing DT smoke/adoption tests pass.

## P6 — Semantic Lab Persona & Choice Simulator

Extend the existing Tk Semantic Lab and its existing scenario/worker path.

Mandatory controls:

- gender/identity field where supported;
- trait multi-select populated from actual registry;
- personality enums and numeric sliders;
- approval/respect/familiarity sliders;
- derived relationship state display using production logic;
- role/capability controls including trader adapter;
- health/activity/context controls already supported;
- language EN/TL.

Mandatory inspection:

- actor context;
- speech dials/trace;
- candidate providers;
- predicate/privacy results;
- rank;
- realization variant;
- keys/resolved text;
- frame/click/action result.

Add bounded A/B comparison or a context-matrix runner that exercises the real worker. No Python-only semantic/style simulator.

**Gate:** Xvfb/GUI proof shows controls alter the actual production worker result and scenario save/load round-trips. A relationship slider change must derive production relationship state rather than allow impossible ordinary combinations.

## P7 — Regression, performance & handoff

Run focused + impacted full suites and resolve regressions.

Required final evidence:

- relevant Python Semantic Lab suite;
- embedded Lua tests;
- real worker EN/TL persona + choices matrix;
- privacy/stale/duplicate/action-authority cases;
- Dynamic Trading adoption cases when dependency is available;
- doctor;
- Kahlua/`luac5.3`;
- bounded performance/no per-frame or all-NPC polling;
- persistence check proving derived speech/candidate state is not saved redundantly;
- native SP/MP review documented as user-owned/unrun if unavailable.

**Gate:** all developer-verifiable requirements green. Status becomes **READY FOR USER LIVE TEST**, never "native verified" unless the user actually supplies that evidence.


## P8 — Behavioral Completion

The P0-P7 implementation is accepted as infrastructure/regression foundation, but the user-visible persona/choice goal is not complete. P8 supersedes the previous READY FOR USER LIVE TEST handoff.

Read BEHAVIORAL_COMPLETION.md before P8 implementation.

### P8A — Bond vocabulary + production-faithful Lab baseline

Implement the smallest corrective foundation first.

Required:

- inventory the actual current detailed starting-companion relationship kinds and their persistence/projection path;
- add a bounded relationship-kind metadata registry or equivalent declarative contract;
- derive bond.class as friend/family/lover while preserving detailed bond.kind;
- project bond into ActorConversationContext without new persistence;
- add EN/TL relationship-term registrations for current kinds;
- fix Semantic Lab normal relationship state to use production PNC.RelationshipStates.ResolveState;
- add production-backed bond-kind catalog/selector and read-only derived bond class;
- add slider value labels;
- add tests proving family kind survives while relationship state changes independently.

**Gate:** mother/father/sister/brother map to family; friend maps to friend; lover maps to lover; no duplicate persistent bond class; the Lab cannot produce an ordinary impossible relationship-state combination.

### P8B — Speech-dial and realization coverage completion

Required:

- create a machine-readable audit/coverage table of production semantic response families;
- identify which Persona Lab controls actually influence speech;
- wire or clearly classify currently inert controls such as socialStyle, forgiveness and bravery;
- replace ad-hoc trait-name handling with declarative speech metadata where practical;
- expand realization beyond greetings across the mandatory families in BEHAVIORAL_COMPLETION.md;
- add bond-aware friend/family/lover realization where it changes wording;
- family variants use localized term substitution rather than mother/father/cousin-specific semantic IDs;
- preserve semantic response plan/action identity.

**Gate:** real worker matrices cover multiple non-greeting intents and demonstrate same semantic facts with different friend/family/lover + standing/personality realizations in EN/TL.

### P8C — Generic provider discovery + contextual replies

Required:

- make registry collection the normal optional/domain provider discovery path;
- remove provider-specific Dynamic Trading collection from the central builder;
- preserve root/flow/response-plan authored offers;
- add at least one real contextual social/relationship provider through the generic contract;
- add gossip/knowledge/quest providers only where production semantic facts already support them;
- keep visibility/authority/privacy separation exact.

**Gate:** a test provider can register and participate without a central suggestions edit; Dynamic Trading still works through the same generic seam; social/contextual replies are ranked and clickable through the existing typed path.

### P8D — Semantic Lab tuning workflow

Required:

- arbitrary current utterance for A/B/matrix runs;
- clone current scenario into comparison rows;
- selectable sweep dimensions including approval/respect/familiarity, bond kind, personality, traits and role;
- apply-and-replay without reopening a hidden settings workflow for every change;
- inspect localized bond term, semantic family, style variant, ranking and final response;
- keep all policy decisions in the real Lua worker.

**Gate:** GUI proof under Xvfb shows the same utterance compared across friend/family/lover and friend/enemy standing, including at least two family subtypes that reuse the same family realization with different localized terms.

### P8E — Corrective regression and handoff

Run focused and impacted full regressions after P8A-D.

Required evidence:

- relationship/bond mapping and no-new-persistence tests;
- non-greeting realization coverage tests;
- EN/TL family-term substitution tests;
- provider generic-discovery tests;
- Dynamic Trading adoption regression;
- stale/replay/privacy/action-authority regression;
- Semantic Lab Tk/Xvfb workflow;
- Kahlua/luac, doctor, JSON validation, diff checks;
- bounded performance and ModData checks.

**Gate:** only after P8A-P8E pass may the parent goal return to READY FOR USER LIVE TEST. Native Project Zomboid SP/MP remains user-owned.
