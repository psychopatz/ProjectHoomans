# Agent Runbook: UnifiedSchemaDrivenNPCAI

## 1. Startup Discovery Order (Mandatory)

1. Discover live workspace roots, active PZ build directory (never hardcode `42.20`), branch, `HEAD`, upstream, and dirty/untracked files across:
* `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`
* `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
* `/home/psychopatz/Zomboid/Workshop/DynamicTrading`


2. Read root `AGENTS.md` in each touched repository before any edit.
3. Read `PROGRESS.md` -> `HANDOFF.md` -> needed sections of `ROADMAP.md` and `ARCHITECTURE.md`.
4. Query `codebase-memory-mcp` (`search_graph`, `trace_path`, `get_code_snippet`) before opening large files (`PNC_SocialEventHooks_CombatAdapter_Awareness.lua`, `SceneAdopters.lua`, `PNC_CommunityExcursionService.lua`). Verify symbol hits against exact source.

## 2. CodeBuilder & Generated Artifact Rules

* Never hand-edit generated Lua registries, manifests, indexes, or runtime plans.
* Edit canonical source schemas/packages or compiler code in `psychopatzCore`, then run canonical `CodeBuilder` compile, naming audit, and `reconcile` commands.
* Require clean reconcile (`missing=0`, `drifted=0`, `stale=0`, `retired_present=0`, `ambiguous=0`) and `activeCurrentPsdlIdentityCount = 0`.

## 3. Evidence Hierarchy (Never Conflate Tiers)

Record exact evidence class for every gate:
`static/compiler check` < `unit test` < `production-Lua harness` < `real PZ JVM (pz-runtime-harness)` < `visible GUI acceptance (Colonists Debug GUI)` < `native SP` < `native MP`.

* Do NOT launch native Project Zomboid unless explicitly authorized by the user.
* Scope-local focused tests run during chunks; full multi-repo + scale suites run at phase gates and U6.

## 4. Strict Git & Commit Safety

* Preserve all unrelated staged, unstaged, and untracked changes.
* Forbidden commands: `git add -A`, `git reset`, `git checkout --`, `git stash`, `git branch` (no new branches unless authorized), `git amend`, `git rebase`, `git push`, PRs, tags, or Workshop publishing.
* Stage only exact phase-owned paths (`git add <file1> <file2> ...`) and run `git diff --check` before committing.
* **Cross-repo commit order:**
* When `psychopatzCore` introduces compiler/mechanism contracts consumed by `ProjectHoomans` (U2, U4): commit `psychopatzCore` first -> `ProjectHoomans` (plus reconciled job docs) last.
* When verifying/reconciling cross-repo generated artifacts or Core continuity vectors: follow the active `psychopatzCore` contract rule and record the exact participant commit vector in `HANDOFF.md`.
