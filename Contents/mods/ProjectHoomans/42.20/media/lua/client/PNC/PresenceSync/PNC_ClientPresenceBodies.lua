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
local Core = PNC.Core
local Const = PNC.Const
local Network = PNC.Network
local ClientState = PNC.Network.ClientState
local LiveBodyControl = PNC.LiveBodyControl
local canRequestRemoteSync = Internal.CanRequestRemoteSync

local function getBodyInstanceID(body)
    local value = body and body.getPersistentOutfitID
        and body:getPersistentOutfitID() or nil
    if value == nil then
        return nil
    end
    return tostring(value)
end

local function isNakedBody(body)
    local worn
    local visuals
    if not body or (body.isDead and body:isDead()) then
        return false
    end
    worn = body.getWornItems and body:getWornItems() or nil
    visuals = body.getItemVisuals and body:getItemVisuals() or nil
    return (not worn or not worn.size or worn:size() <= 0)
        and (not visuals or not visuals.size or visuals:size() <= 0)
end

local function removeLocalBody(body)
    if not body then
        return false
    end
    if LiveBodyControl and LiveBodyControl.EnforceManagedSafety then
        LiveBodyControl.EnforceManagedSafety(body, "client_stale_body_remove")
    end
    if body.removeFromWorld then
        body:removeFromWorld()
    end
    if body.removeFromSquare then
        body:removeFromSquare()
    end
    return true
end

local function bodyConflictsWithSnapshot(body, snapshot, id)
    local modData
    local bodyID
    local expectedLease
    local bodyLease
    if not body then
        return true
    end
    modData = body.getModData and body:getModData() or nil
    bodyID = modData and modData.PNC_UUID or nil
    if modData and modData.PNC_NPC == true
        and bodyID ~= nil
        and tostring(bodyID) ~= tostring(id)
    then
        return true
    end
    expectedLease = snapshot and snapshot.liveBodyLease or nil
    bodyLease = modData and modData.PNC_BodyLease or nil
    return expectedLease ~= nil
        and bodyLease ~= nil
        and tostring(expectedLease) ~= tostring(bodyLease)
end

local function resolveIndexedBody(index, key, snapshot, id)
    local body
    if key == nil then
        return nil
    end
    body = index and index[tostring(key)] or nil
    if body == false or bodyConflictsWithSnapshot(body, snapshot, id) then
        return nil
    end
    return body
end

local function resolveSnapshotBody(snapshot)
    local id
    local body
    if type(snapshot) ~= "table" or snapshot.id == nil then
        return nil
    end
    id = tostring(snapshot.id)
    if snapshot.liveBodyLease ~= nil then
        body = resolveIndexedBody(
            Sync.BodyByLease,
            id .. ":" .. tostring(snapshot.liveBodyLease),
            snapshot,
            id
        )
    end
    body = body or resolveIndexedBody(
        Sync.BodyByInstanceID,
        snapshot.liveBodyInstanceID,
        snapshot,
        id
    )
    body = body or resolveIndexedBody(
        Sync.BodyByID,
        id,
        snapshot,
        id
    )
    body = body or resolveIndexedBody(
        Sync.BodyByOnlineID,
        snapshot.liveBodyOnlineID,
        snapshot,
        id
    )
    return body
end

function Sync.RemoveBodyInstance(args)
    local cell
    local zombieList
    local wantedInstance
    local wantedOnline
    local wantedID
    local removed = 0
    local i
    local body
    local modData
    local onlineID
    local identityConflict
    local identifierMatch
    if type(args) ~= "table" or not getCell then
        return 0
    end
    wantedInstance = args.bodyInstanceID ~= nil
        and tostring(args.bodyInstanceID) or nil
    wantedOnline = tonumber(args.bodyOnlineID)
    wantedID = args.id ~= nil and tostring(args.id) or nil
    cell = getCell()
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if not zombieList then
        return 0
    end
    for i = zombieList:size() - 1, 0, -1 do
        body = zombieList:get(i)
        modData = body and body.getModData and body:getModData() or nil
        onlineID = Network and Network.GetZombieOnlineID
            and Network.GetZombieOnlineID(body) or nil
        identityConflict = wantedID and modData and modData.PNC_UUID
            and tostring(modData.PNC_UUID) ~= wantedID
        if wantedOnline ~= nil then
            identifierMatch = onlineID == wantedOnline
                and not identityConflict
        elseif wantedInstance then
            identifierMatch = getBodyInstanceID(body) == wantedInstance
                and not identityConflict
        else
            identifierMatch = wantedID
                and modData and tostring(modData.PNC_UUID or "") == wantedID
        end
        if identifierMatch then
            removeLocalBody(body)
            removed = removed + 1
        end
    end
    Sync.lastBodyScanAt = 0
    if removed > 0 and Core and Core.LogInfo then
        Core.LogInfo("PNC client stale body removed npc=" .. tostring(wantedID or "unknown")
            .. " bodyInstanceID=" .. tostring(wantedInstance or "nil")
            .. " reason=" .. tostring(args.reason or "server_remove"))
    end
    return removed
end

