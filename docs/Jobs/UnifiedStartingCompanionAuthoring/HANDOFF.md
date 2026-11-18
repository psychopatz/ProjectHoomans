---
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
updated_at: "2026-11-18T20:27:04.844538Z"
state: "USER_ACCEPTANCE"
parent_status: "IN_PROGRESS"
phase: "P5R14"
chunk: "P6 hoodie, tooltip, double-click and regional-camera retest"
retrieval_tier: "verify"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
checkpoint_mode: "committed_handoff"
phase_commit: "self"
phase_commit_phase: "P5R14"
phase_commit_message: "phase(P5R14): repair generated clothing and add regional hover/picker previews"
phase_commit_vector: "project-hoomans=self;psychopatz-core=94539bcd22159667b6bb4eba53b38014da2ab47a;dynamic-trading=aecc3250068202cdf1701b2bd49e8892abfba87c"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;psychopatz-core=eab3dd2b57545666496f28842f5719a0f65d9d4b1f2ecb8b28f8fb0149501e95;dynamic-trading=1bec8aa0d890bd2531d304c0ad3aa1694ad5f15cbd96f616d556721384728748"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
---


# Session Handoff

P5R14 repairs the reported hoodie mismatch: the native game makes SweaterHat
exclusive with Hat; General's beanie/HoodUp variant is now HoodDown. Generated
wardrobe preparation resolves native locations/conflicts before creating items,
so native rendering and listed worn equipment agree. Canonical provider-owned
inventory stays on its prior path.

Body hover shows native part names and equipped-group item icons/names in a
bounded, owner-cleaned tooltip. Picker double-click shares normal validation and
one-shot confirmation; actions are centered. Read-only item portraits retain the
same captured native visuals on commit, with bounded caches and safe Cancel.

Core now owns named camera regions, per-region preferences, reset/restore and a
camera-only applyCameraState API. Target/spec/clothing/cache and animation
variables stay unchanged. Both main and chooser portraits use it; Appearance
keeps its separate headgear-free projection. See Core Docs/UI/PortraitViewRegions.md.

TEST_VERIFIED: 74/74 focused; full 1064/1068, same four known scene-route/context/
population/translation failures; two Core portrait checks pass. The brittle
canonical-slot source-string check became a real native projection regression.
STATIC_ONLY: 22 owned Lua syntax, 14 production Kahlua, two EN/TL Character keys,
JSON/key/placeholder parity and owned whitespace pass. Coverage: 28 Hoomans,
seven Core, eight current Java, six native paths; changed/new/unindexed source
read directly. Native rendering/input/camera offsets remain UNVERIFIED.

Next: user-owned fresh-session P5R14 matrix in LOADOUT_AUDIO_CRUD_RETEST.md, then
remaining weapon/audio/save/library/SP/MP gates. No native control, push or
publication. Preserve concurrent semantic/FoundationRegistry work. Commit exact
Core paths first, then primary paths/HANDOFF and verify checkpoint/residuals.
