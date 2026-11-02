# Agent runbook — Semantic Exhaustive Dialogue Quality Sweep

## Operating goal

Complete the reopened Semantic Exhaustive Dialogue Quality Sweep after the independent audit disproved the prior P7 acceptance claim.

The target is not merely a runnable batch system. The finished harness must truthfully discover current production surfaces/response pools, execute bounded combinations through real Lua, verify the intended surface was actually reached, preserve full persona/relationship/state provenance, expose run-level quality failures, support reliable cancel/resume, and provide a dedicated Quality Sweep workbench for human inspection.

Read PROGRESS.md last and start from its Immediate Next Chunk. After each accepted chunk, update progress and continue automatically through all remaining mandatory P1–P7 remediation.

## Checkout and document order

1. Work only in `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` on existing `main`.
2. Read root `AGENTS.md`, then this job's:
   - README.md
   - AGENT_RUNBOOK.md
   - ARCHITECTURE.md
   - GUI_WORKBENCH.md
   - QUALITY_RUBRIC.md
   - HARNESS_ACCEPTANCE.md
   - ROADMAP.md
   - AUDIT.md
   - **PROGRESS.md last**
3. Read current Semantic Test Subsystem and Semantic Observatory docs as authority dependencies.
4. Inspect branch/HEAD/status/worktrees/upstream before writes. Preserve unrelated or uncertain changes.
5. Never reset/rebase/auto-stash/blind-pull/force-push/create a branch.
6. Do not Workshop-publish.

## Critical audit corrections

Do not trust the previous `COMPLETE` wording.

Specifically:

- a completed worker request does not prove the planned surface was reached;
- current root-choice names must be discovered/verified from production;
- evidence must use current Inspector actor-context paths;
- trait option objects must normalize to canonical values;
- response-pool reachability must paginate the full registry;
- cancellation must be resumable;
- quality analysis must include cross-row duplicates/repetition;
- a `lazy=true` trace marker is not a functional inspector resolver;
- synthetic rows do not satisfy end-to-end acceptance.

## Reuse rules

- Extend existing `tools/semantic_harness/testing/`.
- Reuse `LuaSemanticWorker`, fixture scenario/session, Response Observatory, Conversation Inspector and source lineage.
- Production Lua owns semantic behavior.
- Python may discover/plan contexts, compare planned vs reached routes, project evidence and evaluate text quality. It may not become a semantic oracle.
- Maintain bounded batch execution and explicit caps.

## GUI ownership

Implement a dedicated top-level **Quality Sweep** workspace in the existing Semantic Harness.

- Simulation remains live/single-scenario interaction.
- Quality Sweep owns broad batch coverage/review.
- Studio remains authoring.

The GUI must consume `DialogueQualitySweepService` or its evolved shared service API. Do not create a separate GUI runner.

The current Simulation Quality Sweep sub-tab may be migrated or reduced to a launcher/summary. Do not maintain two full interfaces.

Long-running execution must not block Tk. Use a safe background worker/event queue and marshal UI updates onto the Tk thread.

## Validation discipline

For each chunk:

1. define the production-backed observable;
2. add negative controls;
3. implement narrowly;
4. run focused unit tests;
5. run real-worker integration;
6. inspect actual output—not only exit status;
7. verify planned surface vs reached surface;
8. update PROGRESS.md;
9. continue to next mandatory chunk.

A test named “real worker” is insufficient if its crucial defect evidence is still synthetic.

## Acceptance evidence discipline

Use precise categories:

- real production Lua;
- production-backed replay fixture;
- synthetic/unit-only;
- GUI hermetic;
- static-only.

Never describe synthetic dictionaries as real production-Lua demonstrations.

For contrast claims, assert the contrast itself. Merely asserting that both outputs exist is not acceptance.

## Git/document discipline

- Keep root AGENTS.md lean and unchanged unless a repository-wide durable rule changes.
- Do not create checked-in GOAL_PROMPT.md.
- PROGRESS.md is current truth, not chronology.
- Commit coherent accepted work locally after checking status.
- Push only when explicitly authorized by current workflow/user.
- Preserve the README workbench direction already present at audit time.

## Stop conditions

Stop only when:

1. all reopened ROADMAP and HARNESS_ACCEPTANCE gates pass; or
2. a genuine blocker prevents safe further work after all independent work is exhausted; or
3. only explicitly user-owned native acceptance remains.

Do not stop because a phase test file passes, the GUI renders, a large sweep completes, or a cluster is found.

## Final report

Report:

- parent status;
- planned vs reached surface coverage;
- full pool/variant enumeration totals;
- real demonstration evidence;
- cancel/resume evidence;
- GUI responsiveness/feature evidence;
- regression counts;
- performance/storage measurements;
- commits and publication state;
- any honest untested categories.
