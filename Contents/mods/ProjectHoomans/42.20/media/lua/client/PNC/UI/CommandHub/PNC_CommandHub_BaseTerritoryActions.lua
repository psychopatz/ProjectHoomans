local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Support = require
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local Territory = PNC.CommandHub.BaseTerritoryActions or {}
PNC.CommandHub.BaseTerritoryActions = Territory

local OPERATION_ACTIONS = {
    create = "base_create",
    expand = "base_expand",
    shrink = "base_shrink",
}

local BASE_ACTIONS = {
    base_create = true,
    base_expand = true,
    base_shrink = true,
}

local function tr(key, fallback)
    return Shared.Tr(key, fallback)
end

local function player()
    return type(getSpecificPlayer) == "function"
        and getSpecificPlayer(0) or nil
end

local function snapshotFor(window)
    local client = PNC.ColonyManagementClient
    if client and type(client.ReadSnapshot) == "function" then
        local update = client.ReadSnapshot()
        if type(update) == "table" and type(update.snapshot) == "table" then
            return update.snapshot
        end
    end
    return window and type(window.snapshot) == "table"
        and window.snapshot or {}
end

local function setStatus(window, value)
    if not window then return end
    if type(window.setBaseStatus) == "function" then
        window:setBaseStatus(value)
    elseif type(window.setStatus) == "function" then
        window:setStatus(value)
    else
        window.baseTerritoryStatus = tostring(value or "")
    end
end

local function requestFor(operation, snapshot, region)
    local client = PNC.Client
    if not client then return false, "CLIENT_UNAVAILABLE" end
    local settlement = snapshot and snapshot.settlement or nil
    local colony = snapshot and snapshot.colony or nil
    if operation == "create" then
        if not colony or not colony.id then
            return false, "COLONY_STATE_UNAVAILABLE"
        end
        local factionID = colony.factionID or colony.factionId
        if not factionID then
            return false, "FACTION_STATE_UNAVAILABLE"
        end
        if type(client.RequestCreateBase) ~= "function" then
            return false, "CLIENT_UNAVAILABLE"
        end
        return client.RequestCreateBase({
            colonyId = colony.id,
            factionId = factionID,
            region = region,
        })
    end
    if not settlement or not settlement.id then
        return false, "BASE_STATE_UNAVAILABLE"
    end
    local request = {
        baseId = settlement.id,
        expectedRevision = settlement.revision,
        regionDelta = region,
    }
    if operation == "expand" then
        if type(client.RequestExpandBase) ~= "function" then
            return false, "CLIENT_UNAVAILABLE"
        end
        return client.RequestExpandBase(request)
    end
    if type(client.RequestShrinkBase) ~= "function" then
        return false, "CLIENT_UNAVAILABLE"
    end
    return client.RequestShrinkBase(request)
end

function Territory.IsAction(action)
    return BASE_ACTIONS[tostring(action or "")] == true
end

function Territory.ApplyResult(window, snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    local result = snapshot.actionResult
    if type(result) ~= "table" or not Territory.IsAction(result.action) then
        return false
    end
    local resultID = result.requestId and tostring(result.requestId) or nil
    if resultID and window
        and window.baseTerritoryLastResultID == resultID
    then
        return false
    end
    local pending = window and window.baseTerritoryRequestID or nil
    if pending and result.requestId
        and tostring(pending) ~= tostring(result.requestId)
    then
        return false
    end
    if result.ok == true then
        setStatus(window, tr("UI_PNC_Base_TerritoryUpdated",
            "TERRITORY UPDATED"))
    else
        setStatus(window, Shared.SettlementReason(result.reason))
    end
    if window then
        window.baseTerritoryRequestID = nil
        window.baseTerritoryLastResultID = resultID
    end
    return true
end

function Territory.Begin(window, operation)
    operation = tostring(operation or "")
    if not OPERATION_ACTIONS[operation] then
        return false, "INVALID_TERRITORY_OPERATION"
    end
    local currentSnapshot = snapshotFor(window)
    local settlement = currentSnapshot.settlement
    local current = settlement and Support.BaseRegion(window)
        or Support.EmptyRegion()
    local currentCount = GridRegion.countTiles(current)
    local territory = settlement and settlement.territory or {}
    local maximum = operation == "create"
        and (PNC.SettlementDefinitions
            and PNC.SettlementDefinitions.STARTING_TERRITORY or 270)
        or tonumber(territory.territoryCapacity) or 0
    local titles = {
        create = tr("UI_PNC_Base_SelectCreate",
            "SELECT AREA: BASE TERRITORY"),
        expand = tr("UI_PNC_Base_SelectExpand", "SELECT AREA TO ADD"),
        shrink = tr("UI_PNC_Base_SelectShrink", "SELECT AREA TO REMOVE"),
    }
    local worldPlayer = player()
    if not worldPlayer then
        setStatus(window, tr("UI_PNC_CommandHub_Zone_SelectorUnavailable",
            "ZONE SELECTOR UNAVAILABLE"))
        return false, "PLAYER_UNAVAILABLE"
    end
    local options = {
        title = titles[operation],
        instruction = tr("UI_PNC_Base_SelectHelp",
            "Drag a rectangle; use Add or Erase to shape an irregular connected area."),
        initialRegion = Support.EmptyRegion(),
        guideRegion = operation == "create" and nil or current,
        guideRenderZ = type(worldPlayer.getZ) == "function"
            and math.floor(worldPlayer:getZ()) or 0,
        maxTiles = operation == "create" and maximum or nil,
        highlightColor = operation == "shrink"
            and { r = 1, g = 0.25, b = 0.2, a = 0.42 }
            or { r = 0.15, g = 0.7, b = 1, a = 0.44 },
        debugLabel = "base_territory_" .. operation,
        inputOwner = "ProjectHoomans.CommandHub.BaseTerritorySelector",
    }
    options.validate = function(region, stats)
        local candidate = operation == "create" and Support.Footprint(region)
            or operation == "expand"
                and GridRegion.union(current, Support.Footprint(region))
            or GridRegion.subtract(current, Support.Footprint(region))
        local ok, reason = Support.ValidateConnected(candidate)
        local claimed = GridRegion.countTiles(candidate)
        if ok and claimed > maximum then
            ok, reason = false, "BASE_CAPACITY_EXCEEDED"
        end
        if ok and operation == "expand" and claimed <= currentCount then
            ok, reason = false, "NO_NEW_TERRITORY"
        end
        if ok and operation == "shrink" and claimed >= currentCount then
            ok, reason = false, "NO_TERRITORY_REMOVED"
        end
        return ok, ok and nil or Shared.SettlementReason(reason), {
            claimed = claimed, capacity = maximum,
            selected = stats and stats.tileCount or 0,
        }
    end
    options.onConfirm = function(region)
        local latest = snapshotFor(window)
        local ok, reason, requestID = requestFor(operation, latest, region)
        if ok ~= true then
            setStatus(window, Shared.SettlementReason(reason))
            return false
        end
        if window then window.baseTerritoryRequestID = requestID end
        setStatus(window, tr("UI_PNC_CommandHub_Zone_RequestSent",
            "ZONE REQUEST SENT"))
        return true
    end
    local selector, reason = Support.OpenSelector(window, options)
    if not selector then
        setStatus(window, Shared.SettlementReason(reason
            or "PLAYER_UNAVAILABLE"))
        return false, reason or "SELECTOR_UNAVAILABLE"
    end
    setStatus(window, tr("UI_PNC_CommandHub_Zone_Selecting",
        "SELECT AN AREA IN THE WORLD"))
    return selector
end

return Territory
