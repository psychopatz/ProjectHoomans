# Agent runbook — Semantic Exhaustive Dialogue Quality Sweep

## Operating goal

Implement the **entire** Semantic Exhaustive Dialogue Quality Sweep described by this job: production-backed dimension discovery, semantic buckets, deterministic coverage planning, bounded resumable execution, compact per-sentence provenance, reachability, quality flags/clustering, agent/CLI review bundles, existing-Simulation UI integration, affected replay and full developer-side regression/performance acceptance.

The full parent objective is the completion boundary. Start from PROGRESS.md Next Chunk, but after accepting each chunk update progress and continue automatically through all remaining mandatory roadmap work. Do not stop after a planner, one batch, one quality rule, one GUI page or one successful defect discovery.

## Checkout and document order

1. Work only in /home/psychopatz/Zomboid/Workshop/ProjectHoomans on existing main.
2. Read root AGENTS.md, then this job's README.md, AGENT_RUNBOOK.md, ARCHITECTURE.md, QUALITY_RUBRIC.md, HARNESS_ACCEPTANCE.md, ROADMAP.md, AUDIT.md, and **PROGRESS.md last**.
3. Read relevant current authority docs from:
   - docs/Jobs/SemanticTestSubsystem/
   - docs/Jobs/SemanticObservatoryDialogueQuality/
   - active semantic architecture jobs only as needed for real runtime ownership.
4. Before writes inspect actual branch/HEAD/status/worktrees and origin/main. At job creation local main was 17 commits ahead of origin; preserve unpublished/user/agent history. Never reset, rebase, auto-stash, blind-pull, force-push or create a new branch.
5. Do not push remote Git history unless explicitly authorized by the user/standing repository workflow. Never Workshop-publish.

## Reuse rules

- Extend tools/semantic_harness/testing/; do not create a competing runner.
- Reuse LuaSemanticWorker, existing fixture scenario/session, Response Observatory, Conversation Inspector, source lineage and Simulation.
- Production Lua decides semantic selection/flow/realization. Python may plan contexts, project evidence and flag text; it may not become the semantic oracle.
- Use worker control/persona catalogs as the default dimension source. Add explicit adapters only when a production-backed scenario dimension cannot be represented generically.
- Keep the existing <=64 expansion/batch safety boundary unless measured evidence and an explicit design revision justify a different cap.
- Preserve existing quality-matrix/fuzz utilities when they retain distinct bounded acceptance roles.

## Implementation discipline

- Build machine-readable services first; GUI consumes the same services.
- Keep deterministic case identity and catalog/source fingerprints from the start.
- Treat full sweep as complete declared semantic bucket/coverage strategy execution, not an unbounded float/world Cartesian product.
- Store compact evidence rows; full traces are lazy/replayed.
- Generated run artifacts go to a gitignored path outside watched media and source saves.
- Every quality heuristic has positive and negative controls and a confidence class. Do not turn subjective style preferences into gameplay rules.
- Relationship/family/perspective flags must use semantic/context evidence where available.
- LLM review is optional developer tooling. Project Zomboid runtime must remain fully offline/deterministic.
- LLM content proposals cannot alter plans/actions/authority/eligibility unless explicitly approved as a behavior change.
- Quality Sweep GUI belongs under Simulation only. Do not resurrect duplicate Studio testing/coverage surfaces.

## Validation loop

For every coherent chunk:

1. define production-backed observable behavior and negative controls;
2. implement narrowly;
3. run focused unit tests;
4. run real-worker integration/parity relevant to the chunk;
5. inspect output bounds and reproducibility;
6. update PROGRESS.md current truth;
7. continue to the next mandatory chunk.

Use current repository toolchain conventions. Prefer tools/semantic_harness/.venv/bin/python where Tk/Python 3.12 is required. Do not hide slow/failing tests behind larger blanket timeouts.

## Git/document discipline

- Modify only this job docs and code/tests genuinely required by this goal.
- Do not modify root AGENTS.md unless a repository-wide durable rule truly changes.
- Do not create checked-in GOAL_PROMPT.md.
- Keep PROGRESS.md current-state-only; replace stale narrative rather than append chronology.
- Commit coherent accepted chunks locally after verifying status/ownership.
- Preserve unrelated local work and unpublished commits.

## Stop conditions

Stop only when:

1. the complete developer-side ROADMAP and HARNESS_ACCEPTANCE gates are satisfied; or
2. a genuine authorization/scope/technical blocker prevents further safe work after independently implementable work is completed; or
3. only explicitly user-owned native SP/MP acceptance remains.

A phase completion, passing focused test, generated report, or found bad sentence is not a stop condition.

## Final report

Report:

- parent-goal status;
- implemented services/surfaces;
- exact evidence and test counts;
- coverage strategy and measured case/batch performance;
- known limitations and honest untested categories;
- commit(s);
- whether anything was pushed;
- explicit statement that native PZ/source saves/Workshop were not touched unless separately authorized.
