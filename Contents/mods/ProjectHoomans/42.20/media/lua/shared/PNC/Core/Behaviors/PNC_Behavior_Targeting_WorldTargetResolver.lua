-- World-target kind resolvers used by the public targeting refresh API.

PNC = PNC or {}
PNC.BehaviorTargeting = PNC.BehaviorTargeting or {}

local Targeting = PNC.BehaviorTargeting
local H = Targeting.Internal and Targeting.Internal.WorldTargetResolver
if type(H) ~= "table" then
    return Targeting
end

local Core = H.Core
local Const = H.Const
local Registry = H.Registry
local Perception = H.Perception
local CompatibilityAPI = H.CompatibilityAPI

local function resolveVisibility(record, worldObject)
    if worldObject and Perception.CanSeeWorldObject then
        return Perception.CanSeeWorldObject(record, worldObject)
    end
    return false, nil
end

local function markVisible(
    record,
    target,
    x,
    y,
    z,
    visibilityKind,
    now,
    threatening
)
    target.x = x
    target.y = y
    target.z = z
    target.distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
    target.visible = true
    target.visibilityKind = visibilityKind
    target.lastSeenAt = now
    target.alertOnly = nil
    target.threatening = threatening
    return target
end

local function retainMemory(record, target)
    target.visible = false
    target.distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
    return target
end

local function resolveNpc(record, target, now, memoryUntil)
    local targetRecord = Registry.Get(target.id)
    local targetZombie = targetRecord
        and Registry.GetLiveZombie(target.id)
        or nil
    local visible, visibilityKind = resolveVisibility(record, targetZombie)
    if targetRecord and targetRecord.alive ~= false and targetZombie
        and visible
    then
        return markVisible(
            record,
            target,
            targetRecord.x,
            targetRecord.y,
            targetRecord.z,
            visibilityKind,
            now,
            Perception.IsTargetThreatening
                and Perception.IsTargetThreatening(record, target)
                or false
        )
    end
    if targetRecord and targetRecord.alive ~= false and now < memoryUntil then
        return retainMemory(record, target)
    end
    return nil
end

local function resolvePlayer(record, target, now, memoryUntil)
    local player = Core.ResolvePlayerByOnlineID(target.onlineID)
        or Core.ResolvePlayerByUsername(target.username)
    local visible, visibilityKind = resolveVisibility(record, player)
    if player and visible then
        target.player = player
        return markVisible(
            record,
            target,
            player:getX(),
            player:getY(),
            player:getZ(),
            visibilityKind,
            now,
            Perception.IsTargetThreatening
                and Perception.IsTargetThreatening(record, target)
                or false
        )
    end
    if player and now < memoryUntil then
        return retainMemory(record, target)
    end
    return nil
end

local function resolveZombie(record, target, now, memoryUntil)
    local zombie = Perception.FindZombieByID
        and Perception.FindZombieByID(target.zombieId)
        or nil
    local visible, visibilityKind = resolveVisibility(record, zombie)
    if zombie and visible then
        return markVisible(
            record,
            target,
            zombie:getX(),
            zombie:getY(),
            zombie:getZ(),
            visibilityKind,
            now,
            Perception.IsTargetThreatening
                and Perception.IsTargetThreatening(record, target)
                or false
        )
    end
    if zombie and now < memoryUntil then
        return retainMemory(record, target)
    end
    return Perception.FindNearestEnemyZombie(
        record,
        Const.ZOMBIE_TARGET_RADIUS
    )
end

local function resolveForeignNPC(record, target, now, memoryUntil)
    local resolved = target.worldObject and target
        or CompatibilityAPI
        and CompatibilityAPI.ResolveTarget
        and CompatibilityAPI.ResolveTarget(target)
        or nil
    local foreignBody = resolved and resolved.worldObject or nil
    local visible = false
    local visibilityKind = nil
    if foreignBody and foreignBody.isAlive
        and foreignBody:isAlive()
        and Perception.CanSeeWorldObject
    then
        visible, visibilityKind = Perception.CanSeeWorldObject(
            record,
            foreignBody
        )
    end
    if foreignBody and foreignBody.isAlive
        and foreignBody:isAlive() and visible
    then
        target.worldObject = foreignBody
        return markVisible(
            record,
            target,
            foreignBody:getX(),
            foreignBody:getY(),
            foreignBody:getZ(),
            visibilityKind,
            now,
            true
        )
    end
    if foreignBody and foreignBody.isAlive
        and foreignBody:isAlive() and now < memoryUntil
    then
        return retainMemory(record, target)
    end
    return nil
end

local resolvers = {
    npc = resolveNpc,
    player = resolvePlayer,
    zombie = resolveZombie,
    foreign_npc = resolveForeignNPC,
}

function H.Resolve(record, target, now, memoryUntil)
    local resolver = resolvers[target.kind]
    if resolver then
        return resolver(record, target, now, memoryUntil)
    end
    return nil
end

return Targeting
