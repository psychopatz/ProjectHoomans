if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local Network = PNC.Network
local EventTypes = PNC.EventTypes or {}
local BaseValidation = PNC.BaseValidationService
local Repository = PNC.SettlementRepository
local OWNER = Management.Internal.SettlementSyncOwner
    or {}
Management.Internal.SettlementSyncOwner = OWNER
local PendingBaseIds = Management.Internal.SettlementSyncPendingBaseIds
    or {}
Management.Internal.SettlementSyncPendingBaseIds = PendingBaseIds

local function sendToPlayer(player, base, settlement)
    if not player or not base or not BaseValidation
        or not BaseValidation.CanUse or not Network
        or not Network.SendSettlementDelta
    then
        return false
    end
    local ok, allowed = pcall(BaseValidation.CanUse, player, base)
    if not ok or allowed ~= true then return false end
    Network.SendSettlementDelta(player, settlement)
    return true
end

local function eachOnlinePlayer(callback)
    if isServer and isServer() and getOnlinePlayers then
        local players = getOnlinePlayers()
        if players and type(players.size) == "function"
            and type(players.get) == "function"
        then
            for index = 0, players:size() - 1 do
                callback(players:get(index))
            end
            return
        end
        if type(players) == "table" then
            for _, player in ipairs(players) do callback(player) end
            return
        end
    end
    if getSpecificPlayer then callback(getSpecificPlayer(0)) end
end

local function baseIdFor(payload)
    if type(payload) ~= "table" then return nil end
    if payload.baseId ~= nil then return tostring(payload.baseId) end
    local facility = payload.facilityId and Repository
        and Repository.GetFacility(payload.facilityId) or nil
    return facility and tostring(facility.baseId or "") or nil
end

local function onSettlementMutation(payload)
    local baseId = baseIdFor(payload)
    if baseId and PNC.BaseService and PNC.BaseService.Get(baseId) then
        -- Construction and validation can emit several state changes in one
        -- simulation step. Rebuild one snapshot per base on the next tick.
        PendingBaseIds[baseId] = true
    end
end

local function flushPending()
    local pending = PendingBaseIds
    Management.Internal.SettlementSyncPendingBaseIds = {}
    PendingBaseIds = Management.Internal.SettlementSyncPendingBaseIds
    for baseId, _ in pairs(pending) do
        local base = PNC.BaseService and PNC.BaseService.Get(baseId) or nil
        local settlement = base and Management.Internal
            .BuildSettlementSnapshot(base) or nil
        if base and settlement then
            eachOnlinePlayer(function(player)
                sendToPlayer(player, base, settlement)
            end)
        end
    end
end

if EventsBus and EventsBus.subscribe then
    for _, eventType in ipairs({
        EventTypes.BASE_CREATED,
        EventTypes.BASE_ZONE_CHANGED,
        EventTypes.FACILITY_CREATED,
        EventTypes.FACILITY_STATE_CHANGED,
        EventTypes.FACILITY_UPGRADED,
        EventTypes.FACILITY_DESTROYED,
        EventTypes.STOCKPILE_NODE_CHANGED,
    }) do
        if eventType then
            EventsBus.subscribe(eventType, onSettlementMutation, OWNER)
        end
    end
end

if Events and Events.OnTick and Events.OnTick.Add
    and not Management.Internal.SettlementSyncTickInstalled
then
    Events.OnTick.Add(flushPending)
    Management.Internal.SettlementSyncTickInstalled = true
end

return Management
