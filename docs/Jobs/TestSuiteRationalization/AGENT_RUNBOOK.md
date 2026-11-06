# Agent runbook — Test Suite Rationalization

1. Work in `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` on existing **main** only. Read root `AGENTS.md`, then this job's README, ARCHITECTURE, AUDIT, ACCEPTANCE, ROADMAP, AGENT_RUNBOOK, and **PROGRESS last**.
2. Before edits verify local branch/HEAD/status, origin/main, worktrees and concurrent user/agent changes. The current worktree already contains prior rationalization changes; preserve them and do not reset/stash/discard them merely to obtain cleanliness.
3. Treat the first pass as **partial evidence**, not completed work. P0 inventory/baseline and proven repairs/deletion may be retained; previous P2/P6 completion claims are revoked.
4. Start R0 by correcting the audit model: executable tests default to `UNREVIEWED`. A generic generated sentence cannot convert an entry to `UNKNOWN_KEEP` or any other reviewed classification.
5. `UNKNOWN_KEEP` is permitted only after actual review of production subjects/callers, authority/runtime boundary, plausible overlap candidates, and modification risk. Record specific evidence.
6. Work one coherent production domain at a time. Do not return to a semantic-first loop while the non-semantic root estate remains mostly unreviewed. Maintain a domain ledger showing reviewed/remaining counts and dispositions.
7. For root Lua families, optimize primarily for maintainability, ownership clarity, duplicate scaffolding/mocks, fragmentation and legacy removal; the current ~9.8s runtime is already cheap. Do not weaken isolation just to reduce milliseconds.
8. For Semantic Python/Harness families, runtime is a first-class concern: the measured full suite is ~1,036s. Investigate duplicate scenario/parity coverage, repeated worker startup and tier placement while preserving isolation and authoritative production-Lua execution.
9. Apply deletion/consolidation gates before removing or merging coverage. If review proves a family valuable, keep it. If evidence remains genuinely inconclusive after review, `UNKNOWN_KEEP` with specific evidence is acceptable.
10. Preserve failure localization. Do not replace many precise tests with opaque mega-tests merely to reduce file count.
11. Production changes made during the first pass are not automatically accepted. Review them for current-contract necessity; preserve unrelated user work and do not expand scope into general product refactoring.
12. After each bounded domain batch, run the narrow affected suite plus appropriate broader regression, update manifest/domain evidence/PROGRESS, then continue automatically to the next unreviewed domain.
13. Do not modify root `AGENTS.md` for job progress. Do not check in `GOAL_PROMPT.md`. Keep reports/manifests outside watched `media/` and source saves.
14. Do not claim the worktree is clean because HEAD is 0/0 with origin. Report branch synchronization and worktree cleanliness separately.
15. Final report must include reviewed domain coverage, kept/merged/deleted/moved/repaired counts, before/after test files/LOC/assertions/runtimes, unresolved reviewed `UNKNOWN_KEEP` evidence, exact worktree state, and user-owned native acceptance.
