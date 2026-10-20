# Context, conditions, facts and observations — source-backed contract

## Already implemented

On `382e93a3` the production `ConversationRules` condition evaluator is reused by `PNC_SemanticDialogueFlowKernel.lua` via `EvaluateGateStatus`. Flow Registry accepts a bounded gate with `onPass/onFail/onUnknown`; the `weather_context` flow proves one response-only rain/clear/unknown example in previously recorded tests. `PNC_SemanticEngineFacts.lua` registers typed world/game facts; `PNC_SemanticEngineEvents.lua` exposes bounded observations, and a server zombie-kill detector adapter publishes `engine:zombie_killed`. Latest branch behavior has not been freshly rerun by this doc update.

Those are read-only condition/event inputs, **not** action execution and not automatic quest completions. The flow authoring UI should discover actual registered fact IDs, known/unknown values and provenance, and visibly show branch gate results. Never wire observed engine event payload directly into arbitrary Lua callbacks from the editor.

## Shared typed condition domain

Existing Conversation Blocks own condition families: skill, trait, personality, relationship, relationship_state, audience, time, history, plus all/any/not. Existing flow gate bridge must consume that public evaluator. Extend a typed fact only via a registered provider, explicit validation and tri-state behavior. Do not build a second condition evaluator in Python or in an independent semantic flow runtime.

Facts requested for future context: npc health/need/activity, personal perception of weather and threat, time/time band, player/NPC relationships, validated NPC memory, quest status. Store `known`, value, observer/source, revision/time and freshness where appropriate; `UNKNOWN` never implies healthy/safe/allowed. At server commit, re-read authoritative conditions.

## Dialogue context and reference lifecycle

Current Core/Hoomans context state has topic/pending question/active or suspended flow; future work should add only bounded, participant-scoped discourse references when evidence shows a gap. Pronouns ("it", "there", "some"), pending promises, resumed offers and remembered prior conversation must be resolved using actual verified NPC memory, quest and facts with source/expiry; do not invent an injury cause, promised item, shared knowledge or cross-NPC memory.

A player's text is an assertion/request; a world event is evidence only if source/actor is authoritative and target-relevant. Distinguish **meaning recognized**, **fact observed**, **gate eligible**, **action admitted**, **result completed** throughout tests and UI.

## Examples

- Rainy outdoor NPC can truthfully discuss observed rain; sheltered or unloaded NPC with no reliable observation should qualify uncertainty.
- "What happened?" following an injury disclosure resolves injury topic only; unknown cause is answered as unknown.
- "I'll bring some" after a bandage request refers to those bandages if confidence/provenance support it; ambiguous context triggers clarification, never a random inventory action.
- "Follow me" is a requested command and must still be authorized even if personality wants to help.
- "I've already delivered it" cannot complete an item quest without an authenticated delivery event.
- Resumption, gifts and quests must use exact speaker/addressee/scope; player A's promise is not automatically player B's.

No per-tick context enumeration across all NPCs or full history serialization. Use event/turn-driven snapshots and bounded references. See `CAPABILITY_ACTION_BINDINGS.md` for action safety and `QUEST_CONTRACT.md` for later server-owned state.
