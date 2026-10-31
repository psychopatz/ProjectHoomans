# Remaining private-boundary review

P7J's lexical supplement found 101 candidate source lines in 15 private namespaces
beyond the previously guarded roots. `P7J_PRIVATE_SCAN_PROOF.json` records exact
paths, provisional owners and limitations. Definition ownership is inferred from
fully qualified initialization sites; candidate counts are not accepted defects.
Compound aliases and alias-only namespace initialization require source fallback.
The event-memory calendar leak discovered separately has been migrated to the
public CurrentWorldDay query, with its existing function and remote age checks.

All 15 candidate namespaces from `P7J_PRIVATE_SCAN_PROOF.json` (plus `PNC.MedicalCareExecutor.Internal`
and `PNC.CombatTactics.Internal`) have been reviewed with MCP caller/dependency/source
evidence, migrated to owner-controlled public contracts or profiler registration hooks,
and guarded in `DOMAIN_CONTRACTS.json` (93 total guarded private roots, `0` remaining
foreign-private candidates).

| Candidate private namespace | Inferred owner | Candidate files | State |
| --- | --- | ---: | --- |
| `PNC.ClientPresenceSync.Internal` | Presence | 2 | Resolved in P7L: exposed `RefreshBodyMap` and `GetClientZombieSoundObservation` on `PNC.ClientPresenceSync`; migrated `PBrainZ_InlineChatTargets` and `NameplateRenderer_ZombieDebug`. |
| `PNC.PathService.Internal` | Pathing | 10 | Resolved in P7L: exposed `IsSquareWalkable`, `OpenDoorForNPC`, `OpenWindowForNPC`, `SmashWindowForNPC`, and `PassageWindowDestination` on `PNC.PathService`; migrated 6 server/world walkability callers and 4 client `ClientNativePathController` passage callers. |
| `PNC.HomeDutyService.Internal` | Production | 2 | Resolved in P7L: exposed `CancelActiveTask` on `PNC.HomeDutyService`; migrated `ColonyManagement_ColonistActions` and `CompanionCommandDefinitions`. |
| `PNC.Network.Internal` | Networking | 9 | Resolved in P7L: exposed `PlayerKey`, `SendToPlayer`, `SendToInterestedNPC`, `SendToNearbyPlayers`, `InstallSendGuard`, and `InstallServerProfilerWrappers` on `PNC.Network`; migrated all 9 foreign callers. |
| `PNC.BaseValidationService.Internal` | Settlement | 1 | Resolved in P7L: exposed `RectangleRegion` on `PNC.BaseValidationService`; migrated `MobileGroupDirector_Ambient_Core`. |
| `PNC.ColonyStorageService.Internal` | Colony | 2 | Resolved in P7L: exposed `GetStorageRevision`, `HasStorageChanged`, `Preflight`, `ReserveOutputCapacity`, `ReleaseOutputCapacity`, `CommitStorage`, `TransferIntoStorage`, `LiveNPCSource`, and 5-arg `RecordActivity` on `PNC.ColonyStorageService`; migrated `FacilityCostService` and `LumberService_Execution_OutputDelivery_Deposit`. |
| `PNC.Conversation.Authority.Internal` | Conversation | 10 | Resolved in P7K: 12 LLM social-reaction service/policy modules moved to Conversation; Networking retains guarded require forwarders and command routing. |
| `PNC.FacilityService.Internal` | Settlement | 1 | Resolved in P7L: exposed `Touch` on `PNC.FacilityService`; migrated `BuildingService_Commands`. |
| `PNC.Treatment.Internal` | Health | 1 | Resolved in P7L: exposed `IsBandageType` on `PNC.Treatment` (and `IsDoctor`, `SameCareGroup`, `CurrentPart` on `PNC.MedicalCareExecutor`); migrated `ServerInventory_MedicalSupply`. |
| `PNC.AnimationScenes.Internal` | Presentation | 3 | Resolved in P7L: exposed `ClearScene` on `PNC.AnimationScenes`; migrated `RoamAmbientLifecycle`, `RoamingSeatService_Lifecycle`, and `FacilityJobsBehavior_Lifecycle_Finish`. |
| `PNC.Combat.Internal` | Combat | 2 | Resolved in P7L: exposed `FinishAttackAction` and `InstallProfilerWrappers` on `PNC.Combat` (plus `BuildZombieThreatCentroid` and `InstallProfilerWrappers` on `PNC.CombatTactics`); migrated `CompanionCommandRegistry_Application`, `SocialEventHooks_CombatAdapter_Awareness`, and `PsychopatzProfiler_Shared_Wrappers`. |
| `PNC.LiveBodyControl.Internal` | Pathing | 1 | Resolved in P7L: exposed `ClearVanillaIntent` on `PNC.LiveBodyControl`; migrated `FacilityJobsBehavior_Lifecycle_SleepWake`. |
| `PNC.BehaviorCompanion.Internal` | Behavior | 2 | Resolved in P7L: exposed `ResetFollowMoveIssue` and `InstallProfilerWrappers` on `PNC.BehaviorCompanion`; migrated `Presence_Materialize` and `PsychopatzProfiler_Shared_Wrappers`. |
| `PNC.Server.Internal` | Composition | 1 | Resolved in P7L: exposed `InstallProfilerWrappers` on `PNC.Server`; migrated `PsychopatzProfiler_Server`. |
| `PNC.EnginePathPlanner.Internal` | Pathing | 1 | Resolved in P7L: exposed `InstallProfilerWrappers` on `PNC.EnginePathPlanner`; migrated `PsychopatzProfiler_Shared_Wrappers`. |

The Identity/Semantics/Social/World group remains open until its remaining public
read/adapter relations are justified and real private coupling is eliminated.
