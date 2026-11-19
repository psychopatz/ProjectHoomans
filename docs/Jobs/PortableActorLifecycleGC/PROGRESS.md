# Progress — Project Hoomans Portable Actor Lifecycle & GC Adoption

**Status:** COMPLETE — H0–H5, H3A, H4-policy, H6-player-lifecycle ACCEPTED (**READY FOR USER LIVE TEST**).
**Parent:** PsychopatzCore Docs/portable_actor_lifecycle_gc/.
**Current phase:** H5 complete — all Project Hoomans Portable Actor Lifecycle & GC phases accepted.
**Participant completion:** 6/6 phases accepted (H0, H1, H2, H3, H4, H5, plus H6-player-lifecycle).

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

## H1 & H2 — Core Lifecycle Bridge & Durable Hoomans GC Roots

- Created `PNC/Core/Persistence/PNC_Persistence_CoreLifecycle.lua` (required by `PNC_Persistence.lua`) bridging `RetireActor` and `HardDeleteRollback` exclusively to Core `DefaultRegistry` with zero duplicate Hoomans tombstone/GC stores, and registering `"ProjectHoomans.DurableRoots"` in Core `GC`.
- Registered only warranted strong roots (`DeathMarkers` for active colony/infected corpses, non-terminal quests, active faction leaders/owners, and living durable bonds) while keeping `UniqueNPCRegistry` dead flags, terminal quests, and dead non-leader `faction.memberIDs` WEAK and compacted in `OnBeforePurge` (preserving `status = "dead"` on unique NPCs).
- Wired `PNC_Health_Death.lua` (calling `QuestService.OnNPCDeath` and `MedicalCareService.OnNPCDeath`, then calling `CoreLifecycle.RetireActor` after `AddDeathMarker`/`RemoveRecord` + post-retirement `faction.memberIDs` scrub), `PNC_API/Lifecycle.lua` (`API.Despawn` rollback `HardDelete` vs `retire = true` vs skipping `dtProviderProjection`), and `PNC_NPCKnowledgeService_PlayerSnapshots.lua` (historical Core tombstone/`DeathMarker`/note degradation).
- Verified 18/18 tests PASS (`core_actor_lifecycle_gc`, `factions_foundation`, `quest`, `medical_care`, `core_social`, `death`, `reanimat`) and Kahlua lint 0 errors across all 7 files.

## H6-player-lifecycle — Player Character Death & Core Identity Retirement

- Fixed the 3-return destructuring bug in `PNC_PlayerCharacterLifecycle_Callbacks.lua` (`local changed, result, deadUUID = H.Service().MarkDead(...)`) so `ReleaseCharacterOwnership` receives the actual dead character UUID instead of `"marked_dead"`.
- Wired `PsychopatzCore.PlayerIdentity.RetirePlayerCharacter` inside `PNC_PlayerCharacterService_Lifecycle.lua` (`PlayerCharacters.MarkDead`) with `authority = "server"`, `reason = "player_death"`, `allowAlreadyRetired = true`, and `adoptUnissued = true`.
- Verified `python3 tests/run_tests.py player_character` PASS (`3/3` in `0.17s`), Core `psychopatz_player_character_lifecycle_mp_smoke.lua` PASS, and `pz_verify.py --kahlua --severity ERROR` (`0` errors) across both edited files.

## H3 & H4 — Social History Migration & Lifecycle Semantic Projections

- Extended `PNC_Persistence_CoreSocial.lua` (`ToCoreSocial`) to forward historical edge metadata (`historical`, `historicalPin`, `historicalLabel`, `degradedLabel`, `targetLifecycleStatus`, `targetLifecycleRevision`) while strictly persisting actor memories to `memoryBank` with zero `rel.memories`.
- Enriched `PNC_RelationshipPresentation.lua` (`BuildForConversation`) with O(1) read-only Core `ProjectIdentity` lookups exposing `lifecycleStatus`, `lifecycleRevision`, `targetLifecycleStatus`, `targetLifecycleRevision`, `historical`, and `degradedLabel` with zero GC trigger on open.
- Created `tests/pnc_lifecycle_semantic_projection_smoke.lua` and verified `python3 tests/run_tests.py lifecycle_semantic_projection core_actor_lifecycle_gc core_social portable_social relationship_graph npc_knowledge_service` (`PASS 6/6`) plus Kahlua lint (`0` errors).

## H5 — Scale, GC Soak & Final Acceptance

- Created `tests/pnc_lifecycle_gc_scale_soak_smoke.lua` retiring 200 Hoomans NPCs across colony `DeathMarkers` + reanimation release, active quests, surviving durable bonds, dead unique NPCs (`WEAK`), and 120 ordinary unowned deaths across multiple budgeted Core GC slices/generations (`budget = 20`) plus Kahlua `_G.next = nil` Core `Save()`/`Load()` roundtrip.
- Verified `27/27 PASS` (`0.59s`) across `lifecycle_gc_scale_soak`, `core_actor_lifecycle_gc`, `lifecycle_semantic_projection`, `player_character`, `factions_foundation`, `quest`, `medical_care`, `core_social`, `portable_social`, `social_policy`, `death`, `reanimat`, and `npc_knowledge`, preserving dead `UniqueNPCRegistry` flags (`status = "dead"`) after tombstone purge without pinning tombstones.
- Status: **READY FOR USER LIVE TEST**.

## Next Chunk

Complete — READY FOR USER LIVE TEST (no pending developer phases).
