# Modular Work Foundation & Zone-Based Farming Agent Runbook

## 1. Workspace & Source Roots

- Primary Repository: `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`
- Active Mod Root: `Contents/mods/ProjectHoomans/42.20/media/lua/`
- Sibling Core Repository: `/home/psychopatz/Zomboid/Workshop/psychopatzCore` (`Contents/mods/PsychopatzCore/common/media/lua/` and `42.20/media/lua/`)

## 2. Focused Validation Commands

Run focused smoke tests from `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`:

- **Phase F1 (WorkDefinitions & Tool Logistics):**
  `python3 tests/run_tests.py tests/pnc_job_requirements_smoke.lua tests/pnc_work_item_service_smoke.lua tests/pnc_work_item_logistics_smoke.lua tests/pnc_work_policy_smoke.lua tests/pnc_work_service_presence_boundary_smoke.lua`
- **Phase F2 (Shared Output & Toil Runner):**
  `python3 tests/run_tests.py tests/pnc_production_foundation_smoke.lua tests/pnc_production_lifecycle_smoke.lua tests/pnc_work_behavior_progress_smoke.lua`
- **Phase F3 (Lumber, Fishing, CorpseHaul Unification):**
  `python3 tests/run_tests.py tests/pnc_lumber_service_smoke.lua tests/pnc_lumber_work_adapter_smoke.lua tests/pnc_fishing_service_smoke.lua tests/pnc_fishing_executor_smoke.lua tests/pnc_fishing_live_pipeline_smoke.lua tests/pnc_corpse_haul_work_pipeline_smoke.lua`
- **Phase F4 (Zone-Based Farming):**
  `python3 tests/run_tests.py tests/pnc_farming_mechanics_smoke.lua tests/pnc_farming_provider_smoke.lua tests/pnc_pz_farming_adapter_presence_boundary_smoke.lua`

## 3. Protected Worktree Rules

- Preserve all unrelated dirty files in `Contents/mods/ProjectHoomans/*/PNC/Conversation/`, `ConvoEngine/`, `Semantics/`, `tools/providers/pnc/`, and `docs/Jobs/UnifiedSemanticDialogueAuthority/`.
- Never run `git reset --hard`, `git checkout -- .`, or blind `git stash`.
- Commit only phase-owned files when creating local phase checkpoints. Never push or publish to Workshop without explicit user authorization.
