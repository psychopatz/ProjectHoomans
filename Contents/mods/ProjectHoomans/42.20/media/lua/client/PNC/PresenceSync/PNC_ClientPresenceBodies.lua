--[[
    PNC Client Presence Bodies
    Indexes replicated bodies and removes stale or duplicate local shells.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Const = PNC.Const
local Network = PNC.Network
local ClientState = PNC.Network.ClientState
local Registry = require
    "PNC/PresenceSync/PNC_ClientPresenceBodies_Registry"
local Cleanup = require
    "PNC/PresenceSync/PNC_ClientPresenceBodies_Cleanup"

-- Conversation and presentation code may ask for a body before the registry
-- has been rebound on this client.  The presence scanner is still the
-- authoritative local-body index in that interval, so expose the same
-- lease/instance/UUID validation without making callers reach into Internal.
function Sync.ResolveBodyForNPC(id, snapshot)
    return Registry.ResolveForNPC(
        Sync,
        id,
        snapshot,
        ClientState and ClientState.snapshots or nil
    )
end

local function refreshBodyMap(now)
    local cell
    local zombieList
    local onlineID
    local instanceKey
    local scanInterval = tonumber(Const.CLIENT_BODY_SCAN_MS) or 750
    local id
    local snapshot
    local indexes
    if not getCell
        or now < ((tonumber(Sync.lastBodyScanAt) or 0) + (tonumber(Const.CLIENT_BODY_SCAN_UNRESOLVED_MS) or 200))
    then
        return
    end
    for id, snapshot in pairs(ClientState and ClientState.snapshots or {}) do
        if snapshot and snapshot.interestDetailed ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE and snapshot.alive ~= false
        then
            onlineID = snapshot.liveBodyOnlineID ~= nil and tostring(snapshot.liveBodyOnlineID) or nil
            instanceKey = snapshot.liveBodyInstanceID ~= nil and tostring(snapshot.liveBodyInstanceID) or nil
            local leaseKey = snapshot.liveBodyLease
                and (tostring(id) .. ":" .. tostring(snapshot.liveBodyLease)) or nil
            if not (leaseKey and Sync.BodyByLease[leaseKey])
                and not Sync.BodyByID[tostring(id)]
                and not (onlineID and Sync.BodyByOnlineID[onlineID])
                and not (instanceKey and Sync.BodyByInstanceID[instanceKey])
            then
                scanInterval = tonumber(Const.CLIENT_BODY_SCAN_UNRESOLVED_MS) or 200
                break
            end
        end
    end
    if now < ((tonumber(Sync.lastBodyScanAt) or 0) + scanInterval) then
        return
    end
    Sync.lastBodyScanAt = now
    indexes = Registry.CreateIndexes()
    Sync.BodyByID = indexes.byID
    Sync.BodyByOnlineID = indexes.byOnlineID
    Sync.BodyByInstanceID = indexes.byInstanceID
    Sync.BodyByLease = indexes.byLease
    cell = getCell()
    zombieList = cell and cell.getZombieList
        and cell:getZombieList() or nil
    Registry.Populate(
        indexes,
        zombieList,
        Network and Network.GetZombieOnlineID or nil
    )
end

Internal.RefreshBodyMap = refreshBodyMap
Internal.ResolveSnapshotBody = function(snapshot)
    return Registry.ResolveSnapshotBody(Sync, snapshot)
end
Internal.PruneSnapshotDuplicates = Cleanup.PruneSnapshotDuplicates
Sync.RemoveBodyInstance = Cleanup.RemoveBodyInstance
