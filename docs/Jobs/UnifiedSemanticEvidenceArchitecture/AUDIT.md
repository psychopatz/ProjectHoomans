# Audit — Unified Semantic Evidence Architecture

Audit anchor: ProjectHoomans 2bc4810f. This is source/runtime evidence, not implementation acceptance for this new goal.

## Existing memory/context tiers

### Session / immediate

PNC_SemanticDialogueContextState already owns bounded ephemeral conversation state:

- default recent turns: 12;
- mentions: 32;
- focus: 8;
- flows: 8;
- agenda: 8;
- prior topic history: 4;
- Director active/recent/cooldowns.

This is the correct source for same-conversation adjacency, pending questions/offers, active beats, recent semantic acts and immediate repair context. It must not become persisted transcript memory.

### Current day / compact episodic projection

Conversation/Memory/Events already stores compact per-NPC memory:

- record.memory.d: current packed world day;
- record.memory.s: at most 8 triples eventCode,targetSeed,flags;
- record.memory.t: per-player seed + topic bitmask;
- repeated short event/target pairs coalesce and move to the newest position;
- previous-day short/topic state is discarded by normalization.

This is the correct cross-conversation bridge for earlier-today semantics.

### Durable

Existing owners already persist bounded long-lived meaning:

- relationship memories: limit 20, strength and decay;
- conduct evidence: limit 64, strength and decay;
- compact conversation-memory long lane: limit 6 quadruples eventCode,targetSeed,day,flags;
- knowledge/backstory systems for their own facts.

No generic semantic feature should create a parallel durable database.

## Salience audit

Conversation-memory event metadata supports salience 0..255.

Today, salience is used by upsertLong to decide which event survives when the compact six-entry durable lane is full. Higher salience survives; age breaks ties.

The short/day lane currently evicts by recency only. It does not use salience.

Only four first-party memory event definitions are explicitly registered with nonzero salience/long-term metadata:

- saved from incapacitation — 245;
- survived horde attack — 245;
- abandoned in combat — 235;
- protected from attacker — 215.

Other social event source types can become dynamically hashed Conversation Memory event types with salience 0 and longTerm false. This is an architectural drift risk.

## Current split authority

Gameplay social effects are defined in PNC_SocialEventDefinitions.

Conversation-memory metadata is separately authored under common/.../Conversation/Definitions/Memory/EventTypes.

These definitions can drift and already cover different event sets. Future semantic mechanics should not require maintaining both.

## Existing ranking concepts

The codebase already uses distinct concepts:

- NLU confidence/priority — interpretation evidence;
- reference resolver salience-like score — recency/topic/role/capability;
- Interaction Director relevance — behavior/beat arbitration;
- relationship/conduct strength + decayPerDay — lasting effect;
- Conversation Memory salience — retention importance.

The new architecture should give them explicit names/contracts and common diagnostics, not collapse them into one score.

## Existing integration seam

PNC_SemanticInteractionProviders already normalizes actor, relationship, world and knowledge projections, including adapter support for external actors. PNC_SemanticInteractionContext consumes that projection and feeds the existing Pragmatic Resolver and Interaction Director.

This is the preferred extension seam: add normalized semantic evidence through the existing provider/context path rather than create another context engine.

## Storage concern outside the new authority

The relationship interactionJournal is bounded at 80 entries but entries may contain large presentation fields including up to 512 characters each of player and NPC text. It is read by presentation/debug/authority paths.

Do not make it the new semantic evidence authority. A future storage-cleanup job may reduce it separately.

## First reproduced product symptom

A reset Semantic Lab scenario can recognize im sorry as APOLOGIZE yet choose the generic apology response “Noted. Let's move on.” without demonstrated grievance/repair context.

The parser is not the defect. The missing piece is generic contextual evidence admission between recognition and pragmatic behavior.
