--[[
    PNC Behavior Targeting
    Shared target refresh and live-body facing helpers used by colonist and
    hostile behavior branches.
]]

PNC = PNC or {}
PNC.BehaviorTargeting = PNC.BehaviorTargeting or {}

local Targeting = PNC.BehaviorTargeting
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Perception = PNC.Perception

function Targeting.BindLiveTarget(zombie, target)
    local targetZombie
    if not zombie or not target then
        return
    end
    if target.kind == "player" and target.player then
        if zombie.faceThisObject then
            zombie:faceThisObject(target.player)
        elseif zombie.faceLocationF then
            zombie:faceLocationF(target.x, target.y)
        end
        return
    end
    if target.kind == "npc" then
        targetZombie = Registry.GetLiveZombie(target.id)
    elseif target.kind == "zombie" and Perception.FindZombieByID then
        targetZombie = Perception.FindZombieByID(target.zombieId)
    end
    if targetZombie then
        if zombie.faceThisObject then
            zombie:faceThisObject(targetZombie)
        elseif zombie.faceLocationF then
            zombie:faceLocationF(target.x, target.y)
        end
    end
end

function Targeting.UpdateTargetFromWorld(record, target)
    local targetRecord
    local player
    local zombie
    local targetZombie
    local now
    local memoryUntil
    local visible
    local visibilityKind
    if not target then
        return nil
    end
    now = Core.Now()
    memoryUntil = (tonumber(target.lastSeenAt) or 0) + (tonumber(Const.TARGET_VISUAL_MEMORY_MS) or 2200)
    if target.kind == "npc" then
        targetRecord = Registry.Get(target.id)
        targetZombie = targetRecord and Registry.GetLiveZombie(target.id) or nil
        visible = false
        visibilityKind = nil
        if targetZombie and Perception.CanSeeWorldObject then
            visible, visibilityKind = Perception.CanSeeWorldObject(record, targetZombie)
        end
        if targetRecord and targetRecord.alive ~= false and targetZombie
            and visible
        then
            target.x = targetRecord.x
            target.y = targetRecord.y
            target.z = targetRecord.z
            target.distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
            target.visible = true
            target.visibilityKind = visibilityKind
            target.lastSeenAt = now
            target.threatening = Perception.IsTargetThreatening
                and Perception.IsTargetThreatening(record, target)
                or false
            return target
        end
        if targetRecord and targetRecord.alive ~= false and now < memoryUntil then
            target.visible = false
            target.distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
            return target
        end
        return nil
    end
    if target.kind == "player" then
        player = Core.ResolvePlayerByOnlineID(target.onlineID) or Core.ResolvePlayerByUsername(target.username)
        visible = false
        visibilityKind = nil
        if player and Perception.CanSeeWorldObject then
            visible, visibilityKind = Perception.CanSeeWorldObject(record, player)
        end
        if player and visible then
            target.player = player
            target.x = player:getX()
            target.y = player:getY()
            target.z = player:getZ()
            target.distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
            target.visible = true
            target.visibilityKind = visibilityKind
            target.lastSeenAt = now
            target.threatening = Perception.IsTargetThreatening
                and Perception.IsTargetThreatening(record, target)
                or false
            return target
        end
        if player and now < memoryUntil then
            target.visible = false
            target.distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
            return target
        end
        return nil
    end
    if target.kind == "zombie" then
        zombie = Perception.FindZombieByID and Perception.FindZombieByID(target.zombieId) or nil
        visible = false
        visibilityKind = nil
        if zombie and Perception.CanSeeWorldObject then
            visible, visibilityKind = Perception.CanSeeWorldObject(record, zombie)
        end
        if zombie and visible then
            target.x = zombie:getX()
            target.y = zombie:getY()
            target.z = zombie:getZ()
            target.distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
            target.visible = true
            target.visibilityKind = visibilityKind
            target.lastSeenAt = now
            target.threatening = Perception.IsTargetThreatening
                and Perception.IsTargetThreatening(record, target)
                or false
            return target
        end
        if zombie and now < memoryUntil then
            target.visible = false
            target.distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
            return target
        end
        return Perception.FindNearestEnemyZombie(record, Const.ZOMBIE_TARGET_RADIUS)
    end
    return nil
end

