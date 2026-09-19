-- Builds the client body identity indexes from one local zombie-list scan.
-- The returned maps contain engine body references only for this local
-- registry snapshot; duplicate keys use false to remain explicitly ambiguous.

local Registry = {}

local function bindUnique(index, key, body)
    if index[key] ~= nil and index[key] ~= body then
        index[key] = false
    elseif index[key] == nil then
        index[key] = body
    end
end

function Registry.CreateIndexes()
    return {
        byID = {},
        byOnlineID = {},
        byInstanceID = {},
        byLease = {},
    }
end

function Registry.Populate(indexes, zombieList, getOnlineID)
    local body
    local modData
    local id
    local onlineID
    local instanceKey
    local i

    if not indexes or not zombieList then return end

    for i = 0, zombieList:size() - 1 do
        body = zombieList:get(i)
        modData = body and body.getModData
            and body:getModData() or nil
        if modData and modData.PNC_UUID and modData.PNC_NPC == true then
            id = tostring(modData.PNC_UUID)
            bindUnique(indexes.byID, id, body)
            if modData.PNC_BodyLease then
                bindUnique(
                    indexes.byLease,
                    id .. ":" .. tostring(modData.PNC_BodyLease),
                    body
                )
            end
        end

        onlineID = body and getOnlineID and getOnlineID(body) or nil
        if onlineID ~= nil then
            bindUnique(indexes.byOnlineID, tostring(onlineID), body)
        end

        if body and body.getPersistentOutfitID then
            instanceKey = tostring(body:getPersistentOutfitID() or "")
            if instanceKey ~= "" and instanceKey ~= "0"
                and instanceKey ~= "-1"
            then
                bindUnique(indexes.byInstanceID, instanceKey, body)
            end
        end
    end

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

function Registry.ResolveSnapshotBody(indexes, snapshot)
    local id
    local body
    if type(snapshot) ~= "table" or snapshot.id == nil then
        return nil
    end
    id = tostring(snapshot.id)
    if snapshot.liveBodyLease ~= nil then
        body = resolveIndexedBody(
            indexes.BodyByLease,
            id .. ":" .. tostring(snapshot.liveBodyLease),
            snapshot,
            id
        )
    end
    body = body or resolveIndexedBody(
        indexes.BodyByInstanceID,
        snapshot.liveBodyInstanceID,
        snapshot,
        id
    )
    body = body or resolveIndexedBody(
        indexes.BodyByID,
        id,
        snapshot,
        id
    )
    body = body or resolveIndexedBody(
        indexes.BodyByOnlineID,
        snapshot.liveBodyOnlineID,
        snapshot,
        id
    )
    return body
end

function Registry.ResolveForNPC(indexes, id, snapshot, snapshots)
    local requestedID = tostring(id or "")
    local current = snapshot
    local copy
    if requestedID == "" then return nil end
    if type(current) ~= "table" then
        current = snapshots and snapshots[requestedID] or nil
    end
    if type(current) ~= "table" then
        current = { id = requestedID }
    elseif current.id == nil then
        copy = { id = requestedID }
        for key, value in pairs(current) do copy[key] = value end
        current = copy
    elseif tostring(current.id) ~= requestedID then
        return nil
    end
    return Registry.ResolveSnapshotBody(indexes, current)
end

return Registry
