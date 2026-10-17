# Contextual Semantic Intelligence — autonomous job

**Goal:** Improve Project Hoomans offline NPC dialogue with Façade-inspired contextual reaction selection and multi-turn coherence **without replacing its existing parser, response pools, or optional PBrainZ provider**.

**Job namespace:** `docs/Jobs/ContextualSemanticIntelligence/`. This is a self-contained, concurrently executable agent goal. A worker assigned to this job must not treat another job's progress ledger or bootstrap prompt as its own. No repository-root `GOAL_PROMPT.md` is required for this goal.

## Read order

1. `AGENT_RUNBOOK.md` — scope, parallel-agent and publication boundaries.
2. `AUDIT.md` — revision-specific evidence and known unknowns.
3. `ARCHITECTURE.md` — owners, invariants, and reaction-design constraints.
4. `ROADMAP.md` — ordered phases and mandatory acceptance gates.
5. `HARNESS_ACCEPTANCE.md` — real-Lua Semantic Lab validation protocol.
6. `PROGRESS.md` — one active phase and one Next Chunk.
7. `GOAL_PROMPT.md` — compact /goal bootstrap.

## Canonical pre-existing sources

- `AGENTS.md` — repository-wide mod layout, file-watcher and protected-call safety.
- `docs/Systems/Semantics.md` — existing Semantics architecture and historical refactor notes; **do not overwrite its historical evidence**.
- `docs/architecture/PROJECT_HOOMANS_DOMAIN_CONTRACT.md` — ownership and cross-domain authority.
- `tools/semantic_harness/README.md` — existing Semantic Lab user/worker contract.
- `tools/semantic_compiler/README.md` — offline WordNet/interaction compilation.
- PsychopatzCore and PBrainZ are distinct repositories; do not make cross-repository changes without checking a specific acceptance need and ownership.

## Success criterion

A healthy NPC, an injured NPC, and an NPC with an urgent need receive *meaningfully appropriate*, fact-grounded offline reactions to the same question. Relevant follow-up questions continue the correct conversational topic. The Semantic Lab loads production Lua and tests these scenarios with machine-checkable semantic assertions. Real game SP/MP acceptance remains separate and mandatory. Preserve all existing semantic gameplay authorization.
