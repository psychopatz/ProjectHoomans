# P12 — Pragmatic Conversational Intelligence & Dialogue Director

**Status:** MANDATORY AFTER P11 / NOT YET ACCEPTED.

P0–P10 remain accepted semantic-runtime foundation. P11 is the active modular
Conversation authoring/tooling phase. P12 begins only after P11 developer-side
acceptance, and extends the same semantic authority rather than creating a
second chatbot, parser, dialogue database, or gameplay dispatcher.

## Product outcome

Project Hoomans should feel substantially more conversationally intelligent and
less phrase-bound while remaining deterministic/offline by default.

The finished system must distinguish:

- **what the player may have meant**;
- **what that meaning refers to in the current conversation**;
- **what conversational behavior the NPC should choose**;
- **what authoritative gameplay effect, if any, is actually permitted**;
- **how the chosen conversational intention is worded**.

Target architecture:

```text
PLAYER UTTERANCE
      ↓
existing Core NLU / semantic candidates
      ↓
Pragmatic Resolver
  target / reply-to / conversational function / confidence
      ↓
bounded DialogueContextState
  topic / referents / obligations / recent acts / suspended topics
      ↓
Dialogue Director
  eligible reactions / personality / relationship / situation / cooldown
      ↓
ResponsePlan
  dialogue acts / grounded fact refs / uncertainty / optional action request
      ↓
Dialogue Content realization
      ↓
SemanticSpeech presentation

optional PBrainZ
  consumes the SAME grounded plan downstream of semantic truth
```

## Immediate motivating defect

The user-observed Semantic Lab turn on 2026-10-27 showed:

```text
PLAYER: "fuck ypuuuu"

Understanding:
  classification = recognized_social_interaction
  intent = HOSTILE_REMARK
  pattern = pnc.social.profanity
  confidence = 0.87

NPC:
  "I'm not sure what you mean."
```

This screenshot is user evidence, not yet a reproduced worker trace.

Current production source already routes `HOSTILE_REMARK` / `INSULT` to
`HOSTILE_REMARK_RECEIVED`, and existing regression tests explicitly require
recognized hostile language not to use the generic clarification response.

Therefore P12 must start by proving and repairing the **recognized meaning →
policy branch → response plan → rendered text** path before expanding language
coverage. Do not paper over this defect by adding another profanity literal.

## Central invariant

> **Core NLU proposes meaning. Conversation context resolves reference and
> conversational function. The Dialogue Director chooses an NPC conversational
> behavior. Gameplay/domain authorities alone permit effects. ResponsePlan and
> Dialogue Content express the selected behavior.**

The semantic layer may become smarter about context and pragmatic meaning, but
it must not absorb inventory, relationship, health, faction, quest, task or
world truth.

## No-second-system rules

P12 must reuse and extend:

- PsychopatzCore parser/NLU candidate structures and registered semantic
  patterns;
- `PNC.Semantics.DialogueContextState`;
- `PNC.Semantics.SemanticInteractionLifecycle`;
- `PNC.Semantics.DialogueFlowKernel`;
- existing reference/context resolver;
- `PNC.Semantics.ResponseCatalog`;
- `PNC.Semantics.ResponsePlan`;
- Suggestions and response-window/beat infrastructure;
- ActorConversationContext / SpeechStyleContext;
- authoritative Relationship/Knowledge/Health/Inventory/Faction/Task/Quest
  owners;
- P11 Dialogue Content, Conversation UI Registry, and shared authoring service;
- existing production Lua worker and Semantic Lab.

Do not add:

- another parser;
- a second response catalog;
- a transcript database;
- a second event/follow-up engine;
- a second Conversation state store;
- an LLM-only semantic path;
- a per-NPC tick dialogue planner;
- hard-coded one-off branches for every paraphrase;
- direct gameplay mutation from fuzzy pragmatic inference.

## Interpretation model

The current selected IR remains important, but conversation needs bounded
candidate information when ambiguity matters.

Conceptual contract:

