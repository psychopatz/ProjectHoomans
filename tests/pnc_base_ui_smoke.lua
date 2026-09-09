local T = require "tests/support/test"

local windowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseWindow.lua")
local buildingSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingTab.lua")
local buildingViewSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingView.lua")
local buildingCardsSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingCards.lua")
local buildingDataSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingData.lua")
local buildingCatalogSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagementBuildingTab.lua")
local queueSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseQueue.lua")
local lifecycleSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseWindowLifecycle.lua")
local inventoryListSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Inventory/PNC_InventoryUI_List.lua")
local facilityModalSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal.lua")
local legacySource = T.read("ProjectHoomans", "client",
    "PNC/UI/Building/PNC_Building.lua")
local hubSource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub.lua")
local registrySource = T.read("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Registry.lua")
local baseTabSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_Tab.lua")

T.contains(windowSource, 'id = "pnc-command-hub-base-widget"',
    "Base window is not installed as a detachable widget")
T.contains(windowSource, 'persistenceKey = "PNC.CommandHub.Base"',
    "Base window does not persist its geometry")
T.contains(windowSource, '{ "base", tr',
    "Base tab is missing")
T.contains(windowSource, '{ "facilities", tr',
    "Facilities tab is missing")
T.contains(windowSource, '{ "buildings", tr',
    "Buildings tab is missing")
T.contains(windowSource, "local tabOrder = { \"base\", \"facilities\", \"buildings\" }",
    "Base tab layout does not use an explicit tab count")
T.contains(lifecycleSource, "BaseTab.Rebuild",
    "Base window does not refresh the authoritative facility tab")
T.contains(lifecycleSource, "BuildingTab.Rebuild",
    "Base window does not refresh the building catalog tab")
T.contains(buildingCardsSource, "BuildUI.FacilityCard",
    "Building tab does not reuse the established facility card surface")
T.contains(buildingViewSource, "Data.CatalogOptions",
    "Base catalogs are not separated into facilities and buildings")
T.contains(buildingDataSource, 'option.id ~= "stockpile"',
    "Stockpile is still exposed in the Facilities catalog")
T.contains(buildingCatalogSource, "FilterFacilityRecipes",
    "Buildings catalog does not remove facility-backed recipes")
T.contains(buildingCatalogSource, "SetRowsStable",
    "Buildings catalog still clears live lists during refresh")
T.contains(inventoryListSource, "function ISPNCInventoryList:resolveMouse",
    "Building catalog list does not normalize resized/scrolling input coordinates")
T.contains(buildingCatalogSource, "buildRecipePreview",
    "Buildings catalog is missing the selected-recipe preview pane")
T.contains(facilityModalSource, "BuildUI.DrawNativePreview",
    "Native building preview compositor is not shared with the Buildings tab")
T.contains(buildingViewSource, "REQUIREMENTS",
    "Building tab does not expose the lower material requirements pane")
T.contains(buildingViewSource, "ISScrollingListBox.onMouseDown(list, x, y)",
    "Building queue click handler bypasses native scrolling-list selection")
T.contains(buildingViewSource, "baseBuildingCloseButton",
    "Building tab is missing the reference-style cancel action")
T.contains(buildingViewSource, "baseBuildingCards or {}",
    "Facility cards are not hidden when the Buildings catalog is active")
T.contains(lifecycleSource, "requestResponsiveLayout(false)",
    "Base snapshot refresh still forces a full layout and can blink lists")
T.contains(buildingSource, "RequestDebugFacilityMaterials",
    "Building debug material action was not preserved")
T.contains(buildingSource, "building_debug_get_items",
    "Legacy building debug action fallback was not preserved")
T.contains(queueSource, "facility.activeTask",
    "Base queue does not project facility work")
T.contains(queueSource, "work_cancel",
    "Base queue does not preserve cancellation protocol")
T.contains(queueSource, "resume_work",
    "Base queue does not preserve the resume action route")
T.contains(legacySource, "PNC/UI/Base/PNC_Base",
    "legacy Building entry point does not resolve to Base")
T.contains(hubSource, "PNC/UI/Base/PNC_Base",
    "Command Hub does not load the Base widget")
T.contains(registrySource, "UI_PNC_CommandHub_Category_Base",
    "Command Hub category is not named Base")
T.contains(registrySource, "PNC.BaseUI or PNC.BuildingUI",
    "Command Hub does not prefer the Base widget")
T.contains(baseTabSource, "window.baseIntegrated",
    "Base tab cannot suppress its duplicate build toolbar")
T.contains(baseTabSource, "task and task.id ~= nil",
    "Base tab does not recognize active construction tasks")
T.contains(queueSource, "Components.SetRowsStable",
    "Base construction queue still clears its native list on refresh")

package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return { Probe = function() return {} end }
end
PNC = {
    FacilityDefinitions = {
        Get = function(id)
            return id == "room_from_definition"
                and { directWorkstation = false } or nil
        end,
    },
}
local CatalogData = T.load("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingData.lua")
local facilities = CatalogData.CatalogOptions({
    { id = "bedroom", directWorkstation = false },
    { id = "stockpile", directWorkstation = false },
    { id = "room_from_definition" },
    { id = "forge", directWorkstation = true },
}, "facilities")
local buildings = CatalogData.CatalogOptions({
    { id = "bedroom", directWorkstation = false },
    { id = "stockpile", directWorkstation = false },
    { id = "room_from_definition" },
    { id = "forge", directWorkstation = true },
}, "buildings")
T.equal(#facilities, 3,
    "Facilities catalog did not retain rooms and workstations while hiding stockpile")
T.equal(#buildings, 0,
    "Buildings catalog still uses the legacy facility-card provider")

T.finish("pnc_base_ui_smoke")