local function pruneSnapshotDuplicates(snapshot, canonicalBody)
    local id
    local revisionKey
    local cell
    local zombieList
    local i
    local body
    local modData
    local sameIdentity
    local unmarkedNaked
    local dx
    local dy
    local dz
    local removed = 0
    local now
    local pruneState
    if not canRequestRemoteSync() or not snapshot or not canonicalBody or not getCell then
        return 0
    end
    id = tostring(snapshot.id)
    now = Core.Now()
    revisionKey = table.concat({
        tostring(snapshot.presenceRevision or 0),
        tostring(snapshot.liveBodyInstanceID or ""),
        tostring(snapshot.liveBodyOnlineID or ""),
        tostring(snapshot.liveBodyLease or ""),
    }, ":")
    pruneState = Sync.PrunedRevisionByID[id]
    if pruneState and pruneState.key == revisionKey
        and now < ((tonumber(pruneState.at) or 0) + 1000)
    then
        return 0
    end
    cell = getCell()
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if not zombieList then
        return 0
    end
    for i = zombieList:size() - 1, 0, -1 do
        body = zombieList:get(i)
        if body and body ~= canonicalBody and not (body.isDead and body:isDead()) then
            modData = body.getModData and body:getModData() or nil
            sameIdentity = modData and tostring(modData.PNC_UUID or "") == id
            unmarkedNaked = not (modData and modData.PNC_UUID) and isNakedBody(body)
            if unmarkedNaked then
                dx = (tonumber(body:getX()) or 0) - (tonumber(snapshot.x) or 0)
                dy = (tonumber(body:getY()) or 0) - (tonumber(snapshot.y) or 0)
                dz = (tonumber(body:getZ()) or 0) - (tonumber(snapshot.z) or 0)
                unmarkedNaked = math.abs(dz) <= 1
                    and (dx * dx + dy * dy) <= (1.25 * 1.25)
            end
            if sameIdentity or unmarkedNaked then
                removeLocalBody(body)
                removed = removed + 1
            end
        end
    end
    Sync.PrunedRevisionByID[id] = { key = revisionKey, at = now }
    if removed > 0 and Core and Core.LogWarn then
        Core.LogWarn("PNC client duplicate shells pruned npc=" .. id
            .. " count=" .. tostring(removed)
            .. " canonical=" .. tostring(getBodyInstanceID(canonicalBody) or "nil"))
    end
    return removed
end

local function refreshBodyMap(now)
    local zombieList
    local body
    local modData
    local onlineID
    local instanceKey
    local scanInterval = tonumber(Const.CLIENT_BODY_SCAN_MS) or 750
    local i
    local id
    local snapshot
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
    Sync.BodyByID = {}
    Sync.BodyByOnlineID = {}
    Sync.BodyByInstanceID = {}
    Sync.BodyByLease = {}
    zombieList = getCell():getZombieList()
    if not zombieList then
        return
    end
    for i = 0, zombieList:size() - 1 do
        body = zombieList:get(i)
        modData = body and body.getModData and body:getModData() or nil
        if modData and modData.PNC_UUID and modData.PNC_NPC == true then
            id = tostring(modData.PNC_UUID)
            if Sync.BodyByID[id] ~= nil and Sync.BodyByID[id] ~= body then
                Sync.BodyByID[id] = false
            elseif Sync.BodyByID[id] == nil then
                Sync.BodyByID[id] = body
            end
            if modData.PNC_BodyLease then
                instanceKey = id .. ":" .. tostring(modData.PNC_BodyLease)
                if Sync.BodyByLease[instanceKey] ~= nil and Sync.BodyByLease[instanceKey] ~= body then
                    Sync.BodyByLease[instanceKey] = false
                elseif Sync.BodyByLease[instanceKey] == nil then
                    Sync.BodyByLease[instanceKey] = body
                end
            end
        end
        onlineID = Network and Network.GetZombieOnlineID and Network.GetZombieOnlineID(body) or nil
        if onlineID ~= nil then
            onlineID = tostring(onlineID)
            if Sync.BodyByOnlineID[onlineID] ~= nil
                and Sync.BodyByOnlineID[onlineID] ~= body
            then
                Sync.BodyByOnlineID[onlineID] = false
            elseif Sync.BodyByOnlineID[onlineID] == nil then
                Sync.BodyByOnlineID[onlineID] = body
            end
        end
        if body and body.getPersistentOutfitID then
            instanceKey = tostring(body:getPersistentOutfitID() or "")
            if instanceKey ~= "" and instanceKey ~= "0" and instanceKey ~= "-1" then
                if Sync.BodyByInstanceID[instanceKey] ~= nil and Sync.BodyByInstanceID[instanceKey] ~= body then
                    Sync.BodyByInstanceID[instanceKey] = false
                elseif Sync.BodyByInstanceID[instanceKey] == nil then
                    Sync.BodyByInstanceID[instanceKey] = body
                end
            end
        end
    end
end

Internal.RefreshBodyMap = refreshBodyMap
Internal.ResolveSnapshotBody = resolveSnapshotBody
Internal.PruneSnapshotDuplicates = pruneSnapshotDuplicates
