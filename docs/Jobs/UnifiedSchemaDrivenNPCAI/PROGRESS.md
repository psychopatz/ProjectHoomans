# Progress: UnifiedSchemaDrivenNPCAI

Parent goal: IN PROGRESS
Current phase: Phase U1 — RimWorld Work Foundation Unification

Accepted:

* Phase U0 — Live Workspace Audit, Prerequisite Verification & Manifest Freeze (`CODE_VERIFIED` across `ProjectHoomans`, `psychopatzCore`, `DynamicTrading`, and `pz-java-baseline`).
* Canonical job documentation reconciled against verified live HEADs, Build 42 Java engine contracts, and frozen cross-repo Phase U1–U6 ownership manifest.

Current evidence:

* `CODE_VERIFIED`: Live Git HEADs and clean worktrees verified on `main`:
  * `ProjectHoomans` @ `cbf62c1aedbb57cf486503ae707c8ca6a457e2a6` (pre-U0-closure baseline)
  * `psychopatzCore` @ `e7149129f10da87c28b56d6359aac3ff461eba09`
  * `DynamicTrading` @ `2b66a9583fcbe3d9e915b6c16ab9d6851d053eab`
* `CODE_VERIFIED`: Hard prerequisites `LightweightNPCRuntime` (L0–L6), `Portable Social State` (P0–P12/H0–H8/DT0–DT6), `PortableActorLifecycleGC` (L0–L9), and `ModularWorkFoundationAndFarming` (F1–F5) are developer-complete; `ConvoEngine` S13D–S13F (`psychopatzCore`) is sequenced as gate U5a before Phase U5 Dialogue Director work.
* `CODE_VERIFIED`: Build 42 Java constraints (`IsoGameCharacter.setVariable` server no-op for `IsoZombie`, `faceLocationF` zero-delta warning, `CanSee` no-FOV check, `WorldSoundManager` server `chunk.soundList` gap) verified against `pz-java-baseline`.

Known gap:

* Phase U1 unification targets: `PNC.Tasking.Claims` does not yet exist; `WorkService.RegisterReconciler` is unwired for `FARMING`/`FISHING`/`LUMBER`/`CORPSE_HAUL`; `CorpseHaulService` still registers a standalone `Events.OnTick` loop; `LumberService.Pump` duplicates reconcile polling; legacy `"farming"` Tasking provider still registers at startup; `WorkToilRunner.AbortOrder` is not yet implemented.

Next Chunk: Chunk U1A — Implement `PNC.Tasking.Claims`, wire automatic release into `PNC_TaskLeaseService_Release` and `PNC_Tasking_Assignment`, bridge Work/WorkZone/Lumber/CorpseHaul claims, add `WorkToilRunner.AbortOrder`, and unify all 4 chores onto dirty-state `WorkService.RegisterReconciler`.

Immediate acceptance:

* `PNC.Tasking.Claims` (`Acquire`, `Renew`, `Release`, `ReleaseByLease`, `ReleaseByOwner`, `PruneExpired`, `GetDiagnostics`) verified under TaskLease release and rollback.
* All 4 chore reconcilers (`FARMING`, `FISHING`, `LUMBER`, `CORPSE_HAUL`) registered on `WorkService` with zero standalone production `Events.OnTick` chore polling loops and zero `isFarmer` gates.
* Focused `u1_work_foundation`, `mp_server_file_guard`, `work`, `farming`, `lumber`, `fishing`, `corpse`, and `tasking` tests + Kahlua lint pass.
