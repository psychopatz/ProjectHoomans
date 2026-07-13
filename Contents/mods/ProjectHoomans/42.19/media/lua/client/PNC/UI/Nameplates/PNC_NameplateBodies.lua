PNC = PNC or {}
PNC.NameplateBodies = PNC.NameplateBodies or {}

local Bodies = PNC.NameplateBodies
local Const = PNC.Const

local function addUnique(index, key, body)
    if key == nil then return end
    key = tostring(key)
    if index[key] ~= nil and index[key] ~= body then
        index[key] = false
    elseif index[key] == nil then
        index[key] = body
    end
end

function Bodies.Index(zombieList)
    local index = {
        byID = {},
        byLease = {},
        byOnlineID = {},
        byInstanceID = {},
    }
    if not zombieList then return index end

    for i = 0, zombieList:size() - 1 do
        local zombie = zombieList:get(i)
        if zombie and not zombie:isDead() and zombie.getModData then
            local modData = zombie:getModData()
            local uuid = modData and modData.PNC_UUID or nil
            if uuid then
                uuid = tostring(uuid)
                addUnique(index.byID, uuid, zombie)
                if modData.PNC_BodyLease then
                    addUnique(index.byLease, uuid .. ":" .. tostring(modData.PNC_BodyLease), zombie)
                end
            end
            local onlineID = PNC.Network and PNC.Network.GetZombieOnlineID
                and PNC.Network.GetZombieOnlineID(zombie) or nil
            if onlineID ~= nil then
                index.byOnlineID[tostring(onlineID)] = zombie
            end
            local instanceID = zombie.getPersistentOutfitID and zombie:getPersistentOutfitID() or nil
            addUnique(index.byInstanceID, instanceID, zombie)
        end
    end
    return index
end

function Bodies.Resolve(index, uuid, snapshot)
    if not index or not snapshot then return nil end
    local body = index.byOnlineID[tostring(snapshot.liveBodyOnlineID or "")]
    if not body and snapshot.liveBodyLease then
        body = index.byLease[tostring(uuid) .. ":" .. tostring(snapshot.liveBodyLease)]
    end
    if not body and not snapshot.liveBodyLease then
        body = index.byID[tostring(uuid)]
    end
    return body or index.byInstanceID[tostring(snapshot.liveBodyInstanceID or "")]
end

function Bodies.Tag(zombie, uuid, snapshot)
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    if not modData then return end
    modData.PNC_UUID = tostring(uuid)
    modData.PNC_NPC = true
    modData.PNC_LiveBodyInstanceID = snapshot.liveBodyInstanceID
    modData.PNC_LiveBodyOnlineID = snapshot.liveBodyOnlineID
    modData.PNC_BodyKind = "live"
    modData.PNC_BodyLease = snapshot.liveBodyLease
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
end

return Bodies
