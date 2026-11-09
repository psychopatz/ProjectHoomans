# Restart husk safety — current progress

**Status:** COMPLETE. Native 3-cycle restart matrix and map performance acceptance verified on real Steam Project Zomboid client. Player health 100%, zero attacks, zero duplicate persisted_shell_repaired spam, and map performance smooth.

**Evidence sources:** `AUDIT_AND_FIX_PLAN.md`, `MAP_PERFORMANCE_AUDIT.md`, and native test summary `/tmp/pzh-husk-safety/restart_husk_safety_summary.json`.

## Accepted native verification state

- Completed 3-cycle native restart matrix against real save `2026-11-09_16-25-07` on Steam PZ (build 42.22.2):
  - **Cycle 1 (Cold Start)**: Player health 100.0, `is_attacked=False`, companion shells alive and peaceful, controlled map open/hover/close executed smoothly in 12.64s. `persisted_shell_repaired=0`, `human_safety_repaired=0`. Screenshot: `cycle_1_ingame.png`.
  - **Cycle 2 (Restart 1)**: Player health 100.0, `is_attacked=False`, companion shells peaceful, `persisted_shell_repaired=0`. Screenshot: `cycle_2_ingame.png`.
  - **Cycle 3 (Restart 2)**: Player health 100.0, `is_attacked=False`, companion shells peaceful, `persisted_shell_repaired=0`. Screenshot: `cycle_3_ingame.png`.
- Controlled map open -> hover (960, 540) -> map close test completed smoothly in 12.64s without stalls or frame freezes.
- Verified zero husk attacks on the player and zero repeated `persisted_shell_repaired` churn across all restart cycles.
- All developer-side repairs (carrier identity normalization, 2048 carrier capacity, immediate combat suppression, OnZombieUpdate carrier check, local presentation body lease validation) and user-owned native acceptance criteria are fully satisfied.
