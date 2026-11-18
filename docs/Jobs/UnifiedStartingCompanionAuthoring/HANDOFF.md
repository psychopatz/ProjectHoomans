---
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
updated_at: "2026-11-18T19:38:16.287927Z"
state: "USER_ACCEPTANCE"
parent_status: "IN_PROGRESS"
phase: "P5R13"
chunk: "P6 preset portraits, body map and explicit weapon/combat retest"
retrieval_tier: "verify"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
checkpoint_mode: "committed_handoff"
phase_commit: "self"
phase_commit_phase: "P5R13"
phase_commit_message: "phase(P5R13): add preset portraits, native body navigation and explicit weapon selection"
phase_commit_vector: "project-hoomans=self;psychopatz-core=32b85a62b445a73ebecb9890e960d6e8be8778d1;dynamic-trading=aecc3250068202cdf1701b2bd49e8892abfba87c"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=2b0f59e013dbf1004b515ed4402b5ef03afbd68002b6d7171735fb482a57ec0e"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
---


# Session Handoff

P5R13 implements saved-preset side portraits for both hosts, lazy/cached roster
member cycling and current-player inheritance without applying data. Empty/error
selections hide stale portraits. Loadout now navigates via native silhouette
assets/hit bounds with equipped-region green, box-icon Bags/Inventory shortcuts,
Weapons and unknown-mod-slot access. No live health object is required.

Exact primary/off-hand weapon selection uses vanilla/mod ItemType.WEAPON script
metadata, canonical item payloads and two-hand validation. Generated mode buttons
are debug-only. A generation defect is also fixed: explicit firearm + random
weapons suppressed must produce ranged combat mode, not the generated melee
fallback. Existing pool behavior, mixed firearms and canonical foreign inventory
policy are preserved; no schema bump or duplicate authority.

`TEST_VERIFIED`: 71/71 focused, full 1062/1066; same four known scene-route,
context/population/translation failures. New map/projection/color and preset
resolution/nonmutation/cache tests, plus extended browser/host/geometry/mod
weapon/two-hand/actual-generation tests pass. `STATIC_ONLY`: twenty owned Lua
syntax, twelve production Kahlua, EN/TL parity and owned whitespace checks pass.
Eleven new/three updated Character keys. Coverage checked 34 Hoomans, one Core,
four current Java and five native Lua paths; old graph/new/unindexed source read
explicitly. No Core edits or new bitmap assets. Native rendering/input/audio/
combat remains UNVERIFIED; no native game launch/control or publication.

Next: user-owned P5R13 fresh-session matrix in LOADOUT_AUDIO_CRUD_RETEST.md, then
remaining save/backpack/audio/skin/library/SP/MP gates. Preserve concurrent
semantic CodeBuilder source/generated work; none belongs to this phase. Commit
only exact owned paths, then verify the participant/residual checkpoint vector.
