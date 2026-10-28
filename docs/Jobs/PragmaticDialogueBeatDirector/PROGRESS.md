# Progress — Coherent Emergent Conversation

**Status:** READY FOR USER LIVE TEST.
**Developer phase:** C0–C11 accepted.
**Branch:** existing `main`.
**Next authority:** user live in-game verification only.

## Current truth

The coherent conversation roadmap is developer-complete. Do not rerun or reimplement C0–C11 unless a live/runtime regression supplies new evidence.

Accepted architecture now includes:

- PsychopatzCore-owned bounded compact/typo/elongation/contraction surface recovery with provenance and conservative mutation safety;
- one ProjectHoomans Contextual Discourse Resolver over the existing bounded DialogueContextState;
- risk-aware conversational vs gameplay-mutation admission;
- compositional social features for directedness, hostility, threat, affiliation, self/world context and negation;
- semantically sharded CodeBuilder output with compiler context-health budgets, lightweight discovery indexes and no numeric/opaque overflow shards;
- generated semantic player affordances through the existing DialogueSuggestions authority;
- typed semantic-click execution with no display-text NLU reparse;
- compiler-owned EN/TL UtterancePlan constructions/lexemes inside the existing SpeechRealization authority with Dialogue Content fallback;
- pending-question, topic, referent, interruption/resumption and hostility→repair continuity through the existing bounded discourse/flow/beat state;
- social reaction/effect decoupled from bounded conduct-evidence retention;
- bounded Conversation Inspector/fuzz observability across recovery → discourse → affordance → interaction → realization → effect/persistence.

No parallel parser, button engine, response engine, transcript store, persistent dynamic-combination catalog or gameplay authority was introduced.

## Phase commits

Key implementation checkpoints:

- PsychopatzCore C1 surface recovery: `3744a7d`;
- ProjectHoomans C1–C4 contextual/risk foundation: `83d5133c`;
- C5 storage/context-health migration: `39768538`;
- C6–C8 dynamic conversation slice: `b2890449`, `6fc49bd1`;
- C9 conduct/social-effect decoupling: `ffc12f2c`;
- C10 bounded diagnostics/fuzzing: `e9721815`;
- C11 acceptance fixes: `6bd01300`.

Git history is the implementation diary. Do not expand this file with completed-phase narratives.

## Latest revalidation

The current paired checkout was revalidated after C11:

- C0–C8 focused/current harness: **46/46 PASS**;
- full ProjectHoomans `pnc_semantic` Lua suite: **99/99 PASS**;
- C5 compiler/context-health: **13/13 PASS**;
- two full Conversation generations are byte-identical;
- compiler context-health: **pass**, 0 errors, 0 numeric shard violations, 0 opaque shard violations;
- C9 social events: **1/1 PASS**;
- C9 conduct: **2/2 PASS**;
- C0A conduct-saturation characterization: **1/1 PASS**;
- C10 Conversation Inspector + pragmatic R6 focused batch: **12/12 PASS**;
- PsychopatzCore semantic dialogue-turn, pattern-matcher and surface-recovery suites: PASS;
- `git diff --check`: PASS before documentation cleanup.

The accepted C11 ledger additionally records broader save-backed/lifecycle/NPC-scene/performance acceptance. Read git history or `HARNESS_ACCEPTANCE.md` only if that evidence becomes relevant to a regression.

## Live-test handoff

User-owned native Project Zomboid testing is the only remaining gate.

For a live failure, capture the smallest reproducible case:

- exact typed input or clicked semantic choice;
- language;
- preceding NPC line/interaction when context-sensitive;
- visible result versus expected result;
- relevant Semantic Lab/Conversation Inspector trace if available.

Then reopen only the owning subsystem and its phase-specific document. Do not reopen the full roadmap by default.

## Safety

- no Workshop publication;
- no native PZ launch for ordinary developer acceptance;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no hand-editing generated Conversation runtime artifacts;
- no full transcript/UtterancePlan/button-combination persistence.
