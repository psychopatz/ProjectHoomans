# Pragmatic Interaction Director & Coherent Conversation

**Status:** IN PROGRESS — accepted interaction infrastructure is retained; the active gap is contextual language/discourse understanding and coherent conversation behavior.

The directory name is retained for continuity. Git history is the archive for the completed R0–R9 recovery work; agents should not reread that implementation diary.

## Parent objective

Make Project Hoomans conversations feel like one coherent, naturally emergent interaction rather than several independent systems firing beside each other.

The system must connect:

- imperfect human text;
- semantic candidates;
- discourse/context interpretation;
- pending questions, replies, topics and references;
- actor personality/condition/relationship;
- grounded world/social knowledge;
- flows and bounded interaction beats;
- behavior arbitration;
- dynamic semantic player affordances/buttons;
- compositional runtime player/NPC utterance realization;
- context-efficient modular compiler/storage topology for all new semantic building blocks;
- Dialogue Content realization and authored fallbacks;
- authoritative social/gameplay effects.

The result should remain deterministic and explainable offline, with optional PBrainZ realization but no required runtime LLM.

## Accepted foundation — do not rebuild

The following are already developer-accepted and are treated as foundation:

- one ordinary ResponsePlan / Dialogue Content speech path;
- compiler-owned interaction behaviors/beats/content with atomic canonical records;
- one generated Conversation registry plus worker-local draft overlay;
- shared typed predicate semantics;
- typed stimuli and bounded actor/relationship/world/knowledge projections;
- pragmatic resolver, InteractionPlan and Interaction Director;
- event-driven stimulus indexes, scene limits and LOD;
- NPC-to-NPC / multi-NPC semantic scenes without reparsing generated English;
- shared speech/emote/flavor outputs;
- integrated Semantic Lab Interaction Modules and Interactions trace;
- deterministic generation and no transcript persistence.

Do not reopen these unless current code evidence proves a regression.

## Active architecture gap

Human input is still too dependent on whitespace/exact phrase shape, candidate confidence is gated too globally, and discourse context does not yet participate strongly enough in choosing between plausible conversational meanings. The existing semantic suggestion surface and SpeechRealization path are authoritative but still rely too heavily on pre-authored button/reply wording instead of deriving reusable semantic continuations and bounded runtime utterances from the same discourse state.

Before those dynamic systems expand the catalog, CodeBuilder storage must also be hardened against context bloat: canonical sources stay atomic, generated outputs are semantically sharded, indexes point instead of aggregate, paths/IDs explain ownership, and numeric/opaque overflow shards are forbidden.

The active path is:

```text
human text
  ↓
PsychopatzCore surface normalization / bounded recovery
  ↓
PsychopatzCore ParseCandidates
  ↓
Project Hoomans Contextual Discourse Resolver
  ↓
Pragmatic Resolver
  ├─→ dynamic semantic player affordances
  │      ↓
  │   player UtterancePlan
  ↓
Interaction Director
  ↓
InteractionPlan
  ↓
NPC/player UtterancePlan
  ↓
SpeechRealization / Dialogue Content fallback / emote / existing gameplay authority
```

No parallel parser, sentiment engine, response engine, or gameplay authority may be introduced.

## Repository ownership

- **PsychopatzCore:** generic human-text normalization, tokenization, bounded typo/compact recovery, semantic concepts/patterns, candidate IR and parser diagnostics.
- **ProjectHoomans:** conversation/discourse context, target/reference interpretation, social meaning, candidate contextualization, pragmatic interaction, behavior selection, social memory policy and presentation.
- **Semantic Lab:** observe and test the production Lua path; Python never becomes semantic authority.

Cross-repository changes are allowed only when the owning layer genuinely requires them and both worktrees are verified safe first.

## Read order

Read root `AGENTS.md`, then:

1. `README.md`
2. `ARCHITECTURE.md`
3. `AGENT_RUNBOOK.md`
4. `ROADMAP.md`
5. `PROGRESS.md` last

Supporting docs are phase-specific to protect agent context:

- `AUDIT.md` — read only when implementing/disputing audited failure paths;
- `STORAGE_TOPOLOGY.md` — C5 or compiler-storage work;
- `DYNAMIC_CONVERSATION.md` — C6/C7 choices/realization;
- `HARNESS_ACCEPTANCE.md` — acceptance implementation or C10/C11 validation.
