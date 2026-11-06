# Acceptance — Test Suite Rationalization

## Accepted baseline evidence

The first pass established a useful inventory and regression baseline. Those measurements may be reused if source revisions remain applicable, but they do not prove family review.

## Review acceptance

Every maintained family must end in a reviewed classification.

Final acceptance requires:
- **zero `UNREVIEWED` maintained families**;
- zero `pending_family_review` final dispositions;
- no generic default classification counted as review;
- every `UNKNOWN_KEEP` item backed by test-specific production-subject, boundary, overlap, and risk evidence.

A generated subject list alone is not enough. The agent must actually inspect relevant production ownership/callers and plausible overlapping tests before choosing a reviewed disposition.

## Domain coverage requirement

The review must cover the complete root/non-semantic estate, not only semantic tests.

For every substantive root domain, record:
- number of families reviewed;
- production subjects/authority boundaries;
- keep/merge/delete/move/repair counts;
- important consolidation candidates considered;
- focused validation after changes.

No domain may be skipped because the default suite already passes.

## Per-test/family deletion proof

A deletion requires at least one:
1. protected production behavior/path is gone;
2. equal-or-stronger current coverage exists at the same or stronger boundary;
3. meaningful assertions are migrated and old-vs-new parity is demonstrated;
4. coverage exclusively belongs to a deliberately removed compatibility/migration path.

Evidence must identify the old test, current production path, replacement/current coverage, assertions or contract preserved, and validation result.

## Consolidation proof

For merges/parameterization:
- preserve meaningful positive and negative cases;
- preserve authority/runtime boundary;
- preserve deterministic isolation;
- preserve readable per-case failure identity;
- compare old and new behavior on the same source revisions before deleting the old form.

A single opaque mega-test is not accepted merely because it reduces file count.

## Runner/performance proof

For process/worker reuse or suite-routing changes:
- prove isolation and order independence where applicable;
- detect state leakage;
- preserve timeout/crash diagnostics;
- preserve supported old commands or document explicit replacements;
- measure before/after runtime.

The ~9.8s root Lua suite should not be distorted merely to reduce runtime. The ~17-minute Semantic Python suite deserves separate evidence-led optimization.

## Mandatory protected areas

Do not reduce meaningful protection for:
- authoritative state mutation and persistence;
- currently supported migrations;
- server/client and SP/MP boundaries;
- NPC identity/incarnation/presence lifecycle;
- inventory/state ownership;
- live/abstract transitions;
- networking cleanup/reconnect/death behavior;
- semantic actions with gameplay/relationship effects;
- public domain/module contracts;
- still-possible historical regressions.

## Production-change scope gate

Any production-code change made during this test-rationalization job must have:
- a specific failing/current contract that requires it;
- focused regression evidence;
- explanation why the change is not merely unrelated product refactoring.

Unrelated production changes must remain outside the job.

## Final acceptance evidence

Final acceptance requires:
- zero unreviewed maintained families;
- every reviewed family has a specific disposition;
- all approved deletions satisfy the deletion gate;
- all approved merges preserve parity and failure localization;
- substantive non-semantic root domains have actual review summaries;
- semantic Python slow families have been evaluated for overlap/startup/tier improvements;
- focused suites green after relevant batches;
- final default/full developer suites green;
- before/after file count, LOC, assertions/cases where practical, runtimes, merge/delete/move counts recorded honestly;
- current worktree/status described accurately;
- no unrelated production behavior change accepted implicitly;
- no root AGENTS goal-history bloat;
- no checked-in GOAL_PROMPT;
- native PZ/SP/MP acceptance separated as user-owned unless explicitly requested.

The final raw test count remains informational, not an acceptance gate.
