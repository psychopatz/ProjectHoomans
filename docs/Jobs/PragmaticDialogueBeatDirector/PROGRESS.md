# Progress — Coherent Emergent Conversation

**Status:** IN PROGRESS.
**Current phase:** C0 — failure corpus, ownership audit and baselines.
**Branch:** existing `main`.

## Accepted foundation

The prior Pragmatic Interaction Director recovery R0–R9 is developer-accepted at ProjectHoomans commit `ee825b71`.

Protected foundation:

- single ResponsePlan / Dialogue Content speech authority;
- modular generated interaction registry;
- shared predicates and typed stimuli/providers;
- pragmatic resolver + Interaction Director;
- bounded event-driven beats/scenes/LOD;
- NPC-to-NPC and multi-NPC semantic interaction;
- shared speech/emote/flavor outputs;
- integrated Semantic Lab interaction authoring/trace;
- deterministic generation and bounded semantic memory.

## Verified C0A baseline

Checked-in fixtures and bounded reports live under `tools/semantic_harness/fixtures/c0a/` and `tools/semantic_harness/reports/c0a/`. They use fresh sessions of the real Lua `LuaSemanticWorker`; Python only transports scenarios and projects returned fields.

- Corpus: 23 cases cover compact/no-space, elongation/typo, hostility/threat/wish, self/world profanity, negation, short context replies, benign controls, and mutating-action safety. Current failures include all five compact hostility controls except `fuckyou`, `i hope you die` understood fuzzily at `0.83` but clarified, `i'm fucking starving` routed as an identity claim with an attempted mutation, and `give me waterr` reaching `SemanticTaskRequest`.
- Multi-turn: the NPC greeting follow-up stores a pending question, but player `not really` selects generic `DISAGREE` and cancels the flow. Apology selects `behavior.reconcile`; `yeah right` remains clarification. Time/date continuation retains the time topic; changing to wellbeing starts a new flow.
- Suggestions: current candidates mix authored/static `conversation_root`/`typed_input` rows with derived `active_flow`, `npc_response_plan`, and `social_context` rows. Frames carry intent/speech act/subject/topic, ranks are unique in the captured surfaces, no stance/polarity fields are present, and `question.time` clicks re-enter the typed semantic-click route.
- Reply realization: retaliation, agreement, thanks, and apology use production phrase families; disagreement currently falls back without a phrase family; greeting follow-up is a two-turn plan using the same family. No composition behavior was added.
- Storage: 54 canonical source files / 486 locations; source manifest 5,098 bytes; 53 planned generated shards. Largest current shards include `Event.lua` (32,486 bytes), `SocialPart03.lua` (32,168), `Command.lua` (32,129), and `Question.lua` (31,766). Numeric overflow includes every current `CommandPart02`, `EventPart02`, `SocialPart02`–`04`, `TaskPart02`, and `QuestionPart02`; opaque names remain `Massive.lua` and `Sgd.lua`. Exact flow IDs use the current `.flow` runtime alias; no unresolved alias, generated-definition collision, registry reference, or unplanned-runtime-module was detected.
- Conduct: disposable production-service state reproduces `evidence_pruned_by_limit` for a weak 65th temporary record and `permanent_evidence_limit` for a 65th permanent record. Understanding, reaction selection, relationship effects, and durable evidence are reported separately.

Current relevant-suite baseline: C0A Python regression 9/9; required Semantic Harness Lua filters 12/12; full `pnc_semantic` Lua suite 98/98. Two pre-existing Python assertions remain: the speech registry family expectation for `semantic.flow.greeting.opening.default`, and the GUI lineage expectation for the stale `common_responses.json` source name. No C1+ behavior, generated shard, source save, Core semantic implementation, or persistence policy was changed.

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
