# Semantic Dialogue Orchestrator — independent goal

**Status: proposed, not implemented.** Target: Project Hoomans Build 42.20; offline Lua first, optional PBrainZ, fully server-authoritative actions. Goal: new conversational branches can be registered and tested in Semantic Lab without global semantic-pattern collisions or additions to a monolithic intent/response chain.

## Read order
1. Repository `AGENTS.md`, then this goal's `AGENT_RUNBOOK.md`.
2. `AUDIT.md` (verified source vs unresolved runtime evidence).
3. `ARCHITECTURE.md` and `INTEROP.md`.
4. `ROADMAP.md`, then `ACCEPTANCE.md`.
5. `PROGRESS.md` (the **one current Next Chunk**).
6. `GOAL_PROMPT.md` (copyable job-local Codex bootstrap).
7. Existing `docs/Systems/Semantics.md`, `docs/architecture/PROJECT_HOOMANS_DOMAIN_CONTRACT.md`, `tools/semantic_harness/README.md`.

## Coordination
The earlier `docs/Jobs/ContextualSemanticIntelligence/` job (on an **unmerged** feature PR at audit time) already implements and documents considerable wellbeing/social/context work. Treat that work and its Native SP/MP gate as existing evidence, not as work to recreate. Reconcile exact latest HEAD/branches before coding. Translation modularization is owned by `docs/Jobs/TranslationCatalogModularization/`; do not edit its PROGRESS.

**Definition of done:** the observed name/wellbeing collision is eliminated at the true production Lua route, actual NPC relationship effects are safe, independent flows can interleave, preview/commit are separate, and a new module is extensible through explicit registration. The Semantic Lab must report candidate arbitration and transitions from production Lua. Native SP/MP verification remains separately mandatory.
