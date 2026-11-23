---
handoff_schema: "2"
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
phase_commit_phase: "H10R8"
phase_commit_message: "phase(H10R8): verify injury repairs against native-regression fixtures and scale"
state: "USER_ACCEPTANCE"
parent_status: "IN_PROGRESS"
phase: "H11"
chunk: "Witness observation gating and non-colonist visible-condition awareness"
retrieval_tier: "verify"
phase_commit_vector: "psychopatz-core=21499cfb6412414a46bda8a4058429defe206797;project-hoomans=self;dynamic-trading=62757d0b7fc1c114873735387827ccad9d828077"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=7fc480e2f5c5dfc9be5940c58b6c60e4969cbbef041db8fcdd8ec2fb013d87a8;dynamic-trading=f8a3016d89344add854593d73e4170362efc8de00531cffdb129f3b976936188"
residual_worktree_fingerprint: "7fc480e2f5c5dfc9be5940c58b6c60e4969cbbef041db8fcdd8ec2fb013d87a8"
codebase_memory_indexed_commit: "0e35ae37deb6e385a806136bfa1edbca9acfe8e6"
updated_at: "2026-11-23T02:18:09Z"
---

# Session Handoff

H10R1–H10R8 developer repairs are locally committed on `main`. Injury prompts work through both active conversation leases and server-admitted ambient Beats. The server revalidates the exact selected wound, line of sight, reachability, and item before executing aid. Projection rebuilds reuse authoritative summaries after mutations that already recalculated them. EN/TL composed calls use the selected body part.

The focused injury gates, 200-NPC and event-heavy workloads, repository guards, and CodeBuilder check passed. The 64-case EN/TL pairwise Sweep produced 64 clean rows. The final broad Lua run passed 1,103 of 1,109. Its six failures also reproduced before H10R3. Two general wellbeing wording cases and two full-tree Kahlua findings also reproduce at baseline. See `AUDIT.md` for scope and timings.

H11 is user-owned native SP/MP acceptance. Recheck the Character Health random-wound command and real combat at the same severity, selected-wound wording in EN/TL, witness silence and reactivation, neutral survivor observation, and aid against real inventory on host and remote clients. Confirm ordinary barks create no durable dialogue memory and completed aid survives save/reload.
