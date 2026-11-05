# Agent runbook — Test Suite Rationalization

1. Work in `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` on existing **main** only. Read root `AGENTS.md`, then this job's README, ARCHITECTURE, AUDIT, ACCEPTANCE, ROADMAP, AGENT_RUNBOOK, and **PROGRESS last**.
2. Before edits verify local branch/HEAD/status, origin/main, worktrees and concurrent user/agent changes. Preserve unrelated work. No new branches, blind pull, destructive reset/rebase, automatic stash/discard, force push, native PZ launch or Workshop publication.
3. P0 is evidence-first. Do not use historical semantic counts as the current baseline. Inventory all test-bearing locations and entrypoints, including generated/declarative cases and specialized architecture/refactor checks.
4. Work one coherent family at a time. Trace its production subjects and execution boundary before classifying it. Similar names are not duplication proof.
5. Apply the deletion gate from ARCHITECTURE/ACCEPTANCE before removing a test. If evidence is insufficient, classify `UNKNOWN_KEEP` and continue.
6. Prefer existing shared harnesses, parameterized/table-driven cases and declarative Semantic Test fixtures when they preserve the same boundary. Do not create another competing generic test framework.
7. Preserve failure localization. Do not merge hundreds of unrelated assertions into opaque mega-tests merely to reduce file count.
8. Preserve test isolation semantics. Reuse worker/process setup only after proving no state/order leakage. A faster but weaker suite is a regression.
9. After each bounded cleanup/consolidation batch run the narrow affected suite plus appropriate broader regression. If a deletion causes coverage ambiguity, revert that deletion rather than weakening acceptance.
10. Keep PROGRESS current with exact evidence, metrics and next unreviewed family. Continue automatically through all mandatory phases. A chunk/phase completion does not finish the parent goal.
11. Do not modify root `AGENTS.md` for job progress. Do not check in `GOAL_PROMPT.md`. Keep generated reports/manifests outside watched `media/` and outside source saves.
12. Final report must distinguish: kept canonical/boundary tests, merged coverage, removed duplicate/superseded tests, tier moves, before/after metrics, developer-side validation, unresolved `UNKNOWN_KEEP` items, and user-owned native acceptance.
