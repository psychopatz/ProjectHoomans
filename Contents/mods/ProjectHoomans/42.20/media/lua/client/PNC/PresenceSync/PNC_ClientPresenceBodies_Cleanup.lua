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

local function normalizeBodyInstanceID(value)
    local normalized
    if value == nil then
        return nil
    end
    normalized = tostring(value)
    if normalized == "" or normalized == "0" then
        return nil
    end
    return normalized
end

local function getBodyInstanceID(body)
    local value = body and body.getPersistentOutfitID
        and body:getPersistentOutfitID() or nil
    if value == nil then
        return nil
    end
    return tostring(value)
end

local function isProtectedBody(body)
    local ownership
    local ok
    local value
    local modData
    if not body then
        return false
    end
    if body.isDead then
        ok, value = pcall(body.isDead, body)
        if ok and value == true then
            return true
        end
    end
    if body.isReanimatedPlayer then
        ok, value = pcall(body.isReanimatedPlayer, body)
        if ok and value == true then
            return true
        end
    end
    ownership = PNC.Compatibility and PNC.Compatibility.ActorOwnership
    if ownership and ownership.IsForeignOwned then
        ok, value = pcall(ownership.IsForeignOwned, body)
        if ok and value == true then
            return true
        end
    end
    modData = body.getModData and body:getModData() or nil
    return modData ~= nil
        and modData.PNC_Owner ~= nil
        and tostring(modData.PNC_Owner) ~= "ProjectHoomans"
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
    wantedInstance = normalizeBodyInstanceID(args.bodyInstanceID)
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
        if identifierMatch and not isProtectedBody(body) then
            -- In multiplayer the server-assigned online zombie ID is an exact
            -- live-object identity. A restored husk can lose all PNC ModData
            -- before the removal packet reaches a client, so an exact online
            -- ID must remain sufficient to remove that anonymous replica.
            --
            -- Persistent outfit IDs are not unique actor identities. Keep
            -- those removals gated by the PNC UUID to avoid deleting an
            -- ordinary zombie that happens to reuse an outfit/carrier ID.
            if wantedOnline == nil
                and (
                    not wantedID
                    or not (modData and tostring(modData.PNC_UUID or "")
                        == wantedID)
                )
            then
                identifierMatch = false
            end
        else
            identifierMatch = false
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
            .. " count=" .. tostring(removed)
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
            if sameIdentity and not isProtectedBody(body)
                and (modData.PNC_Owner == nil
                    or tostring(modData.PNC_Owner) == "ProjectHoomans")
            then
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
