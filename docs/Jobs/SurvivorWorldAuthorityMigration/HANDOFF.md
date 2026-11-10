---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P5-G"
phase_commit_message: "phase(P5-G): repair shared abstract survivor-world presence"
phase_commit_vector: "project-hoomans=self;psychopatz-core=54937327046783a64c22e463b7bdcfbd5976ada4;dynamic-trading=fee37b9c0bf6cc4015c4e7c2416aa0bd4c527567"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-10T08:38:40.800052Z"
state: "CLEAN_CHECKPOINT"
---




# Handoff

## State

The authority-repair slice and the shared presence-debug slice are implemented
and locally verified. Core is the canonical owner for generated
factions/communities/groups/actors plus the persisted presence-debug gate,
provider selection, debug session rollback, and canonical provider lease.
Project Hoomans and DTHoomans register only physical lifecycle adapters. The
Hoomans startup path reconciles Core actors after PNC registries load, and
Dynamic Trading retains its existing transactional trader handoff.

## Next chunk

Run the user-owned live validation on a fresh save and a restart:

1. enable `PsychopatzCore.SurvivorWorldPresenceOverride` in the central Debug
   Settings UI;
2. use the Core map debug action on a fresh-save actor and verify the NPC
   monitor, map hover, and physical body share its actor ID;
3. release the debug body and verify the original provider lease is restored;
4. verify a generated settlement/group commits once in Core;
5. verify the live `DTAbstract` to `DTHoomans` hotswap leases the existing
   actor and materializes it without a second PNC/Core record.

No native Project Zomboid session was launched by this developer-side phase.
