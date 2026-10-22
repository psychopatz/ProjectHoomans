# Contextual Dialogue Persona & Choices

**Status:** PLANNED / IMPLEMENTATION NOT STARTED  
**Audit baseline:** ProjectHoomans remote `main` at `765bc4076ab82ec2c1eca6ca52cef1c6bf177597` (2026-10-22).  
**Related Dynamic Trading audit baseline:** `psychopatz/DynamicTrading` at `5b97302e39c482682f4fed0c083ad6764b9eee41`.  
**Native Project Zomboid SP/MP:** not tested by this documentation task; user-owned acceptance.

## Goal

Make deterministic NPC dialogue sound contextually different according to the authoritative actor state already owned by Project Hoomans—identity/gender for grammatical and compatibility uses, NPC traits, persistent social personality, directed relationship scores/state, roles/capabilities, and current situation—without allowing style to invent facts or replace gameplay authority.

At the same time, turn the existing semantic reply/suggestion system into a modular, scalable, localization-safe ecosystem. Static conversation choices, active-flow offers, response-plan offers, authored conversation choices, companion capabilities, trader interactions, gossip, quests, and future domains should normalize into one typed candidate contract and re-enter the existing semantic click/dialogue pipeline.

The existing Semantic Lab must become the production-parity authoring/debug surface for this work: editable actor/persona controls, relationship simulation, language switching, candidate/constraint/rank/realization inspection, and bounded A/B or matrix testing through the real Core+Hoomans Lua worker.

## Preserve

This job **builds on** and must not duplicate or replace:

- `docs/Jobs/ContextualSemanticSuggestions/`: typed semantic suggestions, privacy predicates, stale/replay-safe click frames, EN/TL, Core `choicesPart`, real worker integration.
- `docs/Jobs/ContextualDialogueQuestFramework/`: production dialogue flows, ConversationRules conditions, CodeBuilder/InteractionSpec, Semantic Lab Studio/Simulation and worker.
- `docs/Jobs/SemanticDialogueDecoupling/`: parser/policy separation and translation/semantic contracts.
- `docs/Jobs/CoreNPCFoundationMigration/`: shared actor/NPC foundation boundaries.
- `docs/Systems/SocialProfiles.md`, `Relationships.md`, `NPCTraits.md`, and Identity ownership.
- Dynamic Trading's existing portable conversation/NPC-foundation adapter direction.

## Read order

1. repository root `AGENTS.md`
2. this `README.md`
3. `AGENT_RUNBOOK.md`
4. `AUDIT.md`
5. `ARCHITECTURE.md`
6. `ROADMAP.md`
7. `HARNESS_ACCEPTANCE.md`
8. `PROGRESS.md` **last** for current truth and the exact Next Chunk

No checked-in `GOAL_PROMPT.md` is allowed by repository policy. ChatGPT supplies the executable `/goal` in chat only.
