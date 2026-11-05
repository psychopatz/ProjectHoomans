# Roadmap — Test Suite Rationalization

**Parent goal:** Review the complete maintained developer test estate, remove or consolidate only evidence-proven redundancy/legacy coverage, improve test infrastructure and execution topology, and finish with equal-or-stronger meaningful regression protection plus measured before/after results.

| Phase | Mandatory acceptance |
| --- | --- |
| **P0 — Exact-HEAD inventory and baseline** | Recheck local main/upstream/worktrees; enumerate every maintained test file/family, runner, fixture source and relevant helper; measure current logical cases/assertions where practical, focused/default/full commands, runtimes and major slow families; map production subjects/boundaries; build complete audit manifest. Historical job counts are reference only. |
| **P1 — High-confidence obsolete and duplicate cleanup** | Identify tests whose production path is gone or whose same-boundary coverage is strictly superseded. Apply deletion gate test-by-test/family-by-family. Remove dead compatibility/migration/refactor artifacts only after callers and current contract are proven. Focused + broader regression gates pass after each bounded batch. |
| **P2 — Fixture/setup and repetitive smoke consolidation** | Find repeated mocks/setup/boilerplate and one-behavior-per-file families. Merge into shared/table-driven/declarative coverage only where diagnostics and execution boundaries remain intact. Record old assertions -> new cases and parity. |
| **P3 — Semantic and authority-boundary rationalization** | Reconcile current semantic smoke tests with the existing Semantic Test Subsystem; remove only fixture-proven duplicates while retaining imperative authority contracts. Review repeated presence/identity/inventory/network/live-abstract boundary families for safe parameterization rather than blind deletion. |
| **P4 — Python/Harness/process optimization** | Audit Python test modules, Semantic Lab/Harness parity suites, worker/process startup and repeated fixture work. Consolidate duplicated Python coverage and reduce unnecessary startup/runtime only where isolation/order-independence is proven. |
| **P5 — Suite topology and routing** | Define/implement practical fast/default, focused, integration and acceptance lanes using existing runners where possible. Expensive valuable tests move lanes rather than disappear. Keep commands discoverable in test docs and preserve existing supported entrypoints or provide explicit migration. |
| **P6 — Full developer acceptance** | Every maintained family classified; all removals satisfy deletion gate; final focused/default/full suites pass; before/after files/cases/runtimes/slow-family/helper metrics recorded; final manifest has no unreviewed family; Git diff clean of unrelated work; user-owned native acceptance documented if applicable. |

Each phase is an execution gate, **not a stop condition**. Continue automatically through P0-P6 until the full developer-side objective is accepted or a genuine blocker prevents further safe work.

There is no mandatory target test count. A suite that remains above 1,000 tests can be accepted if each retained family has defensible value and execution cost is appropriately routed.
