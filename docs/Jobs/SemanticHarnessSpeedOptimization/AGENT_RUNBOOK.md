# Agent Runbook — SemanticHarnessSpeedOptimization

1. **Workspace & Scope Check:** Inspect Git state in `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, `/home/psychopatz/Zomboid/Workshop/psychopatzCore`, and `/home/psychopatz/Zomboid/Workshop/DynamicTrading` (read-only). Read root `AGENTS.md` in each repo you modify. Preserve all unrelated dirty work (specifically `docs/Jobs/SemanticTestSubsystem/*`). Never create new Git branches or push.
2. **Startup Order:** Read `PROGRESS.md` and `HANDOFF.md` first (verify checkpoint with `checkpoint.py verify`), then read only the active `P#` section of `ROADMAP.md` and `ARCHITECTURE.md`. Use `AUDIT.md` for pre-verified root causes and file targets.
3. **Standard Benchmark & Verification Commands:**
   - **Declarative semantic fixtures (all 39 files / 228 cases):**
     ```bash
     PYTHONPATH=/home/psychopatz/Zomboid/Workshop/psychopatzCore:/home/psychopatz/Zomboid/Workshop/ProjectHoomans \
       python3 -m tools.semantic_harness.testing.cli \
       --provider-manifest /home/psychopatz/Zomboid/Workshop/ProjectHoomans/tools/providers/pnc/provider.json \
       --root /home/psychopatz/Zomboid/Workshop/ProjectHoomans/tools/providers/pnc/tests/fixtures/semantic
     ```
   - **PsychopatzCore full unittest discovery (277 tests):**
     ```bash
     PYTHONPATH=/home/psychopatz/Zomboid/Workshop/psychopatzCore:/home/psychopatz/Zomboid/Workshop/ProjectHoomans \
       python3 -m unittest discover -s /home/psychopatz/Zomboid/Workshop/psychopatzCore/tools/semantic_harness/tests -p 'test_*.py' -q
     ```
   - **PNC full unittest discovery (702 tests):**
     ```bash
     PYTHONPATH=/home/psychopatz/Zomboid/Workshop/psychopatzCore:/home/psychopatz/Zomboid/Workshop/ProjectHoomans \
       python3 -m unittest discover -s /home/psychopatz/Zomboid/Workshop/ProjectHoomans/tools/providers/pnc/tests -p 'test_*.py' -q
     ```
   - **PNC parallel runner:**
     ```bash
     python3 /home/psychopatz/Zomboid/Workshop/ProjectHoomans/tests/run_tests.py --suite python --jobs 4
     ```
   - **Stray worker check:** verify `ps -ef | grep '[w]orker.lua'` shows no leftover test-owned Lua processes before and after runs.
4. **Lua Compatibility Check:** Run `pz-verify` on every modified file under `Contents/mods/` (`PsychopatzJson.lua`, `PsychopatzSemanticRegistry.lua`, `PsychopatzCustomTranslationManager.lua`) and keep the harness copy of `PsychopatzJson.lua` synced with the mod copy.
5. **Phase Commits:** Never use `git add -A`. When a phase gate passes, reconcile `PROGRESS.md` / `HANDOFF.md` / `ROADMAP.md` and run:
   - Participant first (when modified):
     `agent-phase repo-commit --repo /home/psychopatz/Zomboid/Workshop/psychopatzCore --phase P# --message "<summary>" --path <owned-path>...`
   - Primary last:
     `agent-phase commit SemanticHarnessSpeedOptimization --phase P# --message "<summary>" --path <owned-path>...`
6. **Continuation:** Continue automatically from `P1` through `P5` unless blocked by an external dependency or ambiguity requiring user input.
