# Acceptance — Test Suite Rationalization

## P0 baseline requirements

Before pruning:
- verify exact local ProjectHoomans main revision and relevant PsychopatzCore revision(s);
- inventory all test files/cases/fixtures/runners/helpers;
- record supported invocation commands and current pass/fail state;
- measure wall time for default/full and major focused suites where practical;
- identify slow families and repeated startup/setup;
- map each family to current production subjects and execution/authority boundary.

If a suite cannot be executed in the available environment, record that limitation instead of inventing results.

## Per-test/family deletion proof

A deletion requires at least one:
1. protected production behavior/path is gone;
2. equal-or-stronger current coverage exists at the same or stronger boundary;
3. meaningful assertions are migrated and old-vs-new parity is demonstrated;
4. coverage exclusively belongs to a deliberately removed compatibility/migration path.

Evidence should identify the old test, replacement/current path, assertions or contract preserved, and validation result.

## Consolidation proof

For merges/parameterization:
- preserve all meaningful positive and negative cases;
- preserve authority/runtime boundary;
- preserve deterministic isolation;
- preserve readable per-case failure identity;
- compare old and new behavior on the same source revisions before deleting the old form.

A single mega-test that is harder to diagnose is not accepted merely because it has fewer files.

## Runner/performance proof

For process/worker reuse or suite-routing changes:
- prove isolation in both test orders where applicable;
- detect state leakage and order dependence;
- keep timeout/crash diagnostics bounded;
- preserve supported old commands or document explicit replacements;
- measure before/after runtime rather than claiming improvement from intuition.

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

## Final P6 evidence

P6 requires:
- no unreviewed maintained test family in the manifest;
- no deletion lacking an accepted proof category;
- focused suites green after relevant batches;
- final default/full developer suites green;
- before/after counts and runtimes recorded honestly;
- list of `UNKNOWN_KEEP` items, if any, with reason they were retained;
- no unrelated production behavior change;
- no root AGENTS goal-history bloat;
- no checked-in GOAL_PROMPT;
- native PZ/SP/MP acceptance clearly separated as user-owned unless explicitly requested.

The final test count is informational, not an acceptance gate.
