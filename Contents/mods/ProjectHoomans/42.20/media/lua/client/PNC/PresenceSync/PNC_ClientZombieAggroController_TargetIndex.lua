-- Local NPC target index for the singleplayer zombie pursuit fallback.
-- This cache is client-local; multiplayer target choice remains server-owned.

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}

local Sync = PNC.ClientPresenceSync
local ClientState = PNC.Network and PNC.Network.ClientState or nil
local Const = PNC.Const or {}

local AGGRO_RADIUS = tonumber(Const.ZOMBIE_AGGRO_RADIUS) or 12
local INDEX_REFRESH_MS = math.max(
    250,
    tonumber(Const.CLIENT_BODY_SCAN_MS) or 750
)
local INDEX_CELL_SIZE = math.max(
    2,
    tonumber(Const.CLIENT_ZOMBIE_AGGRO_CELL_SIZE) or 8
)
local NPC_BODY_INDEX = {
    initialized = false,
    builtAt = 0,
    buckets = {},
}

local TargetIndex = {}

local function snapshotFor(id)
    return ClientState
        and ClientState.snapshots
        and ClientState.snapshots[tostring(id)]
        or nil
end

local function isTargetable(snapshot, body)
    local modData
    if not body or (body.isDead and body:isDead()) then
        return false
    end
    if snapshot then
        return snapshot.presenceState == Const.PRESENCE_LIVE
            and snapshot.alive ~= false
            and snapshot.zombieTargetable == true
    end
    modData = body.getModData and body:getModData() or nil
    return modData
        and modData.PNC_NPC == true
        and modData.PNC_UUID ~= nil
        and tostring(modData.PNC_BodyKind or "live") ~= "corpse"
        or false
end

local function cellCoordinate(value)
    return math.floor((tonumber(value) or 0) / INDEX_CELL_SIZE)
end

local function bucketKey(cellX, cellY, z)
    return tostring(cellX)
        .. ":" .. tostring(cellY)
        .. ":" .. tostring(math.floor(tonumber(z) or 0))
end

local function rebuildNPCBodyIndex(now)
    local buckets = {}
    local seenBodies = {}
    local id
    local snapshot
    local body
    local key
    local bucket
    local foundBody = false
    local bodyByID = Sync.BodyByID or {}
    local ambiguousIDs = {}

    for candidateID, candidate in pairs(bodyByID) do
        if candidate == false then
            ambiguousIDs[tostring(candidateID)] = true
        end
    end

    local function addBody(candidate, candidateID, candidateSnapshot,
        fromBodyMap)
        if not candidate or seenBodies[candidate]
            or not isTargetable(candidateSnapshot, candidate)
        then
            return
        end
        seenBodies[candidate] = true
        key = bucketKey(
            cellCoordinate(candidate:getX()),
            cellCoordinate(candidate:getY()),
            candidate:getZ()
        )
        bucket = buckets[key]
        if not bucket then
            bucket = {}
            buckets[key] = bucket
        end
        bucket[#bucket + 1] = {
            id = candidateID,
            body = candidate,
            fromBodyMap = fromBodyMap == true,
        }
        foundBody = true
    end

    -- The shared body map tracks current local shells, including bodies whose
    -- roster entry is not detailed for this client.
    for id, body in pairs(bodyByID) do
        snapshot = snapshotFor(id)
        addBody(body, id, snapshot, true)
    end

    -- Cover the short window before the shared body map sees a newly streamed
    -- shell. This fallback is bounded by the index refresh interval.
    if not foundBody and getCell then
        local cell = getCell()
        local zombieList = cell and cell.getZombieList
            and cell:getZombieList() or nil
        local index
        if zombieList then
            for index = 0, zombieList:size() - 1 do
                body = zombieList:get(index)
                local modData = body and body.getModData
                    and body:getModData() or nil
                id = modData and modData.PNC_UUID or nil
                snapshot = id and snapshotFor(id) or nil
                if id == nil or not ambiguousIDs[tostring(id)] then
                    addBody(body, id, snapshot, false)
                end
            end
        end
    end
    NPC_BODY_INDEX.buckets = buckets
    NPC_BODY_INDEX.builtAt = now
    NPC_BODY_INDEX.initialized = true
end

local function ensureNPCBodyIndex(now)
    if not NPC_BODY_INDEX.initialized
        or now - NPC_BODY_INDEX.builtAt >= INDEX_REFRESH_MS
    then
        rebuildNPCBodyIndex(now)
    end
end

function TargetIndex.FindNearestBody(zombie, now)
    local bestBody
    local bestDistanceSq = AGGRO_RADIUS * AGGRO_RADIUS
    local radiusCells = math.ceil(AGGRO_RADIUS / INDEX_CELL_SIZE)
    local centerX
    local centerY
    local centerZ
    local offsetX
    local offsetY
    local offsetZ
    local bucket
    local entry
    local index
    local snapshot
    local dx
    local dy
    local distanceSq
    local bodyByID
    if not zombie or not zombie.getX or not zombie.getY or not zombie.getZ then
        return nil, bestDistanceSq
    end
    now = tonumber(now) or 0
    centerX = cellCoordinate(zombie:getX())
    centerY = cellCoordinate(zombie:getY())
    centerZ = math.floor(tonumber(zombie:getZ()) or 0)
    ensureNPCBodyIndex(now)
    bodyByID = Sync.BodyByID or {}
    for offsetZ = -1, 1 do
        for offsetX = -radiusCells, radiusCells do
            for offsetY = -radiusCells, radiusCells do
                bucket = NPC_BODY_INDEX.buckets[bucketKey(
                    centerX + offsetX,
                    centerY + offsetY,
                    centerZ + offsetZ
                )]
                if bucket then
                    for index = 1, #bucket do
                        entry = bucket[index]
                        snapshot = snapshotFor(entry.id)
                        if (not entry.fromBodyMap
                            or bodyByID[tostring(entry.id)] == entry.body)
                            and isTargetable(snapshot, entry.body)
                            and math.abs(
                                entry.body:getZ() - zombie:getZ()
                            ) < 1
                        then
                            dx = entry.body:getX() - zombie:getX()
                            dy = entry.body:getY() - zombie:getY()
                            distanceSq = (dx * dx) + (dy * dy)
                            if distanceSq < bestDistanceSq then
                                bestBody = entry.body
                                bestDistanceSq = distanceSq
                            end
                        end
                    end
                end
            end
        end
    end
    return bestBody, bestDistanceSq
end

function TargetIndex.Reset()
    NPC_BODY_INDEX.initialized = false
    NPC_BODY_INDEX.builtAt = 0
    NPC_BODY_INDEX.buckets = {}
end

return TargetIndex
