# Pragmatic Interaction Director & Coherent Conversation

**Status:** IN PROGRESS — L0–L5 live-regression quality recovery; C0–C11 remains accepted foundation.

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

## Active live-regression gap

The semantic foundation is working, but the native user test proved that internal success is not sufficient: direct generated responses can be hidden behind the landing group, bounded relationship-memory retention can still reject an otherwise valid social interaction, and common behavior acts such as WARN still lack compositional realization diversity.

The corrected path remains:

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

For the active L0–L5 recovery, read root `AGENTS.md`, then:

1. `README.md`
2. `ROADMAP.md`
3. `PROGRESS.md` last

Load deeper documents only for the owning phase:

- `ARCHITECTURE.md` / `AGENT_RUNBOOK.md` — architecture or authority regression;
- `ROADMAP.md` — active L0–L5 recovery phases plus compact accepted-foundation context;
- `AUDIT.md` — original failure evidence;
- `STORAGE_TOPOLOGY.md` — compiler/storage regression;
- `DYNAMIC_CONVERSATION.md` — generated-choice or UtterancePlan regression;
- `HARNESS_ACCEPTANCE.md` — acceptance/debugging evidence.

This keeps completed-phase context out of ordinary agent bootstrap.
