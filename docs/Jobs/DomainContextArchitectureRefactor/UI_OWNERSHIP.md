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
| `Provision/PNC_ProvisionSettingsModel.lua:61–100` | `Load` copies normalized snapshot rules into an unsent editing model; `Set` changes that copy. | Local interaction state; policy remains domain-owned. Submission/authority review remains required. |
| `Colonist/PNC_ColonistActivities_Actions.lua:165–220` | Button state resolves a command and calls `Client.ExecuteCompanionCommand`; inventory button opens a view. | Command submission/presentation. Graph's `execute` edge to server consumption execution is a lexical alias mismatch, not this call target. |

## Evidence and remaining review

P6A/P6B reports pin moved source, focused/full suites, compiler checks, boundary
ratchet and canonical entry discovery. Graph coverage is best effort: statement
imports, dynamic callbacks and lexical aliases need source/literal checks. The
UI-to-server CALLS query returned the one `execute` mismatch above; no cross-file
WRITES edges were recorded. Neither absence is an exhaustive authority proof.

The bounded literal candidate scan also found native read-only item/body identity
inspection, debug settings, command/network submission and UI-local `Internal`
providers. Continue reviewing these by actual state owner. Result presentation,
facility/build admission, remaining domain cycles and Tasking/BodyLifecycle
foreign-private access are still open; this document does not accept all of P6.