```text
InterpretationCandidate {
  semanticIntent,
  speechAct?,
  action?,
  subject?,
  target?,
  slots,
  confidence,
  provenance,
  negated?,
  quoted?,
  sourcePattern?
}

PragmaticFrame {
  selectedCandidate,
  alternatives[],
  dialogueAct,
  conversationalFunction,
  replyTo?,
  targetRef?,
  topic?,
  confidenceBand,
  ambiguityReason?,
  contextEvidence[]
}
```

These are design contracts, not an instruction to create duplicate parallel
IR types if current Core/Hoomans structures can be extended safely.

The pragmatic layer must be able to represent distinctions such as:

- ANSWER vs unrelated INFORM;
- CHALLENGE_QUESTION vs ordinary QUESTION;
- ACCEPT/REFUSE of a pending proposal;
- DISMISS / TOPIC_EXIT;
- hostility/provocation without assuming a gameplay command;
- interruption and later resumption;
- elliptical follow-up such as "How?", "Why?", "How many?", "And him?";
- explicit or implied target/reference resolution.

## Dialogue obligations and topic state

Extend the existing bounded `DialogueContextState` rather than creating a new
conversation store.

Required conversational state, where not already represented:

```text
currentTopic
topicSalience[]
recentDialogueActs[]
pendingQuestions[]
pendingOffers[]
pendingRequests[]
commitments[]
focusRefs[]
suspendedTopics[]
recentEmotionalEvents[]
activeBeat?
```

Rules:

- all state is scoped to the correct conversation / player / NPC pair;
- arrays remain bounded with explicit expiry/compaction;
- no full transcript persistence;
- pending questions are obligations, not coercive locks;
- unrelated questions may interrupt without being misclassified as evasion;
- ambiguous/expired referents clarify rather than invent;
- volatile facts revalidate through their authoritative owner.

## Topic salience

Use bounded salience over existing topics/referents, not a global knowledge
scan.

Salience may rise because:

- the player or NPC just mentioned the topic;
- a pending question/proposal references it;
- a grounded world event opened a response window;
- a strongly relevant memory/fact is currently projected.

Salience decays with turns/time and is capped.

Example:

```text
NPC: "We lost two people yesterday."
PLAYER: "How?"

recent event/topic = leader_loss / raid
requested attribute = cause
```

The player should not need to restate the full subject when the current context
makes the reference unambiguous.

## Dialogue Director

Add a pure, bounded reaction-arbitration layer inside the semantic authority.

The Director chooses among **conversational behaviors**, not raw lines and not
gameplay mutations.

Example candidates:

```text
ACKNOWLEDGE
ANSWER
CLARIFY
CHALLENGE
WARN
RETALIATE_VERBALLY
DEFUSE
REFUSE
ACCEPT
ASK_FOLLOWUP
RETURN_TO_TOPIC
CHANGE_TOPIC
END_TOPIC
END_CONVERSATION
IGNORE
PROPOSE
REMIND
```

Each candidate may declare:

- eligibility/preconditions;
- semantic/pragmatic trigger;
- relationship/personality/context factors;
- urgency/relevance;
- cooldown/repetition penalty;
- interrupt/resume behavior;
- required authoritative facts;
- optional authorized action request.

Selection must be explainable. Avoid one giant opaque priority number when a
small precedence/eligibility structure can keep behavior understandable.

### Effects boundary

A high-confidence social meaning does not imply a high-confidence gameplay
effect.

Example:

```text
"Get lost."
social meaning: dismissive/hostile = high confidence
possible game effects:
  end conversation
  order NPC to leave
  remove follower from group
```

If gameplay intent is ambiguous, respond/clarify conversationally and do not
commit an irreversible action.

## Personality and relationship influence

Personality/relationship affect **which eligible conversational behavior wins**
and how it is expressed. They do not rewrite factual truth.

Examples:

- aggressive + low trust may favor WARN/RETALIATE;
- cautious + threatened may favor DEFUSE/END_CONVERSATION;
- close relationship may permit teasing or softer boundary responses;
- guarded personality may suppress unsolicited follow-up.

Use existing actor/relationship projections. Do not clone personality or
relationship state into the dialogue subsystem.

## Conversational beats

