# Progress — Coherent Emergent Conversation

**Status:** IN PROGRESS.
**Current phase:** C0 — failure corpus, ownership audit and baselines.
**Branch:** existing `main`.

## Accepted foundation

The prior Pragmatic Interaction Director recovery R0–R9 is developer-accepted at ProjectHoomans commit `ee825b71`.

Protected foundation:

- single ResponsePlan / Dialogue Content speech authority;
- modular generated interaction registry;
- shared predicates;
- typed stimuli/providers;
- pragmatic resolver + Interaction Director;
- bounded event-driven beats/scenes/LOD;
- NPC-to-NPC and multi-NPC semantic interaction;
- shared speech/emote/flavor outputs;
- integrated Semantic Lab interaction authoring/trace;
- deterministic generation and bounded semantic memory.

Do not reread or restore the old recovery diary unless current evidence shows a regression.

## Current audit findings

Fresh production-worker checks show distinct remaining problems:

- `fuckyou` currently recovers as `INSULT` at about 0.91, but this is not general no-space support;
- `fuck u` and `fuck youuuu` are recognized;
- `shutthefuckup`, `youidiot`, `illkillyou`, and `youreuseless` still fail as single unknown tokens;
- `i hope you die` can be classified as `HOSTILE_REMARK` around 0.83 yet still becomes `ASK_CLARIFICATION` because policy applies a global high-confidence gate;
- social events can be understood but later reported rejected when new conduct evidence is removed by the 64-entry evidence cap (`evidence_pruned_by_limit`);
- canonical beat/behavior source is already reasonably atomic, but generated Conversation output still contains numeric/opaque shards including `SocialPart02.lua`, `CommandPart02.lua`, `QuestionPart02.lua`, `Massive.lua` and `Sgd.lua`, which must be migrated before dynamic affordance/realization growth.

Relevant ownership verified in code:

- PsychopatzCore `PsychopatzSemanticNormalizer.lua`, parser/candidate matcher and registry own generic surface parsing;
- ProjectHoomans `PNC_SemanticDialogueCandidateEligibility.lua` and `PNC_SemanticDialoguePolicy_Flow.lua` own contextual admission/policy;
- existing pragmatic/interaction layers are downstream and should not become parsers;
- conduct persistence is separate server-side social state and must not define whether language was understood.

## Immediate Next Chunk — C0A

Create a compact real-worker regression corpus and diagnostics baseline before changing parsing behavior.

Required initial groups:

1. compact/no-space;
2. elongation/typo;
3. directed hostility vs self/world profanity;
4. threat vs hostile wish;
5. negation;
6. context-dependent short replies;
7. benign false positives;
8. mutating-action safety;
9. conduct-saturation reaction vs persistence;
10. current post-NPC-reply button sources, stance diversity and authored/static dependence;
11. current NPC response realization for mirror/counter/agreement/disagreement cases, including whether a full authored phrase is required;
12. current canonical/generated storage metrics: largest records/shards, definitions per shard, manifest/index size, numeric overflow shards, opaque generated names and current ID→source→generated discoverability.

Record expected semantic class, contextual outcome, allowed recovery type, semantic button continuations, realization strategy, storage ownership and whether authoritative mutation is permitted.

Then use that corpus to drive C1 rather than adding one-off phrase aliases.

## Remaining mandatory work

C1 surface recovery → C2 compositional social features → C3 Contextual Discourse Resolver → C4 risk-aware acceptance → C5 storage topology/context-health → C6 dynamic semantic affordances → C7 compositional utterance realization → C8 discourse continuity → C9 conduct-memory decoupling → C10 observability/fuzzing → C11 integrated acceptance.

## Safety

- no new branch;
- verify both repositories before cross-repo edits;
- preserve unrelated user work;
- no Workshop publication;
- no native PZ launch for ordinary developer acceptance;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no hand-editing generated artifacts.
