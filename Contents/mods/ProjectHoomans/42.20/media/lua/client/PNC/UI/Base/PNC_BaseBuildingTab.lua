local Data = require "PNC/UI/Base/PNC_BaseBuildingData"
local View = require "PNC/UI/Base/PNC_BaseBuildingView"
local BuildingCatalog = require
    "PNC/UI/Base/PNC_BaseBuildingCatalog"
local Placement = require
    "PNC/UI/Base/PNC_BaseBuildingPlacement"
local QueueOverlay = require
    "PNC/UI/Base/PNC_BaseBuildingQueueOverlay"

local Building = {}

local function catalogActive(window)
    return window.tab == "facilities" or window.tab == "buildings"
end

local function canUseDebug()
    return PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
end

function Building.Create(window)
    window.baseBuildingCategory = nil
    window.baseBuildingCatalogKind = "buildings"
    window.baseBuildingPage = 1
    View.Create(window)
    -- Keep the vanilla-style recipe browser in the same Base window. Its
    -- controls use the legacy `build*` namespace, so it can coexist with the
    -- facility-card controls without creating a second window.
    BuildingCatalog.Create(window, PsychopatzCore.UI)
end

function Building.Layout(window, content)
    if window.tab == "buildings" then
        BuildingCatalog.Layout(window, PsychopatzCore.UI.Layout, content)
    else
        View.Layout(window, content)
    end
end

function Building.Apply(window, active)
    local facilitiesActive = active and window.tab == "facilities"
    local buildingsActive = active and window.tab == "buildings"
    if facilitiesActive then
        local kind = "facilities"
        if window.baseBuildingCatalogKind ~= kind then
            window.baseBuildingCatalogKind = kind
            View.Rebuild(window, window.snapshot or {})
        end
    elseif buildingsActive then
        local kind = "buildings"
        if window.baseBuildingCatalogKind ~= kind then
            window.baseBuildingCatalogKind = kind
            BuildingCatalog.Rebuild(window, window.snapshot or {})
        end
    end
    View.Apply(window, facilitiesActive)
    BuildingCatalog.Apply(window, buildingsActive)
    if not active then
        Placement.Cancel(window)
    end
end

function Building.Rebuild(window, snapshot)
    if window.tab == "buildings" then
        return BuildingCatalog.Rebuild(window, snapshot)
    end
    return View.Rebuild(window, snapshot)
end

-- Kept below as a compatibility note for callers that inspect the old
-- catalog-kind state. The active branch above deliberately owns the tab
-- boundary so room cards never get rebuilt from the recipe catalog.
function Building.OnControl(window, button)
    local id = button and button.internal or ""
    if window.tab == "buildings" then
        return BuildingCatalog.OnControl(window, button)
    end
    local category = string.match(tostring(id), "^building_category:(.+)$")
    if category then
        window.baseBuildingCategory = category
        window.baseBuildingPage = 1
        View.Rebuild(window, window.snapshot or {})
        window:requestResponsiveLayout(true)
        return true
    end
    if id == "page_previous" then
        window.baseBuildingPage = math.max(1,
            (tonumber(window.baseBuildingPage) or 1) - 1)
        View.Rebuild(window, window.snapshot or {})
        window:requestResponsiveLayout(true)
        return true
    end
    if id == "page_next" then
        window.baseBuildingPage = math.min(
            tonumber(window.baseBuildingPageCount) or 1,
            (tonumber(window.baseBuildingPage) or 1) + 1)
        View.Rebuild(window, window.snapshot or {})
        window:requestResponsiveLayout(true)
        return true
    end
    local option = Data.SelectedOption(window)
    if id == "build_selected" and option and option.enabled == true then
        local FacilityActions = require
            "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityActions"
        local started = FacilityActions.BeginBuild(window, option.id) ~= false
        View.Apply(window, true)
        window:requestResponsiveLayout(true)
        return started
    end
    if id == "debug_materials" and option and canUseDebug() then
        if PNC.Client and PNC.Client.RequestDebugFacilityMaterials then
            PNC.Client.RequestDebugFacilityMaterials({ definitionId = option.id })
        elseif PNC.Client and PNC.Client.RequestColonyAction then
            PNC.Client.RequestColonyAction("building_debug_get_items", {
                recipeKey = option.id,
            })
        end
        return true
    end
    if id == "place" then
        if option and option.enabled == true then
            return Building.OnControl(window, { internal = "build_selected" })
        end
        return false
    end
    if id == "cancel_placement" then
        Placement.Cancel(window)
        return true
    end
    if id == "toggle_queue_overlay" then
        QueueOverlay.Toggle()
        View.Apply(window, catalogActive(window))
        return true
    end
    if id == "cancel_order" then
        local selected = window.baseBuildingNativeQueueSelectedID
        if selected and PNC.Client and PNC.Client.RequestColonyAction then
            PNC.Client.RequestColonyAction("work_cancel", {
                workOrderId = selected,
            })
            return true
        end
    end
    if id == "close_building" then
        window:close()
        return true
    end
    return false
end

return Building
