# Test Suite Rationalization — current progress

**Status:** PLANNED — implementation not started.
**Documentation audit reference:** GitHub `main` at `b588e6d826ec290bb7d3e5756e4d86bd53556e25` on 2026-11-06.
**Local exact-HEAD/worktree baseline:** NOT YET VERIFIED. GitHub state must not be treated as proof of local cleanliness.

## Verified planning evidence

- Root `tests/README.md` documents isolated one-process-per-Lua-test execution, shared `tests/support/test.lua`, profiler mode and refactor-binding checks.
- Current root tests visibly include many subsystem-specific `*_smoke.lua` and `*_presence_boundary_smoke.lua` families.
- The completed Semantic Test Subsystem established a canonical declarative production-Lua-backed behavioral test path, but deliberately retained imperative low-level contract tests and removed only proven duplicates.
- Historical semantic counts in that job are not current baseline numbers.

## Current phase

**P0 — Exact-HEAD inventory and baseline**

### Immediate Next Chunk

1. Verify local repository branch, HEAD, status, origin/main and concurrent worktrees before any edit.
2. Discover every maintained test entrypoint and test-bearing directory, not only `tests/` and not only filenames containing `test` or `smoke`.
3. Enumerate test families, runners, fixtures/helpers and production subjects/boundaries.
4. Run/document current supported focused/default/full commands and profiler/timing evidence where safe.
5. Produce the complete audit manifest and baseline metrics.
6. Identify candidate cleanup families, but **make no deletion solely from naming/similarity**.
7. Update this progress ledger with verified counts and the first evidence-backed rationalization batch, then continue automatically into P1.

## Completion boundary

Do not mark this job complete because:
- test count falls below 1,000;
- one test family is cleaned;
- one runner gets faster;
- a phase passes.

Completion requires P6 acceptance across the full maintained test estate.
