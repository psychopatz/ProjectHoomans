# Progress — Project Hoomans Portable Actor Lifecycle & GC Adoption

**Status:** IN_PROGRESS (H0 + H3A Core `memoryBank` parity implemented — awaiting Core L1-L4/H1-H2 completion).
**Parent:** PsychopatzCore Docs/portable_actor_lifecycle_gc/.
**Current phase:** H0 complete + H3A Core `memoryBank` persistence parity updated (`PNC_Persistence_CoreSocial.lua`); next H1 after Core L4.
**Participant completion:** 1/6 phases accepted (H3A persistence compatibility landed early with Core L3).

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

## H3A — Core `memoryBank` Persistence Compatibility

- Updated `PNC_Persistence_CoreSocial.lua` (`HasGenericSocialPayload`, `ToCoreSocial`, `FromCoreSocial`, `SyncToCore`) to store and synchronize Core memories strictly in actor-level `memoryBank` (`Social.SCHEMA_VERSION = 3`, `rel.memories = nil`) while preserving Hoomans runtime view projection (`memories = targetMemories`) without writing `.memories` back to Core ModData.
- Updated `tests/pnc_npc_foundation_social_adapter_smoke.lua` and `tests/pnc_portable_social_convergence_smoke.lua` assertions on raw Core social payloads to inspect `CoreSocial.GetMemoriesForTarget` and verify `rel.memories == nil`.

## H4-policy — Social Policy Reference Strength Metadata

- Annotated `tools/providers/pnc/codebuilder/sources/social_policy/events/combat_and_care.json` and `dialogue_and_emotes.json` with explicit `references` (`STRONG`/`WEAK`/`LABEL_ONLY`, role caps, `degradeOnPurge`, `anchorMax = 16` on `friendship_established`).
- Regenerated `PNC/SocialPolicy/Events/CombatAndCare.lua`, `DialogueAndEmotes.lua`, and `Registry.lua` via Core CodeBuilder `reconcile.py --apply` (`clean: true`; Kahlua lint 0 errors; `social_policy` & `core_social` tests PASS).

## Next Chunk

Wait for Core L1-L4 acceptance, then implement **H1** (bridge `Health.Kill` / `retireDeadRecord` to Core `Retire` after consequences and `API.Despawn` rollback to Core `HardDelete`, preserving consequence ordering and `DeathMarkers`).
