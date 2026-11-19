# Progress — Project Hoomans Portable Actor Lifecycle & GC Adoption

**Status:** IN_PROGRESS (H0 ACCEPTED — awaiting Core L1-L4 contracts).
**Parent:** PsychopatzCore Docs/portable_actor_lifecycle_gc/.
**Current phase:** H0 complete; next H1 (pending Core L1-L4).
**Participant completion:** 1/6 phases accepted.

## Verified H0 Audit Facts (Checkpoint `67510b0db`)

- `PNC.Health.Kill` (`PNC_Health_Death.lua:183-218`) executes `releaseOwnedWork` -> `markDeadState` -> `CorpseAwareness.ObserveDeath` -> `UniqueNPCRegistry.MarkDead` -> `Factions/Communities.OnNPCDeath` -> `createCorpse` -> `retireDeadRecord` (`Registry.RemoveRecord`) -> `WorldKnowledge.PublishDeath`.
- **Critical Core leak:** neither `retireDeadRecord` nor `PNC.API.Despawn` ever retires, removes, or releases the canonical Core actor in `PsychopatzCore.Actors.DefaultRegistry`; `CoreProvider.Release` has 0 production callers.
- **Subsystem reality check:** `PNC_DeathMarkers` are lightweight colony/infected corpse markers (not a general cemetery); memorials/cemeteries, prisoners/captives, dedicated squads, separate rumor ModData, and persisted bed/facility ownership do NOT exist (`PNC_FacilityReservations_Core` and `PNC_FactionTollService_Core` are transient only).
- **Verified Hoomans gaps for H1-H4:**
  - `PNC_FactionService_Lifecycle.lua:201-231` clears `leaderNPCID` on NPC death but leaves dead non-leader IDs in `faction.memberIDs` / Core `memberActorIDs` until repair/reload.
  - `PNC_QuestService`, `PNC_MedicalCareService`, `PNC_FishingService`, and `PNC_LumberService` lack death-cleanup hooks for dead NPC givers/patients/workers.
  - `PNC_PlayerCharacterLifecycle_Callbacks.lua:28-30` captures only 2 of 3 returns from `MarkDead` (passes `"marked_dead"` instead of `uuid` to `ReleaseCharacterOwnership`).
  - `PNC_NPCKnowledgeService_PlayerSnapshots.lua:69` fails with `"npc_not_found"` after `RemoveRecord`.
  - ~24 Hoomans Lua modules assume per-relationship `memories` arrays (to be updated in H3 after Core L3).
- Unrelated dirty NPCAuthoring / StartingCompanions / Equipment worktree files were verified and preserved untouched.

## Next Chunk

Wait for Core L1-L4 acceptance, then implement **H1** (bridge `Health.Kill` / `retireDeadRecord` to Core `Retire` after consequences and `API.Despawn` rollback to Core `HardDelete`, preserving consequence ordering and `DeathMarkers`).
