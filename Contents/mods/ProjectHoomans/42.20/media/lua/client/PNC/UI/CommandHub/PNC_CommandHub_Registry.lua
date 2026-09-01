PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"
local Registry = CoreHub.Registry
PNC.CommandHub.Registry = Registry
PNC.CommandHub.Gates = PNC.CommandHub.Gates or {}
local Gates = PNC.CommandHub.Gates

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

local function isZoneActionOpen(actionID)
    local zoneUI = PNC.CommandHub.ZoneUI
    if not zoneUI or zoneUI.activeDefinitionID ~= actionID then return false end
    local window = zoneUI.instances and zoneUI.instances[actionID] or nil
    return window ~= nil and window.getIsVisible
        and window:getIsVisible() == true
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

local function hasRadio()
    local journalButton = PNC.ColonyJournalButton
    return journalButton
        and type(journalButton.HasRadio) == "function"
        and journalButton.HasRadio() == true or false
end

local function colonyManagementSnapshot()
    local client = PNC.ColonyManagementClient
    if client and type(client.ReadSnapshot) == "function" then
        local update = client.ReadSnapshot()
        if type(update) == "table" then
            return update.snapshot or {}
        end
    end

    local network = PNC.Network
    local state = network and network.ClientState or nil
    return state and state.colonyManagement or {}
end

function Gates.HasRadio()
    return hasRadio()
end

function Gates.HasBaseAndStockpile()
    local snapshot = colonyManagementSnapshot()
    local settlement = type(snapshot) == "table" and snapshot.settlement or nil
    if type(settlement) ~= "table" then return false end

    -- stockpileNodes are optional navigation/access points. The actual
    -- setup prerequisite is a built stockpile facility in the established
    -- base, so a valid base does not remain disabled just because no access
    -- point has been configured yet.
    for _, facility in ipairs(settlement.facilities or {}) do
        if tostring(facility.definitionId or "") == "stockpile" then
            local state = tostring(facility.constructionState or "")
            if state == "" or state == "BUILT" then return true end
        end
    end
    return false
end

local function isJournalOpen()
    local journal = PNC.ColonyJournalUI
    return journal and journal.instance
        and journal.instance.getIsVisible
        and journal.instance:getIsVisible() == true or false
end

local function toggleEvents(_, owner)
    trace("pnc_events_open_start", "has_owner=" .. tostring(owner ~= nil)
        .. " available=" .. tostring(PNC.ColonyJournalUI ~= nil
            and PNC.ColonyJournalUI.Toggle ~= nil))
    local journal = PNC.ColonyJournalUI
    if journal and type(journal.Toggle) == "function" then
        local result = journal.Toggle(owner)
        trace("pnc_events_open_result", "result=" .. tostring(result))
        return result
    end
    trace("pnc_events_open_result", "result=false reason=missing_journal_ui")
    return false
end

Registry.SetCategoryOrder({ "work", "zone", "settings", "events" })

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
    enabled = Gates.HasBaseAndStockpile,
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
    enabled = Gates.HasBaseAndStockpile,
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
            selected = function() return isZoneActionOpen("lumber") end,
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
            selected = function() return isZoneActionOpen("corpse_haul") end,
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
            selected = function() return isZoneActionOpen("fishing") end,
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

Registry.RegisterCategory({
    id = "events",
    source = "ProjectHoomans",
    order = 40,
    childID = "events",
    titleKey = "UI_PNC_CommandHub_Category_Events",
    titleFallback = "Events",
    tooltipKey = "UI_PNC_CommandHub_EventsHelp",
    tooltipFallback = "Open the colony journal",
    onClick = toggleChild("events", toggleEvents),
    selected = isJournalOpen,
    closeHub = false,
})

return Registry
