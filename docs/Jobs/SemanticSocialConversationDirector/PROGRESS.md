# Progress — Semantic Social Conversation Director

**Status:** PLANNED — READY FOR IMPLEMENTATION.
**Branch:** existing `main` only.
**Planning anchor:** `56b77cf4eeae680cffac277fc416fe6591f95a82`.
**Current phase:** D0 — Baseline and affordance authority freeze.
**Parent completion boundary:** D0-D8 developer acceptance; a phase/chunk completion does not complete the parent goal.

## Verified accepted foundation

- `SemanticInteractionSceneRuntime` is developer-complete and already owns canonical autonomous multi-actor Scene lifecycle.
- Scene Runtime already supports explicit speaker/recipient/participant/observer roles, semantic continuation, bounded participants/turns, player handoff and cross-domain Opportunity providers.
- `PNC_SemanticInteractionDirector.lua` is already a generic semantic plan arbiter and must remain the lower-level response authority.
- `PNC_SemanticDialogueSuggestions_GeneratedAffordanceProvider.lua` is a bounded semantic response-candidate source but is explicitly player-oriented today.
- `PNC_SemanticAffordanceContinuationPolicy.lua` currently applies recurrence in terms of player turns.
- Therefore the first implementation gap is actor-neutral affordance extraction, not creation of a new conversation runtime.

## Immediate Next Chunk — D0A

### Goal

Freeze the current production affordance/response behavior and prove the exact reusable semantic contract before changing it.

### Required work

1. Trace all production callers/registrations of GeneratedAffordanceProvider and the response-channel/button projection.
2. Capture representative current candidate outputs for:
   - answer/inform;
   - agree/disagree/acknowledge;
   - apology/repair;
   - hostility/challenge/de-escalation;
   - wellbeing pending question;
   - identity pending question;
   - trait-gated/contextual suggestions;
   - recurrence suppression.
3. Capture player UI/semantic response behavior and typed-input independence.
4. Identify player-specific inputs and classify each as:
   - truly player-only;
   - generic actor data under a player-shaped field;
   - UI-only;
   - authority-specific and not reusable.
5. Define/encode the minimal actor-neutral affordance candidate schema and adapter boundary in tests/docs/code comments as appropriate, without changing visible behavior yet.
6. Freeze Scene Runtime speaker/recipient/observer interoperability needed by the later NPC consumer.
7. Add focused regression coverage that will fail if actor-neutral extraction changes current player semantics accidentally.

### D0A acceptance

- current player affordance frontier is reproducible in focused Lua/worker fixtures;
- typed input remains independent of generated-button recurrence;
- player-specific coupling is enumerated with source evidence;
- minimal actor-neutral candidate contract is explicit;
- no new ambient Social Director/NPC chatter behavior yet;
- focused tests, relevant worker checks, Kahlua compile and `git diff --check` pass.

## After D0A

Update this file with actual evidence, advance to the next mandatory D0/D1 chunk, and continue automatically through D8. Do not stop merely because D0A or any later phase passes.

## Standing safety

- no new branch;
- preserve unrelated work;
- no native PZ launch unless explicitly assigned;
- no Workshop publication;
- no rendered-text reparsing;
- no feature-specific parallel conversation engine;
- no global actor/faction scan;
- no transcript/generated-choice persistence;
- no routine LLM path.
