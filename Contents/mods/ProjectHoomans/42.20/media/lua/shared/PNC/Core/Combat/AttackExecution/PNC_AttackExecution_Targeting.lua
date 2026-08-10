-- Target snapshots, re-resolution, visibility, and committed melee range checks.

local Combat = PNC.Combat
local Internal = Combat.Internal
local AttackExecution = Internal.AttackExecution
local Core = PNC.Core
local Const = PNC.Const or {}
local Registry = PNC.Registry
local Perception = PNC.Perception

function AttackExecution.captureTargetRef(target)
    local worldObject
    if not target then
        return nil
    end
    if target.kind == "zombie" and target.zombieId and Perception and Perception.FindZombieByID then
        worldObject = Perception.FindZombieByID(target.zombieId)
    elseif target.kind == "player" then
        worldObject = target.player
    end
    return {
        kind = target.kind,
        id = target.id,
        onlineID = target.onlineID,
        username = target.username,
        zombieId = target.zombieId,
        x = target.x,
        y = target.y,
        z = target.z,
        -- Runtime-only identity anchor. The stable ID remains authoritative
        -- across index rebuilds; this direct reference closes the short gap
        -- between attack commit and the delayed hit frame.
        worldObject = worldObject,
    }
end

function AttackExecution.resolveActionTarget(targetRef)
    local targetRecord
    local player
    local zombieTarget
    if not targetRef then
        return nil
    end
    if targetRef.kind == "player" then
        player = Core.ResolvePlayerByOnlineID(targetRef.onlineID) or Core.ResolvePlayerByUsername(targetRef.username)
        if not player then
            return nil
        end
        return {
            kind = "player",
            player = player,
            x = player:getX(),
            y = player:getY(),
            z = player:getZ(),
            distSq = 0,
        }
    end
    if targetRef.kind == "npc" then
        targetRecord = Registry.Get(targetRef.id)
        if not targetRecord or targetRecord.alive == false then
            return nil
        end
        return {
            kind = "npc",
            id = targetRecord.id,
            x = targetRecord.x,
            y = targetRecord.y,
            z = targetRecord.z,
            distSq = 0,
        }
    end
    if targetRef.kind == "zombie" then
        zombieTarget = targetRef.worldObject
        if zombieTarget and zombieTarget.isDead and zombieTarget:isDead() then
            zombieTarget = nil
        end
        if not zombieTarget then
            zombieTarget = Perception.FindZombieByID and Perception.FindZombieByID(targetRef.zombieId) or nil
        end
        if not zombieTarget or zombieTarget:isDead() then
            return nil
        end
        return {
            kind = "zombie",
            zombieId = targetRef.zombieId,
            worldObject = zombieTarget,
            x = zombieTarget:getX(),
            y = zombieTarget:getY(),
            z = zombieTarget:getZ(),
            distSq = 0,
        }
    end
    return nil
end

function AttackExecution.isActionTargetVisible(record, target)
    local worldObject
    local visible
    local visibilityKind
    if not target or not Perception or not Perception.CanSeeWorldObject then
        return false
    end
    if target.kind == "player" then
        worldObject = target.player
    elseif target.kind == "npc" then
        worldObject = Registry.GetLiveZombie(target.id)
    elseif target.kind == "zombie" then
        worldObject = target.worldObject or Perception.FindZombieByID and Perception.FindZombieByID(target.zombieId) or nil
    end
    if not worldObject then
        return false
    end
    visible, visibilityKind = Perception.CanSeeWorldObject(record, worldObject)
    return visible == true and visibilityKind ~= "clearthroughwindow"
end

function AttackExecution.isCommittedMeleeTargetInRange(zombie, target)
    local dx
    local dy
    local dz
    local range
    if not zombie or not target or target.x == nil or target.y == nil then
        return false
    end
    dx = (tonumber(target.x) or zombie:getX()) - zombie:getX()
    dy = (tonumber(target.y) or zombie:getY()) - zombie:getY()
    dz = math.abs((tonumber(target.z) or zombie:getZ()) - zombie:getZ())
    range = (tonumber(Const.MELEE_RANGE) or 1.3) + (tonumber(Const.MELEE_HIT_TOLERANCE) or 0.12)
    return dz <= 0.25 and ((dx * dx) + (dy * dy)) <= (range * range)
end
