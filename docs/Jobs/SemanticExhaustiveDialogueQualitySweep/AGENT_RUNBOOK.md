# Agent runbook — Semantic Exhaustive Dialogue Quality Sweep

## Operating goal

Finish the sentence-first Semantic Dialogue Quality Sweep.

The user-facing objective is simple:

> Generate as many meaningful production NPC sentence variants as practical, show what triggered each one, and make awkward dialogue easy to spot.

Do not turn the Quality Sweep back into a testing dashboard.

## Read order

1. root `AGENTS.md`
2. `README.md`
3. `AGENT_RUNBOOK.md`
4. `ARCHITECTURE.md`
5. `GUI_WORKBENCH.md`
6. `QUALITY_RUBRIC.md`
7. `HARNESS_ACCEPTANCE.md`
8. `ROADMAP.md`
9. `AUDIT.md`
10. `PROGRESS.md` **last**

Start from the Immediate Next Chunk in PROGRESS and continue automatically through remaining mandatory roadmap work.

## UX invariant

Default Quality Sweep workflow must remain:

`Generate Sentences → browse sentences → filter/search → inspect context`.

Do not make these primary user controls again:

- smoke/full/pairwise strategy;
- batch IDs;
- coverage matrices;
- reachability status tables;
- plan/resume terminology.

These belong in Advanced developer tooling only.

## Product priority

When choosing work, prefer in this order:

1. generate more distinct meaningful production sentences;
2. make trigger/context evidence accurate;
3. make awkward/repetitive lines obvious;
4. make source/semantic provenance inspectable;
5. improve developer diagnostics.

A larger dashboard is not progress unless it helps sentence review.

## Production authority

- Production Lua owns semantics, eligibility, selection and realization.
- Python may discover surfaces, plan contexts and target variant-frontier cases.
- Python may not reimplement semantic eligibility/selection as truth.
- Use production explain evidence for frontier search.

## Current accepted fixes

Preserve:

- sentence-first top-level Quality Sweep UI;
- live sentence rows after each completed batch;
- categorical `identityTrust` handling;
- production-discovered default surfaces;
- balanced full/review planning across all surfaces;
- exact-input Full Inspector replay;
- working cancel/resume foundation;
- complete response-pool pagination.

## Immediate technical direction

The next major capability is **variant-guided sentence expansion**.

Use the full response registry and observed selected variants to ask:

> Which registered variants have not yet appeared in the sentence review?

For an unobserved variant:

1. inspect production explain evidence;
2. identify relevant context constraints;
3. select bounded candidate values from existing sweep dimensions;
4. execute real Lua;
5. record outcome;
6. add newly reached rendered lines to the normal evidence table.

Do not require the user to manually run a separate reachability mode.

## Quality acceptance discipline

Synthetic rows are unit controls only.

Do not claim real acceptance for family, perspective, clustering, anti-repeat or eligible-but-dominated unless the relevant behavior is exercised by production Lua or a faithful production-backed replay fixture.

For contrast tests, assert the actual contrast.

For anti-repeat, prove actual selection/phrase/history behavior.

For `ELIGIBLE_NOT_SELECTED`, prove production says eligible=true but a different candidate wins.

## GUI discipline

- long operations off Tk thread;
- UI updates via queue/`after()`;
- analyzer exceptions must never blank the sentence table;
- evidence rows remain visible even if optional quality analysis partially fails;
- Advanced reachability scans must not block normal review;
- do not mutate remembered user save state.

## Git discipline

- existing `main` only;
- inspect status/upstream/worktrees before writes;
- preserve unrelated work;
- no blind pull/reset/rebase/auto-stash/force-push;
- no checked-in `GOAL_PROMPT.md`;
- do not modify root `AGENTS.md` unless a repository-wide durable rule changes;
- commit coherent accepted chunks;
- do not push unless explicitly authorized.

## Validation loop

For every chunk:

1. identify real production observable;
2. implement narrowly;
3. add focused unit controls;
4. add/extend real-worker acceptance;
5. inspect actual rendered sentences;
6. run relevant regressions;
7. update PROGRESS.md;
8. continue automatically.

## Stop conditions

Stop only when:

- all mandatory roadmap/acceptance gates pass;
- a real blocker prevents further safe work after independent work is exhausted; or
- only explicitly user-owned native acceptance remains.

Do not stop because the GUI renders, a sweep completes, or a large number of cases was generated.
