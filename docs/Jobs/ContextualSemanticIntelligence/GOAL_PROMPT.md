# Contextual Semantic Intelligence — /goal agent bootstrap

Copy the block below into the dedicated Codex goal agent. This file is **job-local**: never replace a global /goal or another agent's active job.

    /goal
    Repository: psychopatz/ProjectHoomans (use verified local checkout and current HEAD).
    Job namespace: docs/Jobs/ContextualSemanticIntelligence/
    Read in order: AGENTS.md; docs/Jobs/ContextualSemanticIntelligence/AGENT_RUNBOOK.md; AUDIT.md; ARCHITECTURE.md; ROADMAP.md; HARNESS_ACCEPTANCE.md; PROGRESS.md; docs/Systems/Semantics.md; docs/architecture/PROJECT_HOOMANS_DOMAIN_CONTRACT.md; tools/semantic_harness/README.md.
    Purpose: improve offline Lua NPC contextual reactions inspired by Façade; preserve Core NLU, existing conditioned responses, authoritative game domains, and optional PBrainZ.
    Current phase: 0 Semantic Lab correctness baseline.
    Start with exactly ONE Next Chunk from this job's PROGRESS.md: Phase 0A realistic harness wellbeing projection and real-Lua behavioral baseline; do not implement new reaction arbitration yet.
    Required validation: doctor; real production Lua Semantic Lab tests with explicit IR/decision/messages/context/no-side-effect assertions; focused Lua smoke suite; replay conflict ledger; native game acceptance when the phase requires it. JSON fixtures and absence of conflicts alone do not prove language correctness.
    Preserve: existing IR/public APIs/authority, game-source truth, WordNet offline workflow, SP/MP boundaries, bounded event-driven work, and repository AGENTS.md file-watcher precautions.
    Concurrency: isolate this job's docs, working branch, worker sessions and evidence paths; coordinate shared production files with other active agents. Do not edit other jobs' progress.
    On success: update only this job's PROGRESS.md to evidence-backed current state and next bounded chunk; update ROADMAP.md only if gates materially change; commit coherently to an authorized destination and report exact SHA/CI.
    Stop only for true safety/authorization/technical blockers or when all mandatory gates are accepted (maintenance-ready); never invent work or claim unrun tests passed.

## Maintaining this goal

As each Next Chunk is accepted, `PROGRESS.md` becomes the source for the next task. Keep this bootstrap compact and stable unless its durable rules or project target change; detailed requirements belong to the other documents.