Introduce lightweight, bounded beat identity only if it can live on the
existing lifecycle/thread state.

A beat is a conversational situation, not a scripted dialogue tree.

Initial reusable beat families may include:

- FIRST_CONTACT;
- SUSPICIOUS_INTRODUCTION;
- FRIENDLY_CATCHUP;
- ARGUMENT_ESCALATION;
- RECONCILIATION;
- REQUESTING_HELP;
- SHARING_NEWS;
- REACTING_TO_DANGER;
- MEDICAL_CONCERN;
- FACTION_TENSION.

A beat declares:

- entry conditions;
- eligible conversational behaviors;
- optional goals/pressures;
- exit/suspend/resume conditions;
- cooldown/expiry.

Do not encode fixed sentence sequences. ResponsePlan and Dialogue Content still
own wording.

## Confidence policy

Use semantic confidence to control behavior, not merely recognition.

Recommended conceptual bands:

```text
HIGH
  → understand and respond; effect only if authoritative/action intent is clear

MEDIUM
  → context may disambiguate when strong evidence exists

LOW / CONFLICTED
  → clarify or acknowledge uncertainty
```

No confidence score may bypass authority checks.

## Underspecified command/state inference

Many linguistic forms should converge on the same semantic desired state.

Example:

```text
"wait"
"hold on"
"stay here"
"don't move"
"stay put"

→ companion movement desired state = HOLD
```

Do this through reusable semantic/pragmatic normalization, not a separate
hard-coded response branch for every phrase.

Negation, quoted speech, third-person mentions and uncertain targets remain
mandatory negatives.

## Response composition

The Director selects behavior; `ResponsePlan` composes it.

Example:

```text
dialogueAct = WARN
topic = player_hostility
tone = irritated
groundedFactRefs = [...]
secondaryAct = BOUNDARY_WARNING
optionalReturnTopic = ...
```

Dialogue Content then realizes wording according to style/personality without
changing meaning.

Different NPCs may realize the same plan differently, but all variants remain
meaning-equivalent.

## Optional PBrainZ parity

PBrainZ remains optional and downstream.

It may receive:

- selected ResponsePlan/dialogue acts;
- allowed grounded fact refs;
- compact topic/beat/context;
- speech style;
- explicitly permitted actions.

It may not:

- invent facts;
- change the selected gameplay action;
- mutate relationships/inventory/tasks;
- bypass privacy;
- create a second memory truth store.

Provider-disabled deterministic mode must remain fully conversationally
functional.

## Semantic Lab cognition inspector

Extend the existing Semantic Lab/Observatory instead of building another app.

For a selected turn, expose a human/agent-readable path:

```text
Player utterance
  ↓
semantic candidates + confidence/provenance
  ↓
selected pragmatic frame
  ↓
relevant context / pending obligation / topic salience
  ↓
eligible Director reactions + rejection reasons
  ↓
selected reaction and why
  ↓
ResponsePlan / facts / optional action request
  ↓
final rendered EN/TL text
  ↓
authoritative side effects, if any
```

Raw JSON remains available under diagnostics, but should not be the primary
debug experience.

The existing "Why did this win?" surface should explain the full selected
conversation turn rather than only the final selector.

## P12 phases

### P12A — recognized-to-response parity and cognition baseline

First reproduce the user-observed hostile-turn contradiction through the real
Core+Hoomans Lua worker and the same Simulation path.

Required:

- run typo/noise variants including the user example and clean insult controls;
- record parser candidates/selected IR, policy branch, response pool/plan,
  realization ID, rendered text and any action/effect;
- determine why a recognized `HOSTILE_REMARK` can display generic
  clarification despite current policy/tests;
- repair the actual seam without adding a one-off phrase;
- add a regression proving recognized high-confidence social meaning cannot
  silently degrade to generic clarification when a valid deterministic branch
  exists;
- establish a multi-turn baseline set for later P12 phases.

**Gate:** the screenshot class of contradiction is reproduced/explained and
fixed through the actual production path.

### P12B — candidate interpretation and pragmatic frame

