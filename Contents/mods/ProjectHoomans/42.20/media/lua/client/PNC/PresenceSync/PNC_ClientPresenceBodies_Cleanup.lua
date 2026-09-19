-- Client-side side effects for server-directed removals and duplicate shells.

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Cleanup = {}
local Sync = PNC.ClientPresenceSync
local Core = PNC.Core
local Network = PNC.Network
local LiveBodyControl = PNC.LiveBodyControl
local canRequestRemoteSync = Sync.Internal.CanRequestRemoteSync

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

function Cleanup.RemoveBodyInstance(args)
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

function Cleanup.PruneSnapshotDuplicates(snapshot, canonicalBody)
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
    if not canRequestRemoteSync()
        or not snapshot or not canonicalBody or not getCell
    then
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
        if body and body ~= canonicalBody
            and not (body.isDead and body:isDead())
        then
            modData = body.getModData and body:getModData() or nil
            sameIdentity = modData
                and tostring(modData.PNC_UUID or "") == id
            unmarkedNaked = not (modData and modData.PNC_UUID)
                and isNakedBody(body)
            if unmarkedNaked then
                dx = (tonumber(body:getX()) or 0)
                    - (tonumber(snapshot.x) or 0)
                dy = (tonumber(body:getY()) or 0)
                    - (tonumber(snapshot.y) or 0)
                dz = (tonumber(body:getZ()) or 0)
                    - (tonumber(snapshot.z) or 0)
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

return Cleanup
