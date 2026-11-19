---
parent_status: "IN_PROGRESS"
phase: "P3"
chunk: "Exact representation evaluation"
retrieval_tier: "verify"
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "P2"
phase_commit_message: "phase(P2): Negotiate lean NPC replication and hydrate portraits on demand"
phase_commit_vector: "project-hoomans=self;psychopatz-core=cd97c3c29f431aacba5db66aca71fb6e9c05fe09"
phase_residual_vector: "project-hoomans=9b9c918f24400548ac11539c06c97bf3c9f444a4c1a1e1997c76591ffb05c166;psychopatz-core=27ef68e132727310ad9a41bd4b650b3f995f6d6abf38771c7ed11a939e6d4480"
residual_worktree_fingerprint: "9b9c918f24400548ac11539c06c97bf3c9f444a4c1a1e1997c76591ffb05c166"
codebase_memory_indexed_commit: "6635ccc81e21f02383feb598dc3b92c91b093d6a"
updated_at: "2026-11-19T16:05:50.215918Z"
state: "CLEAN_CHECKPOINT"
---


# Session Handoff

Negotiated Project Hoomans clients receive lean roster and nearby portrait references. Authenticated roster hydration resolves at demand. Legacy and hosted-local clients keep resolved portraits. Targeted tests cover mixed recipients, bounded cache, mutation equality, ordered application, stale replies and reconnect. Core map hover reacts to a changed descriptor revision. The separate canonical Core actor map provider retains its existing payload. See [P2 evidence](P2_HYDRATION.md).

Begin P3 at the existing portrait response. Source review found that native SurvivorFactory contributes resolved identity inputs outside seed control. Authored and runtime seeds also differ for some unique NPCs. Evaluate reversible candidates from lossless resolved values, and require evidence of actual generator/catalog equivalence before selecting seed or shared definitions. Native multiplayer remains user-owned.
