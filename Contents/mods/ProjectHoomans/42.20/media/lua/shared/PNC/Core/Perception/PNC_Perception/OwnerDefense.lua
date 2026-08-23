PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex

function Internal.GetCompanionDefenseRadius()
    return math.max(8, tonumber(Const.ZOMBIE_TARGET_RADIUS) or 12)
end

local function ownerThreatCacheKey(owner)
    local onlineID = owner and owner.getOnlineID
        and owner:getOnlineID() or nil
    local username = owner and owner.getUsername
        and owner:getUsername() or nil
    if onlineID ~= nil and (tonumber(onlineID) or -1) >= 0 then
        return "id:" .. tostring(onlineID)
    end
    if username and tostring(username) ~= "" then
        return "user:" .. tostring(username)
    end
    return tostring(owner)
end

local function buildOwnerThreatTarget(record, owner, zombie)
    local engineTarget
    local candidate
    if not zombie or zombie:isDead()
        or Core.IsManagedNPCBody(zombie)
        or math.abs(zombie:getZ() - owner:getZ()) >= 1
        or not zombie.getTarget
    then
        return nil
    end
    engineTarget = zombie:getTarget()
    if engineTarget ~= owner then
        return nil
    end
    candidate = Internal.BuildZombieTarget(
        record,
        zombie,
        Core.DistanceSq(
            record.x,
            record.y,
            zombie:getX(),
            zombie:getY()
        ),
        "owner_under_attack"
    )
    if candidate then
        candidate.threatening = true
        candidate.defendingOwner = true
    end
    return candidate
end

function Internal.FindZombieTargetingOwner(record, owner, radius)
    local zombies
    local bestZombie
    local bestOwnerDistSq
    local radiusSq
    local i
    local zombie
    local engineTarget
    local ownerDistSq
    local now
    local cacheKey
    local cached
    if not record or not owner or not Spatial or not Spatial.QueryZombies then
        return nil
    end
    now = Core.Now()
    cacheKey = ownerThreatCacheKey(owner)
    cached = Perception.OwnerThreatCache[cacheKey]
    if cached and now < (tonumber(cached.expiresAt) or 0) then
        if cached.zombie == false then
            return nil
        end
        local cachedTarget = buildOwnerThreatTarget(
            record,
            owner,
            cached.zombie
        )
        if cachedTarget then
            return cachedTarget
        end
    end
    radius = math.max(1, tonumber(radius) or Internal.GetCompanionDefenseRadius())
    radiusSq = radius * radius
    zombies = Spatial.QueryZombies(owner:getX(), owner:getY(), radius)
    bestOwnerDistSq = math.huge
    for i = 1, #zombies do
        zombie = zombies[i]
        if zombie and not zombie:isDead()
            and not Core.IsManagedNPCBody(zombie)
            and math.abs(zombie:getZ() - owner:getZ()) < 1
            and zombie.getTarget
        then
            engineTarget = zombie:getTarget()
            if engineTarget == owner then
                ownerDistSq = Core.DistanceSq(
                    owner:getX(),
                    owner:getY(),
                    zombie:getX(),
                    zombie:getY()
                )
                if ownerDistSq <= radiusSq
                    and ownerDistSq < bestOwnerDistSq
                then
                    bestZombie = zombie
                    bestOwnerDistSq = ownerDistSq
                end
            end
        end
    end
    Perception.OwnerThreatCache[cacheKey] = {
        zombie = bestZombie or false,
        expiresAt = now + (
            tonumber(Const.COMPANION_OWNER_THREAT_CACHE_MS) or 100
        ),
    }
    return buildOwnerThreatTarget(record, owner, bestZombie)
end

function Perception.FindOwnerThreateningZombie(record, owner, radius)
    return Internal.FindZombieTargetingOwner(record, owner, radius)
end
