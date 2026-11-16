-- Command Hub action adapters.
--
-- This provider owns the optional UI routing and action callbacks used by the
-- category definitions.  The registry root owns composition and keeps the
-- public Registry and Gates tables unchanged.

local Internal = PNC.CommandHub.RegistryInternal
local Registry = Internal.Registry
local Gates = Internal.Gates
local trace = Internal.Trace

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
        local controller = PNC.CommandHub.ChildController
        local reason = controller and controller.lastFailureReason or nil
        trace("pnc_toggle_child_result", "child=" .. tostring(childID)
            .. " result=" .. tostring(result)
            .. " reason=" .. tostring(reason or ""))
        return result
    end
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

local function openColonist(_, owner)
    trace("pnc_colonist_open_start", "has_owner=" .. tostring(owner ~= nil)
        .. " available=" .. tostring(PNC.ColonistUI ~= nil
            and PNC.ColonistUI.Open ~= nil))
    local colonist = PNC.ColonistUI
    if colonist and type(colonist.Open) == "function" then
        local result = colonist.Open(owner)
        trace("pnc_colonist_open_result", "result=" .. tostring(result ~= nil))
        return result
    end
    trace("pnc_colonist_open_result", "result=false reason=missing_colonist_ui")
    return false
end

local function openStorage(_, owner)
    trace("pnc_storage_open_start", "has_owner=" .. tostring(owner ~= nil)
        .. " available=" .. tostring(PNC.ColonyStorageUI ~= nil
            and PNC.ColonyStorageUI.Open ~= nil))
    local storage = PNC.ColonyStorageUI
    if storage and type(storage.Open) == "function" then
        local result = storage.Open(owner)
        trace("pnc_storage_open_result", "result=" .. tostring(result ~= nil))
        return result
    end
    trace("pnc_storage_open_result",
        "result=false reason=missing_storage_ui")
    return false
end

local function openResearch(_, owner)
    trace("pnc_research_open_start", "has_owner=" .. tostring(owner ~= nil)
        .. " available=" .. tostring(PNC.ResearchUI ~= nil
            and PNC.ResearchUI.Open ~= nil))
    local research = PNC.ResearchUI
    if research and type(research.Open) == "function" then
        local result = research.Open(owner)
        trace("pnc_research_open_result", "result=" .. tostring(result ~= nil))
        return result
    end
    trace("pnc_research_open_result",
        "result=false reason=missing_research_ui")
    return false
end

local function openBase(_, owner)
    trace("pnc_base_open_start", "has_owner=" .. tostring(owner ~= nil)
        .. " available=" .. tostring(PNC.BaseUI ~= nil
            and PNC.BaseUI.Open ~= nil))
    local base = PNC.BaseUI
    if base and type(base.Open) == "function" then
        local result = base.Open(owner)
        trace("pnc_base_open_result",
            "result=" .. tostring(result ~= nil))
        return result
    end
    trace("pnc_base_open_result",
        "result=false reason=missing_base_ui")
    return false
end

local function scavengeSnapshot()
    local state = PNC.Network and PNC.Network.ClientState or nil
    local sessionId = state and state.activeScavengeSessionId or nil
    return sessionId and state.scavengeSessions
        and state.scavengeSessions[sessionId] or nil
end

local function scavengeAvailable()
    local controller = PNC.ScavengeController
    local team = controller and controller.TeamIDs
        and controller.TeamIDs() or {}
    return #team > 0 or scavengeSnapshot() ~= nil
end

local function isScavengeOpen()
    local scavenge = PNC.ScavengeUI
    return scavenge and scavenge.instance
        and scavenge.instance.getIsVisible
        and scavenge.instance:getIsVisible() == true or false
end

local function openScavenge(_, owner)
    local controller = PNC.ScavengeController
    if not controller or type(controller.Open) ~= "function"
        or not scavengeAvailable()
    then
        return false
    end
    local team = controller.TeamIDs and controller.TeamIDs() or {}
    local snapshot = scavengeSnapshot()
    local npcId = team[1] or snapshot and snapshot.npcId
    return controller.Open(npcId, {
        npcIds = team,
        name = #team > 0 and (tostring(#team) .. " scavengers") or nil,
        owner = owner,
    })
end

local function stockpileBootstrapVisible()
    return not Gates.GetBaseAndStockpileStatus().hasStockpileFacility
end

local function stockpileBootstrapEnabled()
    local status = Gates.GetBaseAndStockpileStatus()
    return status.hasBase and not status.hasStockpileFacility
        and Gates.GetStockpileMaterialStatus().affordable == true
end

local function stockpileBootstrapDisabledTooltip()
    local status = Gates.GetBaseAndStockpileStatus()
    if not status.hasBase then
        return {
            key = "UI_PNC_CommandHub_Disabled_NoBase",
            fallback = "Requires a colony base.",
        }
    end
    if status.hasStockpileFacility then return nil end
    local materials = Gates.GetStockpileMaterialStatus()
    if not materials.affordable then
        return {
            key = "UI_PNC_CommandHub_Disabled_NoStockpileMaterials",
            fallback = "Requires the materials needed to build the first stockpile.",
        }
    end
    return nil
end

local function buildStockpile(_, owner)
    trace("pnc_stockpile_build_start", "has_owner=" .. tostring(owner ~= nil))
    if not stockpileBootstrapEnabled() then
        trace("pnc_stockpile_build_result", "result=false reason=missing_materials")
        return false
    end
    local Facility = require
        "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityActions"
    local result, reason = Facility.BeginBuild(owner, "stockpile")
    trace("pnc_stockpile_build_result",
        "result=" .. tostring(result) .. " reason=" .. tostring(reason))
    return result
end

Internal.IsOpen = isOpen
Internal.IsZoneActionOpen = isZoneActionOpen
Internal.ToggleChild = toggleChild
Internal.OpenWork = openWork
Internal.OpenZone = openZone
Internal.ToggleEvents = toggleEvents
Internal.IsJournalOpen = isJournalOpen
Internal.OpenColonist = openColonist
Internal.OpenStorage = openStorage
Internal.OpenResearch = openResearch
Internal.ScavengeAvailable = scavengeAvailable
Internal.OpenScavenge = openScavenge
Internal.IsScavengeOpen = isScavengeOpen
Internal.StockpileBootstrapVisible = stockpileBootstrapVisible
Internal.StockpileBootstrapEnabled = stockpileBootstrapEnabled
Internal.StockpileBootstrapDisabledTooltip = stockpileBootstrapDisabledTooltip
Internal.BuildStockpile = buildStockpile
Internal.OpenBase = openBase

return Internal
