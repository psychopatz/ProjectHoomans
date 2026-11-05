# Audit — Test Suite Rationalization

## Source-verified starting facts

Audit reference: GitHub `main` at `b588e6d826ec290bb7d3e5756e4d86bd53556e25` on 2026-11-06. Exact local worktree state is **not** proven by GitHub and must be rechecked before implementation.

The current root test contract documents:
- `python3 tests/run_tests.py` as the isolated Lua suite;
- `python3 tests/run_tests.py profiler` for profiling;
- parallel/verbose execution through `--jobs` / `--verbose`;
- `tests/refactor_binding_smoke.py` for split-module private-binding checks;
- one process per Lua test;
- shared test loading through `tests/support/test.lua` and `T.load/T.read/T.path/T.addPackagePaths`.

The current root `tests/` directory contains many individually named `*_smoke.lua` families. Examples visible at current main include:
- abstract follow/world/presence-boundary smoke tests;
- several subsystem-specific `*_presence_boundary_smoke.lua` files;
- action/behavior smoke tests;
- semantic smoke families.

These names alone do **not** prove redundancy. Separate files may protect distinct authorities or failure boundaries.

## Existing semantic precedent

The completed `docs/Jobs/SemanticTestSubsystem/` job is a useful precedent but its counts are historical, not the current repository baseline.

That job recorded at its execution point:
- 146 `pnc_semantic*_smoke.lua` files / 3,572 assertions before cleanup;
- 197 Python Semantic Harness test modules;
- a canonical declarative, production-Lua-backed Semantic Test subsystem;
- retention of imperative low-level contract tests where fixture migration would lose boundary coverage;
- removal of only two duplicated behavioral smoke tests after parity was proven.

Therefore this job must not assume that declarative fixtures supersede every imperative semantic test.

## Problem statement

The likely debt is not merely raw test count. It can include:
- overlapping regression cases;
- migration-era tests whose production path has been removed;
- repeated PZ mocks/setup/fixtures;
- one-bug-one-file smoke growth that can be table-driven without losing diagnostics;
- expensive tests running in the default lane despite being acceptance-oriented;
- repeated worker/process startup;
- obsolete compatibility/refactor tests;
- test families whose ownership or execution boundary is unclear.

The exact current counts, runtimes, slowest families, and overlap map remain **P0 evidence to measure on exact local HEAD**.

## Primary risks

1. **False deduplication:** two tests that look identical may exercise different client/server, live/abstract, persistence, presence, network, or integration boundaries.
2. **Coverage laundering:** replacing an imperative authority test with a higher-level fixture can make the suite smaller while weakening what it proves.
3. **Count-driven pruning:** deleting tests to hit a numerical goal can erase valuable historical regressions.
4. **Runner optimization that breaks isolation:** process reuse may leak state or hide order dependence.
5. **Stale-baseline reasoning:** older job counts must not be presented as current.
6. **Production distortion:** production behavior must not be changed merely to make stale tests pass.

## Audit conclusion

A repository-wide rationalization is justified, but deletion must be evidence-gated. The first mandatory implementation activity is a complete current test inventory and measurable baseline, followed by family-by-family classification and bounded consolidation.
