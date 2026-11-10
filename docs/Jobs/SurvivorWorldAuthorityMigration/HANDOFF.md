---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P5-E"
phase_commit_message: "phase(P5-E): verify pre-hydrated provider handoff"
phase_commit_vector: "project-hoomans=self;psychopatz-core=a68010b02bf3dbab76368b62b0bf58ab8b4440fe;dynamic-trading=7e69404351e08dabf298ba38d3b8dff02e6c09ea"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "d1da19d15426956852ddf4e0d9517f028797b541"
updated_at: "2026-11-10T06:34:14.286713Z"
state: "CLEAN_CHECKPOINT"
---


# Handoff

## State

The first authority-repair slice is implemented and locally verified. Core is
the canonical owner for new server bootstrap and generated community/group
records. Project Hoomans hydrates Core-affiliated actors into PNC before its
world view is consumed. Dynamic Trading now has regression coverage proving a
pre-hydrated Hoomans record survives the `DTAbstract` to `DTHoomans` handoff.

## Next chunk

Run the user-owned live validation on a fresh save and a restart:

1. verify Core bootstrap actors appear in the Hoomans NPC monitor;
2. verify map hover identity/knowledge resolves through the same actor ID;
3. verify a generated settlement/group commits once in Core;
4. verify the live `DTAbstract` to `DTHoomans` hotswap leases the existing
   actor and materializes it without a second PNC/Core record.

No native Project Zomboid session was launched by this developer-side phase.