local function sameTarget(left, right)
    if not left or not right or left.kind ~= right.kind then return false end
    if left.kind == "npc" then return tostring(left.id or "") == tostring(right.id or "") end
    if left.kind == "zombie" then return tostring(left.zombieId or "") == tostring(right.zombieId or "") end
    if left.kind == "player" then
        if left.onlineID ~= nil and right.onlineID ~= nil then
            return tonumber(left.onlineID) == tonumber(right.onlineID)
        end
        return tostring(left.username or "") == tostring(right.username or "")
    end
    return false
end

function Targeting.SelectReassessedTarget(record, current, candidate)
    local currentDist
    local candidateDist
    local threatRadius = tonumber(Const.TARGET_IMMEDIATE_THREAT_RADIUS) or 6
    local threatRadiusSq = threatRadius * threatRadius
    local currentThreat
    local candidateThreat
    local switchRatio = tonumber(Const.TARGET_SWITCH_DISTANCE_RATIO) or 0.72
    if not candidate then return current end
    if candidate.x ~= nil and candidate.y ~= nil then
        candidate.distSq = Core.DistanceSq(record.x, record.y, candidate.x, candidate.y)
    end
    if not current then return candidate end
    if sameTarget(current, candidate) then return candidate end
    currentDist = tonumber(current.distSq) or math.huge
    candidateDist = tonumber(candidate.distSq) or math.huge
    currentThreat = current.threatening == true and currentDist <= threatRadiusSq
    candidateThreat = candidate.threatening == true and candidateDist <= threatRadiusSq
    if candidateThreat and not currentThreat then
        return candidate
    end
    if currentThreat and not candidateThreat then
        return current
    end
    if current.visible == false and candidate.visible ~= false then
        return candidate
    end
    if candidateDist < currentDist * switchRatio then
        return candidate
    end
    return current
end

-- A zombie attack can arrive while a hostile NPC is still committed to a
-- player/NPC target. Keep that survival threat available to the behavior
-- owner so combat arbitration can temporarily yield to zombie retreat.
function Targeting.ResolveImmediateZombieThreat(record)
    local threat
    if not record then return nil end
    if Perception.ResolveRecentAttacker then
        threat = Perception.ResolveRecentAttacker(
            record,
            Core.Now and Core.Now() or 0
        )
        if threat and threat.kind == "zombie" then
            return threat
        end
    end
    if Perception.FindImmediateZombieThreat then
        threat = Perception.FindImmediateZombieThreat(record)
        if threat and threat.kind == "zombie" then
            return threat
        end
    end
    return nil
end

function Targeting.ResolveEngageTarget(record, resolver)
    local runtime
    local now
    local current
    local candidate
    if not record or type(resolver) ~= "function" then return nil end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    now = Core.Now()
    current = Targeting.UpdateTargetFromWorld(record, runtime.target)
    if current and now < (tonumber(runtime.nextTargetReassessAt) or 0) then
        return current
    end
    runtime.nextTargetReassessAt = now + (tonumber(Const.TARGET_REASSESS_MS) or 350)
    candidate = resolver(record)
    return Targeting.SelectReassessedTarget(record, current, candidate)
end

function Targeting.ResolveCompanionEngageTarget(record)
    return Targeting.ResolveEngageTarget(record, Perception.ResolveCompanionTarget)
end

function Targeting.ResolveCompanionProtectionTarget(record, ownerEngaged)
    local runtime = record and record.runtime or nil
    local now = Core.Now()
    -- Protection targets must be proven again at each reassessment. This
    -- prevents a one-frame attack from turning into an unlimited chase.
    if runtime and runtime.target
        and ownerEngaged ~= true
        and now >= (tonumber(runtime.nextTargetReassessAt) or 0)
    then
        runtime.target = nil
    end
    return Targeting.ResolveEngageTarget(record, function(source)
        return Perception.ResolveCompanionProtectionTarget(
            source,
            ownerEngaged
        )
    end)
end

function Targeting.ResolveHostileEngageTarget(record)
    return Targeting.ResolveEngageTarget(record, Perception.ResolveHostileTarget)
end

function Targeting.ResolveRoamingEngageTarget(record, radius)
    return Targeting.ResolveEngageTarget(record, function(source)
        return Perception.ResolveRoamingTarget(source, radius)
    end)
end
