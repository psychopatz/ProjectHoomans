---
state: "DIRTY_RESUMABLE"
parent_status: "PLAN_READY"
phase: "L0"
chunk: "Clean profiler-OFF baseline and profiler safety"
retrieval_tier: "verify"
handoff_schema: 2
checkpoint_mode: "dirty_snapshot"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
participant_repos: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
observed_project_hoomans_head: "8dfa86e16a16bace054dbb02ff72a56a3b51d706"
observed_psychopatz_core_head: "57f09b7043f071193c0c4fbf397af528ea93e826"
updated_at: "2026-11-20"
---

# Session Handoff

A live new-save audit found that the remaining lag is broader than accepted NPCReplicationScaling portrait work. The most important source-level defects are bulk Core->Hoomans hydration, duplicate/incompatible Core-backed record persistence, synchronous broad persistence commits, and full-snapshot fallback for many mutation events.

The current profiler snapshot is useful for attribution but not a clean normal-play baseline because the `performance` section installed deep wrappers on hot paths. Start L0 by proving profiler-OFF behavior and measuring the same workload without deep wrapping. Do not micro-optimize FollowOwner or stamina from the current timing numbers.

After L0, proceed automatically through lazy promotion/demotion (L1), single-authority deferred persistence (L2), domain-delta replication (L3), then only measured runtime cadence/allocation work (L4), followed by full scale/docs acceptance (L5).

Preserve the Compact Survivor World contract: Core abstract actors must remain compact and provider-neutral until Hoomans physical gameplay actually needs a rich runtime representation. Preserve NPCReplicationScaling P1-P4.
