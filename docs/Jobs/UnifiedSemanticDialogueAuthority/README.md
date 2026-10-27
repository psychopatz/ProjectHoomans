# Unified Semantic Dialogue Authority

**Status:** IN PROGRESS — P0–P9 accepted foundation; P10 canonical cleanup / legacy purge is mandatory before live-test handoff.
**Project Hoomans audit baseline:** `181b58bcc30dc65dc61d19a49d6238abca50ece9`.
**PsychopatzCore audit baseline:** `cf28189c57f7810f31d25c46c11eb88080f47baa`.
**Checkout:** existing `main` only.
**Goal prompt:** chat-only; do not create `GOAL_PROMPT.md`.

## Parent goal

Finish the semantic migration so **Project Hoomans has exactly one conversational intelligence authority**.

All Project Hoomans-owned NPC speech — direct Conversation, greetings/farewells, social reactions, combat/medical/leader-loss/companion/world-event speech, ToolReplies, emote replies, compatibility event speech, and contextual follow-ups — must resolve meaning through the existing semantic architecture before wording or presentation.

The finished system must:

- make `ResponseCatalog` / semantic flows / response plans the only Project Hoomans authority that chooses conversational meaning and response family;
- use the existing Dialogue Content / speech-realization path for meaning-equivalent wording variation;
- use one Project Hoomans semantic speech presentation path for queue/localization/TTS/nameplate delivery; generic PsychopatzCore compatibility infrastructure may remain externally, but Project Hoomans must not retain first-party legacy prose registries or legacy Flavor aliases;
- migrate remaining `PNC_SocialFlavorDefinitions_*`, `PNC_ConversationToolReplyCatalog`, legacy conversation-registry authority, and first-party compatibility prose selection into the semantic/content architecture;
- let NPC-initiated semantic event speech open a bounded, grounded conversational response window so the player can naturally ask appropriate follow-up questions;
- route those follow-ups through the existing semantic Suggestions, `DialogueContextState`, context resolver, response plans and authoritative fact refs rather than a separate event-chat subsystem;
- remain deterministic/offline by default, with PBrainZ/LLM optional and downstream of semantic truth;
- remain sparse and performant for many NPCs/players: no per-NPC/per-tick dialogue scans, no transcript persistence, no duplicated world/relationship/inventory truth, and no repeated semantic evaluation at render time;
- expose canonical content and provenance through the existing Semantic Lab / Observatory rather than creating another editor or simulator;
- finish P10 by deleting migration-era executable/source-only dialogue registries, removing legacy Project Hoomans `Flavor*` namespaces, compacting Dialogue Content identity/schema, and grouping Studio content by semantic family.

## Central invariant — no split system

> **One semantic system chooses what an NPC means. One content/realization layer chooses equivalent wording. One presentation layer delivers it.**

Required authority line:

```text
GAME / WORLD / SOCIAL / COMMAND TRUTH
        ↓
existing semantic context + typed semantic act/event
        ↓
ResponseCatalog / flow / response plan
        ↓
semantic realization + phrase/content selection
======== CONVERSATIONAL AUTHORITY LINE ========
        ↓
localization / formatting
        ↓
queue / cooldown / priority / nameplate / Conversation / TTS
```

During P10, temporary migration aliases may exist only while a caller is actively being converted. The accepted steady state contains **no Project Hoomans first-party legacy Flavor prose/content registry or legacy Flavor compatibility namespace**. Git history, not production source, preserves migration archaeology.

## Follow-up invariant

NPC-initiated speech is not a dead-end ambient bark when the underlying event is conversationally relevant.

Use the existing lifecycle:

```text
grounded world/social event
  → semantic response plan
  → NPC speech
  → SemanticInteractionLifecycle.RecordNPCSpeech
  → bounded beat/eventRef/factRefs/response window
  → existing semantic Suggestions
  → player click or typed follow-up
  → DialogueContextState / ContextResolver
  → grounded semantic answer
```

Do **not** create a second recent-event dialogue registry if the existing lifecycle/thread/response-window contracts can own the state.

## Preserve and reuse

This goal consumes the accepted foundation from:

- `docs/Jobs/SemanticInteractionLifecycle/`;
- `docs/Jobs/SemanticObservatoryDialogueQuality/`;
- `docs/Jobs/ContextualSemanticSuggestions/`;
- `docs/Jobs/ContextualSemanticIntelligence/`;
- `docs/Jobs/GroundedWorldKnowledgeGossip/`;
- `docs/Jobs/ContextualDialogueQuestFramework/`.

Reuse:

- `PNC.Semantics.ResponseCatalog`;
- `PNC.Semantics.ResponsePlan`;
- `PNC.Semantics.RealizationAuthority`;
- `PNC.Semantics.DialogueContextState`;
- `PNC.Semantics.SemanticInteractionLifecycle`;
- semantic Suggestions/providers/ranking;
- ActorConversationContext / SpeechStyleContext;
- existing Knowledge/Relationship/Faction/Health/Inventory/Task/Quest/gameplay authorities;
- existing Dialogue Content Registry / CodeBuilder generation;
- existing semantic speech delivery/presentation behavior, renamed or consolidated where legacy `Flavor` terminology would imply obsolete authority;
- existing production Lua worker, Semantic Lab, Observatory and headless CLI.

## Explicit non-goals

- no new parser;
- no second response catalog;
- no second follow-up engine;
- no second recent-event conversation database;
- no transcript persistence;
- no per-NPC tick scanner;
- no duplicated world/relationship/faction/inventory/health state;
- no replacement of ConversationBlocks branching/effect authority;
- no requirement for PBrainZ/LLM;
- no native PZ launch or Workshop publication by the agent;
- no root `AGENTS.md` goal-status additions.

## Execution authority

This directory is the **sole active roadmap for the new semantic-authority retirement/follow-up migration**.

Older `SemanticInteractionLifecycle` P11 documents remain valuable historical/architectural evidence, but their earlier “complete” claim is superseded for the residual prose/content owners identified in this audit. Do not run two concurrent migration roadmaps.

## Read order

1. repository root `AGENTS.md`;
2. this `README.md`;
3. `AGENT_RUNBOOK.md`;
4. `AUDIT.md`;
5. `ARCHITECTURE.md`;
6. `EVENT_FOLLOWUP_CONTRACT.md`;
7. `MIGRATION_MATRIX.md`;
8. `PERFORMANCE_AND_SCALING.md`;
9. `HARNESS_ACCEPTANCE.md`;
10. `P10_CANONICAL_SEMANTIC_CLEANUP.md`;
11. `ROADMAP.md`;
12. `PROGRESS.md` **last** for current phase and exact Next Chunk.
