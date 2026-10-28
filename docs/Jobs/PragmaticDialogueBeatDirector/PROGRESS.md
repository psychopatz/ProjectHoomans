# Progress — Coherent Emergent Conversation

**Status:** IN PROGRESS.
**Current phase:** C5 — storage topology and compiler context-health.
**Branch:** existing `main`.

## Accepted foundation

The prior Pragmatic Interaction Director recovery R0–R9 remains protected.

C0–C4 are now developer-accepted on the paired ProjectHoomans / PsychopatzCore checkout. C0A reports under `tools/semantic_harness/reports/c0a/` are immutable historical pre-C1 evidence; later phases must not rewrite them to match improved runtime behavior.

PsychopatzCore C1 implementation is committed at `3744a7dfab00b2b97e86141f0fd25664523de92b`.

Accepted behavior:

- Core `ParseCandidates()` supports bounded registry-derived compact/no-space recovery, conservative expressive elongation, common contraction recovery, unique vocabulary segmentation, recovery costs and provenance. Exact parsing remains the preferred path and recovered mutating actions are not silently authorized.
- ProjectHoomans composes social features after semantic interpretation: recipient/self/world directedness, hostility, affiliation, threat, contempt, distress and intensity are bounded projections rather than a second sentiment parser.
- Specific grammar now distinguishes malicious wish vs threat, world complaint vs recipient hostility, intensified self-state vs identity claim, and negated-negative assessment vs insult.
- The Contextual Discourse Resolver consumes Core candidates plus existing bounded DialogueContextState. It attaches one explainable DiscourseFrame with pending interaction, topic, subject, reply-to, contextual support and evidence without reparsing raw text.
- Risk-aware admission separates conversation/read-only interpretation from gameplay mutation. Context may reinforce safe conversation; exact high-confidence mutations stay strict; safe fuzzy movement preserves the existing FOLLOW/STOP/STAY contract; recovered mutation is blocked; exact open-text item/world binding may defer only to existing authoritative selectors; typo-like fuzzy inventory/task interpretations clarify.
- C0A characterization tests now read the historical snapshots instead of comparing them to the continuously improving live worker.

Current validation:

- Core surface-recovery smoke: PASS.
- Core semantic pattern-matcher smoke: PASS.
- C0 historical + C1–C4 live Python harness: 24/24 PASS.
- C4 direct risk-policy smoke: PASS.
- full ProjectHoomans `pnc_semantic` Lua suite: 99/99 PASS.
- `git diff --check`: clean before phase transition.

## C5 current truth

The existing Conversation compiler already has deterministic recursive source-root discovery and 54 canonical source files, but runtime sharding still groups by broad domains. That creates numeric overflow modules such as `SocialPart02.lua`, `CommandPart02.lua`, `QuestionPart02.lua`, plus opaque pattern names such as `Massive.lua` and `Sgd.lua`.

Measured canonical hard-budget issues before migration:

- `content/social/emotes.json` is ~20.9 KB, above the planned ~16 KB hard canonical ceiling.
- `content/command/lifecycle.json`, `content/social/tool_replies.json`, `content/task/lifecycle.json`, and `content/task/tool_replies.json` exceed the planned 32-definition hard shard budget if generated one source→one shard.
- Generated broad-domain output currently contains 53 data shards and several ~32 KB overflow parts.

## Immediate Next Chunk

Use canonical source ownership as the generated-shard key instead of broad domain. Split only the canonical sources that violate hard context budgets into semantically named source directories, then add compiler-owned context-health and lightweight discovery/affected-closure indexes.

C5 acceptance still requires:

- zero numeric/opaque generated Conversation shard names;
- no hard source/generated/index budget violations;
- deterministic recursive discovery and lightweight ID→source→generated routing;
- bounded affected-closure metadata;
- two byte-identical full generations;
- existing semantic/runtime behavior unchanged.

## Remaining mandatory work

C5 storage/context-health → C6 dynamic semantic affordances → C7 compositional utterance realization → C8 discourse continuity → C9 conduct-memory decoupling → C10 observability/fuzzing → C11 integrated acceptance.

## Safety

- no new branch;
- preserve unrelated user work;
- no Workshop publication;
- no native PZ launch for ordinary developer acceptance;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no hand-editing generated runtime artifacts; generated Conversation output changes only through CodeBuilder.
