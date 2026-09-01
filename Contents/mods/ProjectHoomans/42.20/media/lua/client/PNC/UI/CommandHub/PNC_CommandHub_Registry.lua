PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"
local Registry = CoreHub.Registry
PNC.CommandHub.Registry = Registry

local function trace(event, message)
    if CoreHub.Trace then
        CoreHub.Trace(event, message)
    end
end

local function isOpen(childID)
    local controller = PNC.CommandHub.ChildController
    return controller and controller.IsOpen
        and controller.IsOpen(childID) == true or false
end

local function toggleChild(childID, fallback)
    return function(_, owner)
        trace("pnc_toggle_child_start", "child=" .. tostring(childID)
            .. " has_owner=" .. tostring(owner ~= nil))
        local result
        if PNC.CommandHub.ToggleChild then
            result = PNC.CommandHub.ToggleChild(childID, owner)
        else
            local controller = PNC.CommandHub.ChildController
            if controller and controller.Toggle then
                result = controller.Toggle(childID, owner)
            elseif fallback then
                result = fallback(_, owner)
            else
                result = false
            end
        end
        trace("pnc_toggle_child_result", "child=" .. tostring(childID)
            .. " result=" .. tostring(result))
        return result
    end
end

local function openHubSettings(_, owner)
    trace("pnc_settings_open_start", "has_owner=" .. tostring(owner ~= nil)
        .. " available=" .. tostring(PNC.CommandHub.SettingsUI ~= nil
            and PNC.CommandHub.SettingsUI.Open ~= nil))
    if PNC.CommandHub.SettingsUI
        and PNC.CommandHub.SettingsUI.Open
    then
        local result = PNC.CommandHub.SettingsUI.Open(owner)
        trace("pnc_settings_open_result", "result=" .. tostring(result ~= nil))
        return result
    end
    trace("pnc_settings_open_result", "result=false reason=missing_settings_ui")
    return false
end

local function openWork(_, owner)
    trace("pnc_work_open_start", "has_owner=" .. tostring(owner ~= nil)
        .. " available=" .. tostring(PNC.CommandHub.WorkUI ~= nil
            and PNC.CommandHub.WorkUI.Open ~= nil))
    if PNC.CommandHub.WorkUI and PNC.CommandHub.WorkUI.Open then
        local result = PNC.CommandHub.WorkUI.Open(owner)
        trace("pnc_work_open_result", "result=" .. tostring(result ~= nil))
        return result
    end
    trace("pnc_work_open_result", "result=false reason=missing_work_ui")
    return false
end

local function openZone(actionID)
    return function()
        trace("pnc_zone_open_start", "action=" .. tostring(actionID)
            .. " available=" .. tostring(PNC.CommandHub.ZoneUI ~= nil
                and PNC.CommandHub.ZoneUI.Open ~= nil))
        if PNC.CommandHub.ZoneUI
            and PNC.CommandHub.ZoneUI.Open
        then
            local result = PNC.CommandHub.ZoneUI.Open(actionID,
                PNC.CommandHub.instance)
            trace("pnc_zone_open_result", "action=" .. tostring(actionID)
                .. " result=" .. tostring(result ~= nil))
            return result
        end
        trace("pnc_zone_open_result", "action=" .. tostring(actionID)
            .. " result=false reason=missing_zone_ui")
        return false
    end
end

Registry.SetCategoryOrder({ "work", "zone", "settings" })

Registry.RegisterCategory({
    id = "work",
    source = "ProjectHoomans",
    order = 10,
    childID = "work",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Work",
    titleFallback = "Work",
    tooltipKey = "UI_PNC_CommandHub_WorkHelp",
    tooltipFallback = "Authorize colonists for automatic work",
    onClick = toggleChild("work", openWork),
    selected = function() return isOpen("work") end,
    closeHub = false,
})

Registry.RegisterCategory({
    id = "zone",
    source = "ProjectHoomans",
    order = 20,
    childID = "zone",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Zone",
    titleFallback = "Zone",
    tooltipKey = "UI_PNC_CommandHub_ZoneHelp",
    tooltipFallback = "Assign work areas for colony activities",
    onClick = toggleChild("zone"),
    selected = function() return isOpen("zone") end,
    closeHub = false,
    actions = {
        {
            id = "lumber",
            source = "ProjectHoomans",
            order = 10,
            titleKey = "UI_PNC_CommandHub_Zone_ChopWood",
            titleFallback = "Chop wood",
            tooltipKey = "UI_PNC_CommandHub_Zone_ChopWoodHelp",
            tooltipFallback = "Set a tree-cutting zone",
            onClick = openZone("lumber"),
            closeHub = false,
        },
        {
            id = "corpse_haul",
            source = "ProjectHoomans",
            order = 20,
            titleKey = "UI_PNC_CommandHub_Zone_GrabCorpse",
            titleFallback = "Grab corpse",
            tooltipKey = "UI_PNC_CommandHub_Zone_GrabCorpseHelp",
            tooltipFallback = "Choose a corpse source and destination area",
            onClick = openZone("corpse_haul"),
            closeHub = false,
        },
        {
            id = "fishing",
            source = "ProjectHoomans",
            order = 30,
            titleKey = "UI_PNC_CommandHub_Zone_Fishing",
            titleFallback = "Fishing",
            tooltipKey = "UI_PNC_CommandHub_Zone_FishingHelp",
            tooltipFallback = "Set a shoreline fishing zone",
            onClick = openZone("fishing"),
            closeHub = false,
        },
    },
})

Registry.RegisterCategory({
    id = "settings",
    source = "ProjectHoomans",
    order = 30,
    childID = "settings",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Settings",
    titleFallback = "Settings",
    tooltipKey = "UI_PNC_CommandHub_Settings_Help",
    tooltipFallback = "Edit the hub position, dimensions, and opacity",
    onClick = toggleChild("settings", openHubSettings),
    selected = function() return isOpen("settings") end,
    closeHub = false,
})

return Registry
