# Handoff — Mod Removal & Save Compatibility

**Checkpoint type:** PLAN_BASELINE.
**Repo:** ~/Zomboid/Workshop/ProjectHoomans, main at c156ed21e after concurrent firearm-effects commit; initial source inspection was at 8575f20e24d716efc52142376c50a2bd22d706f0; re-check HEAD.
**Save reference:** ~/Zomboid/Saves/Apocalypse/2026-11-20_07-12-33; read-only inspection only.

## Observations

- UI and mods.txt show no configured mods in selected save.
- global_mod_data.bin still contains PNC/ProjectHoomans/Psychopatz byte markers; presence alone is not a failure.
- players.db localPlayers has two living same-name entries; active one not known.
- The reported weight maximum 8 has not been decoded or reproduced.
- Scoped Lua scans did not find explicit direct player setMaxWeightBase/Delta setters in ProjectHoomans, psychopatzCore or DynamicTrading; search is not exhaustive.
- Other contemporary saves have several mods enabled but are different player histories.
- Nine unrelated firearm-effect files/tests were staged at initial inspection, then committed by another agent as c156ed21e during goal preparation. This goal did not modify them; preserve future concurrent changes.

## Resume

Read PROGRESS.md then run P0 on reference only via read-only inspection and disposable-copy controls. Work as psychopatz. Establish active player record and compare actual/visual carry, strength/traits, debug flags and matched vanilla baseline, then proceed through full ROADMAP. Never alter original save.

## Completion boundary

The full developer-side goal requires actual root-cause evidence, minimum correct remedy where owned, automated regressions and an explicit remaining native user-acceptance check. No root-cause claim is accepted solely from surviving ModData or a hypothesis about debug mode.
