# Contextual Dialogue & Quest Framework — Project Hoomans

**Product objective:** Semantic Lab is the primary offline procedural authoring, generation, debugging and real-production-Lua verification environment for Project Hoomans' NPC language, contextual conversations, gameplay actions and quests. **Newly approved expansion:** LLM-like multi-turn contextual intelligence with NO required LLM or large runtime corpus.

**Planning baseline:** remote branch `docs/contextual-dialogue-quest-framework-20261018` at `b06533f909acec8ad838df8c3aa0259d9143a30c`, reviewed 2026-10-19. This is remote source evidence; local Codex state may be ahead or dirty. Recorded work through G3B includes 17 generated / 18 registered capability flows, quest foundation, bounded prior-action and cognition memory, and worker/X11 tests. Those are narrower slices; they do NOT establish arbitrary multi-turn contextual dialogue. Historical ledger remains `HISTORY_20261018.md`.

## Product outcome

Players should converse naturally with the *same* NPC about wellbeing, injuries, needs, weather, inventory, personality, social relationships and quests, including elliptical follow-ups ("Why?", "What happened?", "How many?", "And him?"), pronouns ("it", "some", "there"), corrections, clarifications, interruption/resumption and follow-up commitments. An NPC can recall a truly acknowledged promise or known event later, with provenance and participant scoping; cannot invent injury causes, weather observations, inventories or quest progress.

The language understanding pipeline remains **PsychopatzCore → Hoomans Context/Flow/Plan → authoritative gameplay owners → EN/TL grounded responses**, optionally passing the approved response plan to PBrainZ for richer wording. No PBrainZ-specific duplicate memory or action service. Different response phrasing is not proof of context comprehension; real IR→discourse-state→fact→plan→final text evidence is mandatory.

## Current sequence, without disrupting ongoing work

1. **G3C (current ONE Next Chunk)** — complete existing generated quest-flow command-boundary and worker-restart verification, unless the agent's actual local checkout has already accepted it with proof. Do not redo historically accepted G0/G3B implementation.
2. **C0–C6 (next major phase)** — baseline, conversation frames, sparse memory/commitments, dialogue planning, dataset-assisted Code Builder, Semantic Lab trace/editor and performance/EN+TL/PBrainZ acceptance.
3. Quest, gift, command, task and social-action regressions remain protected. Never infer completion from a GitHub branch or agent report without checking runtime evidence.

## Read order

Root `AGENTS.md` → job `AGENT_RUNBOOK.md`, `AUDIT.md`, `ARCHITECTURE.md`, `AUTOMATIC_FLOW_GENERATION.md`, `CAPABILITY_ACTION_BINDINGS.md`, `CONDITION_CONTEXT.md`, `QUEST_CONTRACT.md`, **`CONVERSATIONAL_INTELLIGENCE.md`**, **`DATASET_CONVERSATION_PIPELINE.md`**, `PROCEDURAL_NLP_COMPILER.md`, `AUTHORING_WORKBENCH.md`, `ROADMAP.md`, `HARNESS_ACCEPTANCE.md`, **`CONVERSATION_ACCEPTANCE.md`**, **`PROGRESS.md` LAST**. `GOAL_PROMPT.md` is a bootstrap, not the source of architectural truth.

Implementation references: `PNC_SemanticDialogueContextState{,_Turns,_Mentions,_Snapshot}.lua`, `PNC_SemanticContextResolver.lua`, `PNC_SemanticDialogueReferenceResolver.lua`, `PNC_SemanticDialogueFlowKernel.lua`, `PNC_SemanticDialogueResponsePlan.lua`, Knowledge/Cognition/Quest owners, `tools/semantic_compiler/`, `tools/semantic_harness/`.

## Mandatory boundaries

Do not implement new generic NLP interpreter, runtime embeddings/large corpus, runtime LLM requirement, command dispatcher, social memory silo or quest authority. Offline Lua remains first-class; versioned modular source and deterministic compilation; single authoritative action, zero effect during Preview; no per-frame all-NPC scans. Keep translations in `common/media/lua/shared/Translate/<LANG>/*.json`. Real Project Zomboid SP/MP testing and Workshop publishing/installing remain user-owned; Codex CLI CUA discovery is not a required development tool.

**Completion:** actual worker shows contextual multi-turn decisions, grounded facts and explanations, topic suspension/resumption and correctly scoped memory across conversation boundary; corpus-assisted compiler safely generates supported language/state definitions; the existing Semantic Lab can inspect and edit them; measured performance and modularity gates pass. Work ends developer **READY FOR USER LIVE TEST**, never native PZ claim.
