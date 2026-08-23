PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local Registry = PNC.Registry
local Relationships = PNC.Relationships

function Internal.IsRecordEnemy(source, target)
    return Relationships and Relationships.AreNPCsEnemies
        and Relationships.AreNPCsEnemies(source, target)
        or false
end

function Perception.CanSeeWorldObject(record, targetObject)
    local observer
    local cell
    local result
    local resultName
    local runtime
    local cache
    local bucket
    local cached
    local visible
    if not record or not targetObject then
        return false
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    bucket = math.floor(Core.Now() / 100)
    cache = runtime.perceptionVisibilityCache
    if not cache or cache.bucket ~= bucket then
        cache = { bucket = bucket, values = {} }
        runtime.perceptionVisibilityCache = cache
    end
    cached = cache.values[targetObject]
    if cached ~= nil then
        return cached == "clear" or cached == "clearthroughopendoor" or cached == "clearthroughwindow", cached
    end
    observer = Registry and Registry.GetLiveZombie and Registry.GetLiveZombie(record.id) or nil
    if not observer or (observer.isDead and observer:isDead()) then
        return false
    end
    if math.abs(observer:getZ() - targetObject:getZ()) >= 1 then
        return false
    end
    cell = getCell and getCell() or nil
    if not cell or not LosUtil or not LosUtil.lineClear then
        return false
    end
    result = LosUtil.lineClear(
        cell,
        math.floor(observer:getX()),
        math.floor(observer:getY()),
        math.floor(observer:getZ()),
        math.floor(targetObject:getX()),
        math.floor(targetObject:getY()),
        math.floor(targetObject:getZ()),
        false
    )
    resultName = string.lower(tostring(result or ""))
    visible = resultName == "clear"
        or resultName == "clearthroughopendoor"
        or resultName == "clearthroughwindow"
    cache.values[targetObject] = resultName
    return visible == true, resultName
end

function Internal.BuildZombieTarget(
    record,
    zombie,
    distSq,
    visibilityKind,
    knownZombieId
)
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    local zombieId = knownZombieId
        or (modData and modData.PNC_ZombieID or nil)
    if not zombieId and Spatial and Spatial.GetZombieID then
        zombieId = Spatial.GetZombieID(zombie)
    end
    if not zombieId then
        return nil
    end
    local target = {
        kind = "zombie",
        zombie = zombie,
        zombieId = zombieId,
        x = zombie:getX(),
        y = zombie:getY(),
        z = zombie:getZ(),
        distSq = distSq,
        visible = true,
        visibilityKind = visibilityKind or "clear",
        lastSeenAt = Core.Now(),
    }
    target.threatening = Perception.IsTargetThreatening(record, target)
    target.zombie = nil
    return target
end

function Internal.CollectEnemyZombies(record, radius)
    local zombies
    local results = {}
    local i
    local zombie
    local distSq
    local visible
    local visibilityKind
    if not record or not Spatial or not Spatial.QueryZombies then
        return results
    end
    radius = tonumber(radius) or Const.ZOMBIE_TARGET_RADIUS
    if Perception.GetVisibleZombieEntries then
        return Perception.GetVisibleZombieEntries(record, radius)
    end
    zombies = Spatial.QueryZombies(record.x, record.y, radius)
    for i = 1, #zombies do
        zombie = zombies[i]
        if zombie and (not zombie:isDead()) and (not Core.IsManagedNPCBody(zombie)) and math.abs(zombie:getZ() - record.z) < 1 then
            distSq = Core.DistanceSq(record.x, record.y, zombie:getX(), zombie:getY())
            visible, visibilityKind = Perception.CanSeeWorldObject(record, zombie)
            if distSq <= (radius * radius) and visible then
                results[#results + 1] = {
                    zombie = zombie,
                    distSq = distSq,
                    visibilityKind = visibilityKind,
                }
            end
        end
    end
    return results
end
