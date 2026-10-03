-- Zone window state and request service.
--
-- This provider owns colony snapshot reads, revision tracking, and deferred
-- selector startup.  The window keeps rendering and input policy while the
-- provider keeps network timing and pending-operation state in one place.

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local Hub = PNC.CommandHub
local ZoneUI = Hub.ZoneUI
local Registry = require "PNC/UI/CommandHub/PNC_CommandHub_ZoneRegistry"
local UI = PsychopatzCore.UI
local Selector = UI.GridRegionSelector

local Service = Hub.ZoneWindowInternal or {}
Hub.ZoneWindowInternal = Service

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function snapshot(definitionID)
    local client = PNC.ColonyManagementClient
    if definitionID == "base_zone" and client
        and type(client.ReadBaseSnapshot) == "function"
    then
        local update = client.ReadBaseSnapshot()
        if type(update) == "table" and type(update.snapshot) == "table" then
            return update.snapshot
        end
    end
    return PNC.Network and PNC.Network.ClientState
        and (PNC.Network.ClientState.colonyManagement
            or PNC.Network.ClientState.colonyBase) or {}
end

local function revision(definitionID)
    local client = PNC.ColonyManagementClient
    if definitionID == "base_zone" and client
        and type(client.ReadBaseSnapshot) == "function"
    then
        local update = client.ReadBaseSnapshot()
        if type(update) == "table" then return tonumber(update.revision) or 0 end
    end
    local state = PNC.Network and PNC.Network.ClientState or {}
    return tonumber(state.colonyManagementRevision) or 0
end

local function isPendingSnapshotReason(reason)
    return reason == "COLONY_STATE_UNAVAILABLE"
        or reason == "FACTION_STATE_UNAVAILABLE"
        or reason == "BASE_STATE_UNAVAILABLE"
        or reason == "PLAYER_UNAVAILABLE"
end

local function actionResultText(result)
    if type(result) ~= "table"
        or result.action ~= "corpse_haul_zones_set"
        or result.ok ~= false
    then return nil end
    if result.reason == "CORPSE_HAUL_ZONES_OVERLAP" then
        return tr("UI_PNC_CommandHub_CorpseHaul_Overlap",
            "Collect and dump areas cannot overlap.")
    end
    return tostring(result.reason or "CORPSE_HAUL_SAVE_FAILED")
end

Service.Snapshot = snapshot
Service.Revision = revision
Service.ActionResultText = actionResultText

function Service.RequestSnapshot(window)
    if window.definitionID == "base_zone"
        and PNC.Client and PNC.Client.RequestBaseBootstrap
    then
        PNC.Client.RequestBaseBootstrap()
    elseif PNC.Client and PNC.Client.RequestColonyManagement then
        PNC.Client.RequestColonyManagement()
    end
    window.lastRequestAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

function Service.TryStartPendingOperation(window)
    local operation = window.pendingOperation
    if not operation then return false end
    if Selector and Selector.instance
        and Selector.instance.ownerWindow == window
    then
        window.pendingOperation = nil
        return true
    end
    local current = snapshot(window.definitionID)
    if operation == "create"
        and (type(current.colony) ~= "table"
            or not current.colony.id
            or not (current.colony.factionID or current.colony.factionId))
    then
        return false
    end
    local definition = window:getDefinition()
    local result, reason
    local section = definition and definition.sections
        and definition.sections[1] or nil
    if section and type(section.open) == "function" then
        result, reason = section.open(window, operation)
    else
        result, reason = false, "SELECTOR_UNAVAILABLE"
    end
    if result == false or result == nil then
        if isPendingSnapshotReason(reason) then return false end
        window.pendingOperation = nil
        window:setStatus(tostring(reason or tr(
            "UI_PNC_CommandHub_Zone_SelectorUnavailable",
            "ZONE SELECTOR UNAVAILABLE")))
        return false
    end
    window.pendingOperation = nil
    return true
end

return Service
