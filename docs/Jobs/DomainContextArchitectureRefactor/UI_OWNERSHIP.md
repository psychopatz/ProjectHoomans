# UI ownership review

UI owns widgets, formatting, selection, layout preferences and unsent edits.
Domain applications own authoritative commands; repositories own definition/save
meaning. A local authoring repository is distinct from an in-world registry.

## Established authoring seams

| Operation | Public domain entry (runtime-relative) | Owner/state |
| --- | --- | --- |
| Opera definition save/load/list | `client/PNC/PuppetOpera/PNC_PuppetOperaStorage.lua` | PuppetOpera; normalized definition envelope, generic DefinitionDatabase file/index mechanism. Does not start playback. |
| NPC draft validation, sparse export, preview and view data | `client/PNC/Identity/PNC_UniqueNPCDraft.lua` | Identity authoring; existing `PNC.UniqueNPCEditorModel` table. Five responsibility-specific providers remain private. |
| NPC authored definition save/load/list | `client/PNC/Identity/PNC_UniqueNPCDefinitionStore.lua` | Identity authoring; existing `PNC.UniqueNPCEditorStorage` table. Does not register or spawn an NPC. |

Windows and the local inventory draft endpoint consume these public contracts.
NPC preview records keep `id=nil` and `_editorDraft=true`; preview identity seeds
never enter authored definitions. Authored traits, explicit appearance, generated
fallbacks, sparse inventory export and validation order are unchanged. Existing
tests retain name/trait conflict, preview stability and inventory-copy checks.

The stable NPC editor-model require path forwards to the same table. Old private
model-provider and definition-storage paths were removed after maintained caller
migration. Opera's old private UI storage path was also removed. There is no
second draft, repository, registry or playback state.

## Persistence candidates classified

Paths below are relative to `client/PNC/UI/`.

| Candidate | Reviewed meaning | Disposition |
| --- | --- | --- |
| `Shared/PNC_ColonyUIComponents.lua:41–72` | `CreateCatalogColumnState` saves stable column keys and normalized positions through Core Settings. | Legitimate per-user presentation preferences. Analyzer `UI_PERSISTENCE_MIX` at line 62 is not authoritative gameplay persistence; retain diagnostic and this justification. |
| `Research/PNC_ResearchController_View.lua:12–39` | Collapsed catalog-group IDs in `ProjectHoomans_ResearchUI.txt`. | UI preference store, not research progress/schema. |
| `Workshop/PNC_WorkshopGroupState.lua:1–47` | Escaped collapsed-group keys in Core Settings. | UI preference serialization. |
| `Base/PNC_BaseBuildingCatalog_Recipes.lua:84–105` | Base-game recipe-favorite key on the local player, using native favorite-key construction. | Presentation preference; preserves native ModData transmission. No recipe unlock/queue ownership. |
| `Provision/PNC_ProvisionSettingsModel.lua:61–248` | `Load` copies normalized snapshot rules into an unsent editing model; `Set` changes that copy; `BuildSubmission` validates rules via domain-owned `PNC.ProvisionPolicy.ValidateRule`; `Submit` checks `self.canEdit` and dispatches `PNC.Client.RequestColonyAction("provision_set", { submission = submission })`. | Local interaction state + thin command submission; authoritative rule persistence and execution remain in server `ColonyManagement.HandleAction` and `PNC.ProvisionPolicy`. |
| `Colonist/PNC_ColonistActivities_Actions.lua:165–220` | Button state resolves a command and calls `Client.ExecuteCompanionCommand`; inventory button opens a view. | Command submission/presentation. Graph's `execute` edge to server consumption execution is a lexical alias mismatch, not this call target. |
| `Base/PNC_BaseBuildingPlacement.lua` & `Base/PNC_BaseBuildingPlacementPolicy.lua` | `Placement` manages local cursor/drag state and tile highlight rendering; `Policy.ValidateFootprint` delegates footprint and queue collision checks to shared domain helpers (`PsychopatzCore/World/PC_GridRegion`, `PNC/Core/Settlement/PNC_BuildingFootprint`, `PNC/Core/Settlement/PNC_BuildingQueueCollision`) for red/blue tile preview feedback. | Preview-only UI feedback; authoritative admission and work-queue creation remain in server `BuildingService` / `FacilityService`. |
| `Base/PNC_BaseBuildingQueueActions.lua:1–66` | Tracks local `window.pncBuildingCancelPending` UI button state and dispatches `PNC.Client.RequestColonyAction("work_cancel", { workType = ..., id = ... })`. | Command submission/presentation. |
| `SettlementManagement/PNC_SettlementManagement_FacilityActions_Build.lua:1–128` | Resolves recipe descriptors from `PNC.FacilityDefinitions` and `PNC.BuildRecipeCatalog`, opens either `Placement.Begin` or the area selector, and submits `PNC.Client.RequestCreateFacility` / `RequestSetFacilityComponent` / `RequestSetFarmPlotCrop`. | Presentation routing and command submission; no authoritative facility mutation occurs in UI. |
| `Inventory/PNC_InventoryTransferEndpoint/` (`_Common.lua`, `_LocalDraft.lua`, `_NPC.lua`, `_Selection.lua`, `_Storage.lua`, `_Trade.lua`) | Uniform UI adapter over four counterparty types (`NPC`, `Storage`, `Trade`, `LocalDraft`). `NPC` and `Storage` read `PNC.Network.ClientState` snapshots and dispatch `PNC.Client.SendInventoryTransfer` / `PNC.Client.TransferPlayerStorage`; `Trade` delegates commits to `PNC_TradeController`; `LocalDraft` delegates draft record synthesis/sync to `PNC/Identity/PNC_UniqueNPCDraft` and shared `PNC.Inventory` / `PNC.InventoryActions`. | Clean UI adapter boundary; authoritative transfers and storage mutations execute in server `ServerInventory` / `ColonyStorageService` / `DynamicTrading`. |

## Evidence and P6 acceptance

P6A/P6B reports pin moved source, focused/full suites, compiler checks, boundary
ratchet and canonical entry discovery. Graph coverage is best effort: statement
imports, dynamic callbacks and lexical aliases need source/literal checks. The
UI-to-server CALLS query returned the one `execute` mismatch above; no cross-file
WRITES edges were recorded.

The bounded literal candidate scan also found native read-only item/body identity
inspection, debug settings, command/network submission and UI-local `Internal`
providers. Result presentation has been classified in `CYCLE_REVIEW.md` with P7H
source and test evidence. Tasking/BodyLifecycle foreign-private calls migrated
through P7A and P7C, and nameplate diagnostic snapshot formatting moved to
`ClientPresenceSync` in P7D / P7L. Facility/build admission, provision submission,
and inventory endpoint adapters are now verified and documented above; **P6 UI
presentation ownership review is complete and accepted.**
