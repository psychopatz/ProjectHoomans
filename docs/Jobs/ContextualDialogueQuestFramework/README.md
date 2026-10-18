# Contextual Dialogue & Quest Framework — Project Hoomans

**Purpose:** Make Semantic Lab the primary **procedural authoring, compilation, inspection and real-Lua testing workbench** for Project Hoomans' lightweight offline NLP, contextual dialogue, existing game actions and eventual quests. Preserve an optional PBrainZ realization path without making it a requirement.

**Current source checkpoint:** `docs/contextual-dialogue-quest-framework-20261018` @ `382e93a342f1d6ee13fc2007a7fbbdf66a7afa7c` (2026-10-18). This is branch-source evidence, not a local worktree/GUI/runtime verification. See `PROGRESS.md` for the single current phase and Next Chunk.

## User-facing outcome

In ONE existing Semantic Lab environment, a human or coding agent should be able to:
1. Choose a gameplay capability (e.g. Follow, Wait Here, Wait At, gift, quest offer) from **live registered production owners**, not guess Lua functions.
2. Add or generate reviewed phrases, speech acts, intents, slots and contextual conditions; see parsing collisions and unsafe ambiguity.
3. Visually connect conversation, condition, action-binding, result and response states; use a synchronized supported code/source editor for precise changes.
4. Run preview and committed turns through the **actual production PsychopatzCore + Project Hoomans Lua** pipeline; see accepted/rejected action route, side effects and real NPC wording.
5. Compile reviewed semantic definitions into deterministic **modular Lua modules/manifests and existing EN/TL translation layout**, review source diffs, restart the worker and confirm the compiled content is loaded and working.

The generator procedurally creates **supported deterministic semantic artifacts**; it cannot promise unlimited free-form understanding or automatically prove unsafe unreviewed synonyms. Its job is less repetitive authoring, explicit boundaries, fewer collisions/errors, and new commands/flows without giant centralized conditionals.

## Scope and ownership

- **Existing production owners stay intact.** Core owns generic NLU and IR; Hoomans owns policy, flow state, game context, registered game-action adapters, conversations, social state and quests; gameplay domains own actual effects. `tools/semantic_compiler` is an existing generator seed, not a new runtime parser.
- Engine facts/events are read-only observations. They **do not** execute gameplay commands. Action bindings are allowlisted references to existing dispatchers and server authorization, never arbitrary Lua source in a node.
- Reuse Conversation Blocks' typed condition evaluation and Hoomans Knowledge/Personality/Relationship data. Avoid a second gate engine, item taxonomy, quest authority, task scheduler or NPC memory store.
- Keep Project Zomboid Build 42.20 source conventions. Core/MarketSense/PBrainZ sibling repositories are not changed without source-backed necessity and authorization.
- Existing `SemanticDialogueDecoupling` live-testing status and `ContextualSemanticIntelligence` historical evidence remain independently owned; do not rewrite their ledgers.

## Read order

`AGENTS.md` → this job's `AGENT_RUNBOOK.md` → `AUDIT.md` → `ARCHITECTURE.md` → **`CAPABILITY_ACTION_BINDINGS.md`** → **`PROCEDURAL_NLP_COMPILER.md`** → `AUTHORING_WORKBENCH.md` → `CONDITION_CONTEXT.md` → `QUEST_CONTRACT.md` → `ROADMAP.md` → `HARNESS_ACCEPTANCE.md` → **`PROGRESS.md`** (sole Next Chunk) → `GOAL_PROMPT.md`.

Technical reference: `tools/semantic_harness/README.md`, `tools/semantic_compiler/README.md`, `docs/Systems/Semantics.md`, `docs/Systems/ConversationBlocks.md`, `docs/Systems/CompanionCommands.md`.

## Finished product / handoff

A new interaction is *authored → validated against actual registry/capabilities → compiled to properly packaged source → loaded on fresh worker → run with contextual, EN/TL and negative cases → traces actual dispatch or denial*. Representative Follow, Stay/Wait At and Gift cases prove different ownership paths. Quest and durable-context slices use these same contracts. Performance/scalability bounds measured; developer work ends at **READY FOR USER LIVE TEST**. Native PZ SP/MP tests, Workshop publication and final distribution remain user-owned, never prerequisites for autonomous source development.
