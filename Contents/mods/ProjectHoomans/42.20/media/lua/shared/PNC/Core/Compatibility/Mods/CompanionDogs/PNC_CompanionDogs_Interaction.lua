-- Companion Dogs compatibility: bounded NPC/dog interaction scheduler.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.CompanionDogs or {}
local Internal = Bridge.Internal or {}
Bridge.Internal = Internal
PNC.Compatibility.CompanionDogs = Bridge

local function refreshDogCache(current, force)
    local cd = Internal.CompanionDogs()
    local ok
    local dogs
    if not force and Bridge._dogCache
        and current < (tonumber(Bridge._dogCacheExpiresAt) or 0)
    then
        return Bridge._dogCache
    end
    if not cd then return nil end
    if type(cd.regCompanions) == "function" then
        ok, dogs = Internal.SafeCall(cd.regCompanions)
    elseif type(cd.regDogs) == "function" then
        ok, dogs = Internal.SafeCall(cd.regDogs)
    else
        return nil
    end
    if not ok or type(dogs) ~= "table" then return nil end
    Bridge._dogCache = dogs
    Bridge._dogCacheExpiresAt = current + Bridge.DOG_CACHE_INTERVAL_MS
    return dogs
end

local function nearestDog(record, body, dogs)
    local nearest
    local nearestDistance
    local dog
    local distance
    local dx
    local dy
    local bodyX
    local bodyY
    if type(dogs) ~= "table" or type(body.getX) ~= "function"
        or type(body.getY) ~= "function"
    then
        return nil
    end
    bodyX = body:getX()
    bodyY = body:getY()
    for index = 1, #dogs do
        dog = dogs[index]
        if Bridge.IsDogEligible(dog)
            and Internal.Near(body, dog, Bridge.INTERACTION_RADIUS)
        then
            dx = bodyX - dog:getX()
            dy = bodyY - dog:getY()
            distance = dx * dx + dy * dy
            if nearestDistance == nil or distance < nearestDistance then
                nearest = dog
                nearestDistance = distance
            end
        end
    end
    -- LOS is the expensive part. Test it once, after cheap distance filtering,
    -- instead of once for every dog candidate and every NPC.
    if nearest and not Internal.VisibleToNPC(record, nearest) then
        return nil
    end
    return nearest
end

local function processRecord(record, body, npcID, dogs, current)
    local dog
    local dogKey
    local key
    local last
    local fed = false
    local flavorID
    local eventID
    local sent
    if not record or not body or (body.isDead and body:isDead()) then
        return false
    end
    if Internal.NPCIsBusy(record) then return false end
    dog = nearestDog(record, body, dogs)
    if not dog then return false end
    dogKey = Bridge.GetDogKey(dog)
    if not dogKey then return false end
    key = Internal.PairKey(npcID, dogKey)
    last = tonumber(Bridge._lastInteractionAt[key])
    if last and current - last < Bridge.INTERACTION_COOLDOWN_MS then
        return false
    end
    -- Do not spend inventory-query work when nobody can see the interaction.
    if not Internal.HasNearbyPlayer(body, dog) then return false end
    if Bridge.IsDogHungry(dog) and Bridge.IsNPCNotHungry(record)
        and Bridge.RollFeedChance()
    then
        fed = Bridge.FeedDog(record, body, dog) == true
    end
    flavorID = Bridge.GetFlavorID(dog, fed)
    Bridge._eventSerial = Bridge._eventSerial + 1
    eventID = "companion_dog:" .. tostring(npcID) .. ":"
        .. tostring(dogKey) .. ":" .. tostring(Bridge._eventSerial)
    sent = Internal.SendFlavorToNearbyPlayers(body, dog, npcID, dogKey,
        flavorID, eventID, Bridge.GetDogSex(dog), fed)
    if sent <= 0 then
        -- A missing client route must be retried, not hidden behind the normal
        -- 120-second pair cooldown. This is the former flavor-text failure.
        Bridge._nextInteractionAt = current + Bridge.INTERACTION_RETRY_INTERVAL_MS
        return false
    end
    Internal.Bark(dog)
    Bridge._lastInteractionAt[key] = current
    return true
end

local function pumpLiveTable(registry, dogs, current)
    local processed = 0
    local interactions = 0
    local live = registry.LiveByID
    local get = registry.Get
    local npcID
    local body
    local record
    if type(live) ~= "table" or type(get) ~= "function" then
        return nil
    end
    for npcID, body in pairs(live) do
        if processed >= Bridge.MAX_NPCS_PER_PUMP then break end
        processed = processed + 1
        record = get(npcID)
        if processRecord(record, body, npcID, dogs, current) then
            interactions = interactions + 1
            if interactions >= Bridge.MAX_INTERACTIONS_PER_PUMP then break end
        end
    end
    return interactions
end

local function pumpCallback(registry, dogs, current)
    local interactions = 0
    local examined = 0
    registry.ForEachLive(function(record, body, npcID)
        if examined >= Bridge.MAX_NPCS_PER_PUMP
            or interactions >= Bridge.MAX_INTERACTIONS_PER_PUMP
        then
            return
        end
        examined = examined + 1
        if processRecord(record, body, npcID, dogs, current) then
            interactions = interactions + 1
        end
    end)
    return interactions
end

function Bridge.Pump(force)
    local cd = Internal.CompanionDogs()
    local registry = PNC.Registry
    local current
    local dogs
    local interactions
    if not Internal.IsAuthority() or not cd or not registry then return 0 end
    if type(registry.Get) ~= "function"
        and type(registry.ForEachLive) ~= "function"
    then
        return 0
    end
    current = Internal.Now()
    if not force and current < (tonumber(Bridge._nextInteractionAt) or 0) then
        return 0
    end
    Bridge._nextInteractionAt = current + Bridge.INTERACTION_INTERVAL_MS
    Bridge.RegisterFlavors()
    dogs = refreshDogCache(current, false)
    if not dogs then return 0 end
    interactions = pumpLiveTable(registry, dogs, current)
    if interactions == nil and type(registry.ForEachLive) == "function" then
        interactions = pumpCallback(registry, dogs, current)
    end
    return interactions or 0
end

Internal.RefreshDogCache = refreshDogCache
Internal.NearestDog = nearestDog

return Bridge
