# Agent Runbook: UnifiedSchemaDrivenNPCAI

## 1. Startup Discovery Order (Mandatory)

1. Discover live workspace roots, active PZ build directory (never hardcode `42.20` in new tests; live runtime layer is `42.20`), branch, `HEAD`, upstream, and dirty/untracked files across:
   * `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`
   * `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
   * `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
2. Read root `AGENTS.md` in each touched repository before any edit.
3. Read `PROGRESS.md` -> `HANDOFF.md` -> needed sections of `ROADMAP.md` and `ARCHITECTURE.md`.
4. Query `codebase-memory-mcp` (`search_graph`, `trace_path`, `get_code_snippet`, `search_code`) before opening large files (`PNC_SocialEventHooks_CombatAdapter_Awareness.lua`, `SceneAdopters.lua`, `PNC_CommunityExcursionService.lua`). Always verify symbol hits against exact source.

## 2. Verified Test & Verification Commands

* **ProjectHoomans Lua suites** (run from `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`):
  * Focused: `python3 tests/run_tests.py <filter>` (e.g., `u1_work_foundation`, `mp_server_file_guard`, `work`, `farming`, `lumber`, `fishing`, `corpse`, `tasking`)
  * Full (gates & U6 only): `python3 tests/run_tests.py`
* **psychopatzCore CodeBuilder & Lua suites** (run from `/home/psychopatz/Zomboid/Workshop/psychopatzCore`):
  * Compiler/reconcile unit tests: `python3 -m unittest`
  * Reconcile check: `python3 tools/semantic_harness/codebuilder/reconcile.py --check`
  * Lua suite: `python3 tests/run_tests.py` (or targeted `lua <test>.lua`)
* **DynamicTrading standalone compatibility suite** (run from `/home/psychopatz/Zomboid/Workshop/DynamicTrading`):
  * `python3 tests/run_tests.py`
* **Kahlua2 Lua lint (`pz-verify`):**
  * `python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/pz-verify/scripts/pz_verify.py --file <file.lua> --kahlua --severity ERROR --no-snippets`
* **Real PZ JVM harness (U6 / gates only):**
  * `/home/psychopatz/Desktop/Projects/pz-runtime-harness/run.sh` (do NOT launch native Project Zomboid GUI/binary unless explicitly authorized).
* **Checkpoint verification:**
  * Run from `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` (or pass absolute `--handoff`):
    `python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/agent-continuity/scripts/checkpoint.py verify --repo /home/psychopatz/Zomboid/Workshop/ProjectHoomans --handoff /home/psychopatz/Zomboid/Workshop/ProjectHoomans/docs/Jobs/UnifiedSchemaDrivenNPCAI/HANDOFF.md`

## 3. CodeBuilder & Generated Artifact Rules

* Never hand-edit generated Lua registries, manifests, indexes, or runtime plans.
* Edit canonical source schemas/packages or compiler code in `psychopatzCore`, then run canonical `CodeBuilder` compile, naming audit, and `reconcile` commands.
* Require clean reconcile (`missing=0`, `drifted=0`, `stale=0`, `retired_present=0`, `ambiguous=0`) and `activeCurrentPsdlIdentityCount = 0`.
* Every new server Lua file under `Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/` must begin with `if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end` and be accounted for in `tests/pnc_mp_server_file_guard_smoke.lua`.

## 4. Evidence Hierarchy (Never Conflate Tiers)

Record exact evidence class for every gate:
`static/compiler check` < `unit test` < `production-Lua harness` < `real PZ JVM (pz-runtime-harness)` < `visible GUI acceptance (Colonists Debug GUI)` < `native SP` < `native MP`.

* Do NOT launch native Project Zomboid unless explicitly authorized by the user.
* Scope-local focused tests run during chunks; full multi-repo + scale suites run at phase gates and U6.

## 5. Strict Git & Commit Safety

* Preserve all unrelated staged, unstaged, and untracked changes.
* Forbidden commands: `git add -A`, `git reset`, `git checkout --`, `git stash`, `git branch` (no new branches unless authorized), `git amend`, `git rebase`, `git push`, PRs, tags, or Workshop publishing.
* Stage only exact phase-owned paths (`git add <file1> <file2> ...` or `agent-phase commit`) and run `git diff --check` before committing.
* **Cross-repo commit order:**
  * When `psychopatzCore` introduces compiler/mechanism contracts consumed by `ProjectHoomans` (U2, U4, U5a): commit `psychopatzCore` first -> `ProjectHoomans` (plus reconciled job docs) last.
  * When verifying/reconciling cross-repo generated artifacts or Core continuity vectors: record exact participant commit vectors in `HANDOFF.md`.
