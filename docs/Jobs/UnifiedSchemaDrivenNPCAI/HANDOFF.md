---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "U2"
phase_commit_message: "phase(U2): add compiled AutonomyAd, ReactionPolicy, and WorkScenario packages and close U2"
phase_commit_vector: "psychopatz-core=010a6260cabe39f210095ba3d1bfb710d35b98cf;project-hoomans=self;dynamic-trading=2b66a9583fcbe3d9e915b6c16ab9d6851d053eab"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
updated_at: "2026-11-21T20:20:29.120871Z"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "Phase U3"
chunk: "U3A"
retrieval_tier: "verify"
---



# Session Handoff: UnifiedSchemaDrivenNPCAI

## What became true

- Phase U2 (`psychopatzCore` @ `010a6260cabe39f210095ba3d1bfb710d35b98cf` + `ProjectHoomans` starter packages & generated artifacts) implemented and verified:
  - Extended `CodeBuilder` with `ai_ir_core.py`, `autonomy_ad_compiler.py`, `reaction_policy_compiler.py`, `work_scenario_compiler.py`, and two-pass `ai_cross_ir_linker.py` supporting `abstract`/`parent` flattening, JSON Patch overlays, deterministic SHA-256 outputs, and static Build 42 `AnimSets` XML + `PNC.NPCVoice.Catalog.Events` key validation.
  - Extended `SocialPolicy` compiler and `PsychopatzSocial.lua`/`PsychopatzSocialRetention.lua` runtime with `stackLimit`, `stackedEffectMultiplier`, and `nullifyingTraits`.
  - Fixed `reconcile.py` header verification, registered new surfaces in `generation_recipe.json`/`generation_ownership.py`/`targets/pz_packages.json`, authored `ProjectHoomans` starter packages (`autonomy_ad`, `reaction_policy`, `work_scenario`), and generated 6 clean Lua outputs under `Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/`.
- Phase U1 (`ProjectHoomans` @ `a598e8b9c1e2fe86b505e543b73cd63f52dfd2a5`) implemented and verified (`PNC.Tasking.Claims`, `WorkToilRunner.AbortOrder`, `WorkService.RegisterOperation`, dirty-state reconcilers).

## Remaining

- Execute Phase U3 (`Sims Band-Gated Autonomy & Co-Presence Unification`) in `ProjectHoomans`.
- Execute Phase U4 (`GTA V / RDR2 Behavioral Reactivity & Secondary Channel`), Phase U5 (`S13D–S13F Gate + Dialogue Director & RDR2 Street Interaction`), and Phase U6 (`Scale Proof & Final Acceptance`).

## Resume

Exact next action:

1. Implement `server/PNC/Tasking/Autonomy/{PNC_AutonomyScorer,PNC_CoPresenceService,PNC_AutonomyTaskProvider}.lua` driven by compiled `PNC.AutonomyAd.Registry`.
2. Refactor `PNC_AmbientFacilityService` (`LivingRoomService`), `PNC_RoamingSeatService`, `PNC_RoamAmbientService`, and behavior callers to route through `PNC.Tasking`, remove dead `Registry.ForEach` polling, and wire `HydrateOnPromotion`.
3. Expose `taskBrain`, claims, autonomy scoring, and Co-Presence diagnostics on Colonists Debug GUI (`"debug"` tab) with zero Debug-OFF overhead; run Phase U3 verification, update docs, commit locally, and hand back for Phase U4 planning.

## Evidence

- `TEST_VERIFIED` (U2): `psychopatzCore` `python3 -m unittest` 30/30 OK (including `test_live_three_repository_integrity_audit_and_two_pass_determinism`); Core Lua social tests 5/5 PASS; `reconcile.py --check` clean (`missing=0, drifted=0, stale=0, retired_present=0, ambiguous=0`); `convo_engine_naming_audit.py --summary` (`ok=true, activeCurrentPsdlIdentityCount=0, violatingFiles={}`); `DynamicTrading` 92/92 PASS; `PASS generated_ai_ir_registries_lua_load`.
- `TEST_VERIFIED` (U1): `u1_work_foundation` (1/1), `mp_server_file_guard` (1/1, 1060), `work` (33/33), `farming` (5/5), `lumber` (8/8), `fishing` (10/10), `corpse` (15/15), `tasking` (8/8) — 81/81 PASS.
- `STATIC_ONLY`: `pz-verify --kahlua --severity ERROR` 0 errors on all U1 files, `PsychopatzSocial*.lua`, and all 6 U2 generated `ProjectHoomans` Lua files.

## Expensive discoveries worth preserving

- `psychopatzCore` semantic harness Python tests run with `python3 -m unittest` (`pytest` is not installed in the workspace environment), and `convo_engine_naming_audit.py` requires `--core-repository`, `--hoomans-repository`, `--dynamic-trading-repository`, and `--summary`.
- `reconcile.py` previously accepted only `"do not edit by hand."` and rejected `social_policy_compiler.py`'s `"... DO NOT EDIT."`; fixed in Core commit `010a6260cabe39f210095ba3d1bfb710d35b98cf`.
- `tests/pnc_mp_server_file_guard_smoke.lua` counts exact `.lua` files under `server/PNC/` (currently `1060`; every new server file requires the `RuntimeRole.AllowsServerCode()` guard and matching test count update).

## Blockers / open decisions

- None for U3–U4 (`ConvoEngine` S13D–S13F remains gated immediately before U5).

## Acceptance

- Phase U2 local commit + `checkpoint.py verify` green, then implement Phase U3.
