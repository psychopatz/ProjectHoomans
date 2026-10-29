# Audit — Semantic Social Conversation Director

## Revision

Planning anchor: `56b77cf4eeae680cffac277fc416fe6591f95a82` on existing `main`.

This is a source/document audit. It does not claim new native Project Zomboid acceptance.

## 1. The multi-actor conversation runtime already exists

`docs/Jobs/SemanticInteractionSceneRuntime/` is developer-complete. Its accepted architecture already establishes:
- one global autonomous Scene Runtime/Scheduler;
- explicit participants, speaker, recipient and observers;
- semantic-plan continuation without reparsing rendered dialogue;
- NPC->NPC and NPC->player interoperability;
- bounded Opportunity/provider admission;
- combat, grounded social knowledge and community-excursion production adopters;
- transient runtime state with no transcript persistence;
- hard bounds including <=4 participants and <=8 generic semantic turns.

Therefore this goal must not introduce a second generic NPC conversation runtime, faction-specific conversation scheduler, gossip engine, combat exchange engine or companion-only dialogue engine.

## 2. The existing semantic affordance system is the correct reuse seam, but is still player-oriented

The current generated affordance implementation is:
`shared/PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_GeneratedAffordanceProvider.lua`.

Source observations:
- it describes itself as a generated **player-affordance provider**;
- it derives bounded conversational strategies from an already-selected DiscourseFrame/InteractionPlan;
- it does not parse text and does not execute gameplay authority;
- it caps candidates at 8;
- it contains player-specific context helpers such as `playerHasTrait`;
- it already emits reusable semantic strategies such as acknowledgement, follow-up, apology/de-escalation/challenge and contextual relation acts.

The recurrence policy:
`PNC_SemanticAffordanceContinuationPolicy.lua`
currently reasons specifically over recent **player** turns.

This is the main architectural gap for the requested feature: the useful semantic response vocabulary exists, but the current provider/policy cannot simply be treated as a generic autonomous-actor chooser without first extracting/normalizing the actor-neutral contract.

## 3. The lower-level Interaction Director is already generic

`PNC_SemanticInteractionDirector.lua` is an explainable generic interaction arbiter. It:
- normalizes semantic stimuli;
- projects InteractionContext and PragmaticResolver state;
- indexes bounded beat/behavior candidates;
- applies predicate/cooldown/stickiness arbitration;
- produces an InteractionPlan;
- separates preview from commit.

The new Social Conversation Director must operate above this authority. It should decide social opportunity, participant/speaker competition and semantic motive/affordance selection; the existing Interaction Director continues to own response-plan arbitration.

## 4. Existing Scene architecture already distinguishes roles needed for group conversation

The accepted Scene Runtime contract distinguishes:
- speaker;
- recipient/addressee;
- participant;
- observer.

This is sufficient to support:
- NPC A -> NPC B while C is a participant;
- C joining a later turn;
- NPC -> group-like semantic acts where a concrete next recipient is still selected;
- player overhearing without buttons;
- player becoming the addressee and receiving existing response affordances.

No new observer/participant model is needed.

## 5. Existing combat architecture already demonstrates bounded chatter arbitration

`SemanticCombatBanterTacticalIntent` already contains a Combat Banter Arbiter concept for:
- moment priority;
- speaker/personality relevance;
- recency;
- chatter budgets;
- suppression of chorus responses.

The generic Social Conversation Director should learn from that model but must not move combat policy into generic social infrastructure or replace the existing combat arbiter. Generic infrastructure owns common admission/turn/chatter primitives; domains keep domain-specific urgency/facts.

## 6. Required architectural gap

What is missing is a generic social/dramaturgy layer that can answer:

1. Is there a meaningful social motive/opportunity worth opening or extending a scene?
2. Which bounded actors are eligible participants?
3. Which actor has the strongest reason to speak now?
4. Which actor is the intended recipient?
5. Which semantic affordances are valid for an NPC responder?
6. Which candidate best fits personality, relationship, knowledge, condition and recent scene context?
7. Should the correct decision be silence?
8. Should another participant join, retarget, interrupt, or allow the scene to end?
9. Are local/actor/pair/topic chatter budgets available?

That is the scope of this goal.

## 7. Performance implications

The existing architecture already forbids per-frame semantic regeneration and global actor scanning. The new layer must remain:
- event-driven;
- bounded to event-provided/local candidate sets;
- subject to active-scene and chatter budgets;
- free of full-faction/full-NPC scans;
- free of routine LLM calls;
- transient unless an existing durable authority independently records a meaningful outcome.

## 8. Immediate implementation implication

The first implementation chunk must not start with ambient chatter content.

It must freeze current player-affordance behavior and establish the actor-neutral semantic-affordance contract beneath it. Otherwise an NPC selector would either duplicate player-button logic or depend on player-specific fields, recreating the exact split architecture this goal is meant to avoid.
