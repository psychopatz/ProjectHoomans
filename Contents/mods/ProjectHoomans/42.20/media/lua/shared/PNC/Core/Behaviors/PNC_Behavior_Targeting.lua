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
local CompatibilityAPI = PNC.Compatibility
    and PNC.Compatibility.API

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
    elseif target.kind == "foreign_npc" then
        targetZombie = target.worldObject
        if not targetZombie and CompatibilityAPI
            and CompatibilityAPI.ResolveTarget
        then
            local resolved = CompatibilityAPI.ResolveTarget(target)
            targetZombie = resolved and resolved.worldObject or nil
        end
    end
    if targetZombie then
        if zombie.faceThisObject then
            zombie:faceThisObject(targetZombie)
        elseif zombie.faceLocationF then
            zombie:faceLocationF(target.x, target.y)
        end
    end
end

local function sameTarget(left, right)
    if not left or not right or left.kind ~= right.kind then return false end
    if left.kind == "npc" then
        return tostring(left.id or "") == tostring(right.id or "")
    end
    if left.kind == "zombie" then
        return tostring(left.zombieId or "")
            == tostring(right.zombieId or "")
    end
    if left.kind == "player" then
        if left.onlineID ~= nil and right.onlineID ~= nil then
            return tonumber(left.onlineID) == tonumber(right.onlineID)
        end
        return tostring(left.username or "") == tostring(right.username or "")
    end
    if left.kind == "foreign_npc" then
        return tostring(left.provider or "") == tostring(right.provider or "")
            and tostring(left.actorId or left.id or "")
                == tostring(right.actorId or right.id or "")
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

-- NPC self-defense must be resolved before ordinary area targeting. A direct
-- attacker is actionable even when this survivor's attackNPCs policy is off.
function Targeting.ResolveImmediateNPCThreat(record)
    local threat
    if not record then return nil end
    if Perception.ResolveRecentAttacker then
        threat = Perception.ResolveRecentAttacker(
            record,
            Core.Now and Core.Now() or 0
        )
        if threat and (threat.kind == "npc"
            or threat.kind == "foreign_npc")
        then
            return threat
        end
    end
    if Perception.FindImmediateNPCThreat then
        threat = Perception.FindImmediateNPCThreat(record)
        if threat and threat.kind == "npc" then
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

Targeting.Internal = Targeting.Internal or {}
Targeting.Internal.WorldTargetResolver = {
    Core = Core,
    Const = Const,
    Registry = Registry,
    Perception = Perception,
    CompatibilityAPI = CompatibilityAPI,
}
require "PNC/Core/Behaviors/PNC_Behavior_Targeting_WorldTargetResolver"
local WorldTargetResolver = Targeting.Internal.WorldTargetResolver

Targeting.Internal.UpdateTargetFromWorld = {
    Core = Core,
    Const = Const,
    Resolver = WorldTargetResolver.Resolve,
}
require "PNC/Core/Behaviors/PNC_Behavior_Targeting_UpdateTargetFromWorld"
