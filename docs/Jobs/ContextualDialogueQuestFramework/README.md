# Contextual Dialogue & Quest Framework — Project Hoomans

**Status:** NEW GOAL, PLANNED; implementation not started by this documentation commit.
**Created:** 2026-10-18. **Audited remote baseline:** ProjectHoomans main at a3eb2e4db553f9c03b7f66a6ff6717878e1668e0.

## Product outcome

Evolve the existing offline production-Lua semantic conversation pipeline and Semantic Lab into a contextual NPC dialogue and quest framework. A player should be able to speak naturally about an NPC's situation, change topics, return to an earlier commitment, offer help, accept or discuss a quest, and receive a response grounded in what this specific NPC knows, remembers and can legitimately do. The system must remain useful with PBrainZ disabled. PBrainZ can optionally verbalize an already authorized dialogue plan, but is not the authority for NPC memory, quest state or gameplay changes.

This job also upgrades the *existing* Semantic Lab into a genuinely usable human/agent authoring tool: create/rename/delete/drag/link branches, edit their semantic and contextual conditions, use a code-style definition view, test through real production Lua, and produce restart-persistent mod definitions rather than worker-only drafts.

## Boundaries and prior work

- Reuse PsychopatzCore's parser, candidate IR and existing Hoomans dialogue policy/flow registry/kernel; do not create a second NLP interpreter.
- Reuse current world/time/weather providers, NPC social/personality and relationships, NPC knowledge/memory and Conversation Blocks condition gates wherever real contracts support reuse.
- Quests are a NEW separately owned Project Hoomans gameplay domain; dialogue only interprets/requests and renders outcomes.
- Preserve older jobs and their independently recorded evidence. SemanticDialogueDecoupling is READY FOR USER LIVE TEST in its own PROGRESS; ContextualSemanticIntelligence carries older phase evidence and is not silently declared finished or rewritten.
- This documentation does not authorize starting Project Zomboid, running multiplayer hosting, or publishing to Steam Workshop. Those remain user-owned live acceptance/release activities.

## Read these files in order

1. Root **AGENTS.md**, then this job's **AGENT_RUNBOOK.md** — safety and execution policy.
2. **AUDIT.md** — baseline truth and unresolved verification.
3. **ARCHITECTURE.md** — ownership, context, state, authority and invariants.
4. **CONDITION_CONTEXT.md** — source-backed condition and dialogue-context model.
5. **QUEST_CONTRACT.md** — quest lifecycle and gameplay event contract.
6. **AUTHORING_WORKBENCH.md** — Semantic Lab visual/code editing and persistence design.
7. **ROADMAP.md** — sequence and measurable gates.
8. **HARNESS_ACCEPTANCE.md** — real worker / UI / negative-case acceptance.
9. **PROGRESS.md** — sole source for the CURRENT phase and exactly ONE Next Chunk.
10. **GOAL_PROMPT.md** — compact Codex /goal bootstrap; do not execute every phase at once.

Reference systems: **docs/Systems/Semantics.md**, **docs/Systems/ConversationBlocks.md**, **docs/Systems/SocialProfiles.md**, **docs/Systems/NPCKnowledge.md**, **docs/architecture/PROJECT_HOOMANS_DOMAIN_CONTRACT.md**, **tools/semantic_harness/README.md**.

## Done means

A newly authored dialogue and one representative quest travel the *production* semantic parser/flow/response route in Semantic Lab, use authoritative contextual gates and quest transitions, preserve a real bounded memory/commitment across a conversation boundary, survive worker restart via checked-in mod source, and show actual response, selected IR/flow, gate decisions and effects. Offline, EN/TL, deterministic repeatability, unrelated-flow regressions, negative/permission scenarios and measured idle-cost limits are mandatory developer gates. Actual PZ SP/MP remains a separate user-owned acceptance handoff.
