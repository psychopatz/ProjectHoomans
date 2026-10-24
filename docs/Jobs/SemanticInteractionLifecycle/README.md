# Semantic Interaction Lifecycle

**Status:** ACTIVE — approved successor semantic roadmap after Contextual Dialogue Persona & Choices P14 acceptance.  
**Audit baseline:** ProjectHoomans main at 6aa9493aa6df0a48b2dd148a247a742d8fb38e5d on 2026-10-24.  
**Native Project Zomboid SP/MP:** user-owned final acceptance; not a Codex implementation blocker.  
**Goal prompt:** chat-only by repository policy; do not create GOAL_PROMPT.md.

## Goal

Turn Project Hoomans dialogue into one scalable semantic interaction lifecycle.

The completed system must:

- migrate legacy flavor-text speech such as greetings, farewells, emote replies, combat/medical/social/world-event reactions and similar spontaneous dialogue into the existing semantic response architecture;
- let typed Talk input, semantic buttons, emotes and headless/Semantic Lab input participate in the same conversation context;
- preserve appropriate context when an NPC speaks first and the player answers by any supported input surface;
- support Façade-like conversational continuity across interruptions, UI closes, hours and in-game days;
- preserve only meaningful long-term consequences, facts, commitments and memories rather than permanent transcripts;
- remain sparse and bounded for hundreds of NPCs and multiple simultaneous players;
- keep multiplayer gameplay and persistence server-authoritative;
- use the existing Semantic Lab and production Lua worker as the main agent test/debug surface;
- retain the current offline deterministic semantic path; PBrainZ/LLM realization remains optional.

The parent goal is not complete when one migration family or one phase passes. It is complete only after the full roadmap has developer-side acceptance through the existing production Lua path.

## Why this is a new roadmap

Contextual Dialogue Persona & Choices P14 is accepted and established production save rehydration, layered social context and the real save-backed Semantic Lab path. This job consumes that foundation.

The current source still has two parallel speech worlds:

1. semantic dialogue, flows, response plans, actor context and contextual suggestions;
2. legacy SocialFlavor / companion-command flavor / emote / farewell / event-reaction text paths.

This job removes that split without replacing the working parser, response catalog, Relationship/Knowledge authority, ConversationBlocks, P14 rehydration path or Semantic Lab.

## Governing principles

1. **Known actions enter after NLU.** Typed/freeform text uses NLU. Emotes, lifecycle events and known game events directly create typed semantic acts.
2. **Text is presentation; meaning is state.** Rendered prose may disappear. Important semantic consequences survive through compact state owned by the correct domain.
3. **Persist consequences, not transcripts.** Ordinary greetings, thanks and small talk normally leave no persistent conversation record.
4. **No theoretical Player × NPC cross-product.** A pair record exists only after a meaningful interaction produces something worth preserving, and is removed again when empty after compaction.
5. **Dormant NPCs do zero dialogue work.** No per-NPC per-tick semantic or memory scans.
6. **Hydrate lazily.** Rich thread/context state exists only for actors currently interacting or handling a meaningful event.
7. **Bound every collection.** Turns, open beats, suspended threads, commitments, pair memories, NPC episodes, recent realization IDs and diagnostic traces all have explicit limits.
8. **Deduplicate shared truth.** Shared world events are stored once and referred to by compact knowledge/memory references.
9. **Gameplay domains still own truth.** Semantics interprets and realizes facts; it does not duplicate inventory, relationship, faction, quest, Knowledge, health or world state.
10. **ConversationBlocks keep branching/effect authority.** Their wording may later use common realization, but their authored branching, gates, weighted outcomes, repeat rules and server effects are not replaced by a flavor system.

## Preserve

This job builds on and must not duplicate:

- docs/Jobs/ContextualDialoguePersonaChoices/
- docs/Jobs/SemanticDialogueDecoupling/
- docs/Jobs/ContextualSemanticSuggestions/
- docs/Jobs/ContextualSemanticIntelligence/
- docs/Jobs/ContextualDialogueQuestFramework/
- docs/Jobs/GroundedWorldKnowledgeGossip/
- existing ActorConversationContext and SpeechStyleContext
- existing semantic flow registry/kernel
- existing ResponseCatalog and ResponsePlan
- existing semantic choice/provider path
- existing production save rehydration and isolated real-save Semantic Lab runtime
- existing Relationship, Knowledge, Faction, Inventory and other authoritative domains
- existing SocialFlavor content as migration source material until parity is proven

## Explicit non-goals

- no new parser or generic chatbot framework;
- no LLM requirement for ordinary dialogue;
- no full transcript persistence;
- no per-tick NPC conversation simulation;
- no new Python gameplay simulation inside the harness;
- no duplicate relationship/knowledge/faction/inventory stores;
- no automatic conversion of every ConversationBlock into a semantic flow;
- no Steam Workshop publishing or agent-owned native PZ acceptance.

## Read order

1. repository root AGENTS.md
2. this README.md
3. AGENT_RUNBOOK.md
4. AUDIT.md
5. ARCHITECTURE.md
6. MIGRATION_MATRIX.md
7. PERSISTENCE_AND_SCALING.md
8. ROADMAP.md
9. HARNESS_ACCEPTANCE.md
10. PROGRESS.md **last** for current truth and the exact Next Chunk