Expose/reuse bounded alternative interpretations from Core where available and
add context-aware pragmatic resolution.

Prove:

- pending question answer vs interruption;
- challenge question;
- accept/refuse/dismiss;
- quoted/negated/third-person negatives;
- ambiguous candidate clarification.

**Gate:** context changes interpretation without inventing semantic facts.

### P12C — generalized conversation state

Extend existing ContextState/lifecycle with bounded topic salience, obligations,
recent acts, referents, commitments and suspended topics.

Prove:

- question interruption/resume;
- "How?", "Why?", "How many?", "And him?";
- second NPC and second player isolation;
- expiry/ambiguity safety;
- bounded serialized state.

### P12D — Dialogue Director reaction arbitration

Implement reusable conversational behavior candidates and explainable
selection.

Prove at minimum that the same hostile semantic act produces different
eligible/selected reactions from contrasting grounded personality/relationship
contexts while keeping the same factual truth and no unauthorized effect.

### P12E — beats and bounded initiative

Add reusable beat/state pressure over existing lifecycle state.

Prove:

- argument escalation and apology/reconciliation;
- first-contact interruption;
- one grounded NPC follow-up;
- cooldown prevents repetitive prompting;
- explicit dismissal/exit ends initiative.

### P12F — underspecified language normalization and safe action inference

Generalize common conversational/command paraphrases to shared semantic desired
states.

Prove:

- multiple HOLD/FOLLOW/dismiss forms converge;
- ambiguous "get lost" style language does not execute destructive group/task
  effects without sufficient intent/context;
- negative/quoted/third-person cases never dispatch.

### P12G — compositional response planning

Use dialogue acts + grounded refs + tone/style + optional return-to-topic in the
existing ResponsePlan/Dialogue Content architecture.

Prove:

- multiple personality styles;
- EN/TL parity;
- deterministic offline output;
- no semantic difference between wording variants;
- optional PBrainZ realizes the same selected plan.

### P12H — Semantic Lab cognition observability

Make the cognition trace usable for humans/agents.

Prove the selected Simulation turn shows:

- candidate meanings;
- contextual/pragmatic selection;
- topic/obligation evidence;
- reaction candidates and rejection reasons;
- selected Director behavior;
- ResponsePlan and grounded facts;
- final displayed text;
- effects/authority route.

No new simulator or sixth standalone app.

### P12I — held-out conversational acceptance

Run multi-turn real-worker acceptance with:

- typos/noisy language;
- interruptions/resumptions;
- pronouns/ellipsis;
- ambiguous intent;
- social hostility/apology;
- wellbeing/medical;
- commands with safe inference;
- world/event follow-up;
- typed/clicked parity;
- two NPCs / two players;
- EN/TL;
- PBrainZ off/on parity;
- zero false gameplay dispatch on protected negative set;
- bounded memory/CPU and no per-tick scan;
- full resource-aware Python, focused Xvfb, native Lua, Kahlua,
  CodeBuilder/idempotence and save-safety gates.

**P12 gate:** conversation is context-sensitive, explainable and naturally
multi-turn without adding a second authority or requiring exact phrasing for
ordinary supported meanings.

## Performance constraints

P12 is turn/event driven.

Forbidden:

- per-frame or per-NPC tick language reasoning;
- scanning every response pool every turn;
- persisting full transcripts;
- storing large per-player×NPC prose histories;
- sending every candidate to PBrainZ;
- recomputing stable persona/profile text repeatedly when revisions did not
  change.

Measure:

- parser/pragmatic/director turn latency;
- context projection latency;
- many-pair sparse state size;
- worker startup;
- held-out suite wall time;
- optional-provider overhead separately.

## Final handoff rule

P11 completion does **not** return the parent goal to live-test handoff once
this P12 expansion is approved.

After P11I passes, update `PROGRESS.md` and continue automatically to P12A,
then through P12I.

Stop only when:

- all P11 and P12 developer-side gates pass;
- a genuine technical/authorization/scope blocker prevents further work; or
- all developer-implementable work is complete and only the explicitly
  user-owned native Project Zomboid SP/MP live acceptance remains.
