-- Abstract follow-owner simulation for bodyless companion records.

local Internal = PNC.BehaviorCompanion.Internal
local Core = PNC.Core
local Const = PNC.Const
local Common = PNC.BehaviorCommon
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function followerPresenceAuditEnabled()
    return Diagnostics
        and Diagnostics.IsFollowerPresenceAuditEnabled
        and Diagnostics.IsFollowerPresenceAuditEnabled() == true
end

local function requestLiveHandoff(record, runtime, owner, now)
    local distance
    local materializeDistance
    if not owner or type(owner.getX) ~= "function"
        or type(owner.getY) ~= "function"
    then
        return false
    end
    materializeDistance = tonumber(Const.MATERIALIZE_DISTANCE) or 28
    distance = Core.Distance(
        tonumber(record.x) or 0,
        tonumber(record.y) or 0,
        tonumber(owner:getX()) or record.x,
        tonumber(owner:getY()) or record.y
    )
    if distance > materializeDistance then
        return false
    end
    -- The abstract record has crossed into the owner's live radius during
    -- this behavior tick. Presence normally runs before behavior, so wake it
    -- explicitly; otherwise the record waits for another cold abstract tick
    -- and appears to stop at the edge of the map handoff.
    runtime.nearestPlayerDistSq = distance * distance
    if runtime.forceLive ~= true then
        runtime.abstractFollowOwnsForceLive = true
    end
    runtime.forceLive = true
    runtime.abstractFollowMaterializeRequested = true
    runtime.forcePresenceCheck = true
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, "presence", now)
    end
    return true
end

if not Internal.AbstractFollowOwnerResolution then
    Internal.AbstractFollowOwnerResolution = {
        Const = Const,
        Common = Common,
        Diagnostics = Diagnostics,
    }
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_Resolution"
end
if not Internal.AbstractFollowOwnerMovementHandoff then
    Internal.AbstractFollowOwnerMovementAudit = {
        Core = Core,
        Diagnostics = Diagnostics,
    }
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_MovementAudit"
    Internal.AbstractFollowOwnerMovementSpeed = {
        Const = Const,
    }
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_MovementSpeed"
    Internal.AbstractFollowOwnerMovementHandoff = {
        Core = Core,
        Const = Const,
        Common = Common,
        Diagnostics = Diagnostics,
        Audit = Internal.AbstractFollowOwnerMovementAudit,
        Speed = Internal.AbstractFollowOwnerMovementSpeed,
    }
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff"
end
if not Internal.AbstractFollowOwnerMovementHandoff.Advance then
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_AbstractFollowOwner_MovementHandoff_Advance"
end

-- Bodyless followers use only owner resolution and direct abstract movement.
-- This deliberately avoids the live follow pipeline's zombie perception,
-- threat response, formation scan, animation, and engine pathing work.
function Internal.TickAbstractFollowOwner(record, now)
    local owner
    local runtime = record.runtime or {}
    local state
    local ownerResolved
    local ownerUnresolved
    local beforeX = tonumber(record.x) or 0
    local beforeY = tonumber(record.y) or 0
    local beforeZ = tonumber(record.z) or 0
    local targetX
    local targetY
    local targetZ
    local stopDistance
    local reason
    local auditEnabled = followerPresenceAuditEnabled()
    now = tonumber(now) or (Core.Now and Core.Now() or 0)
    record.runtime = runtime
    record.activeJob = "FollowOwner"
    local resolution = Internal.AbstractFollowOwnerResolution
    if resolution and resolution.Resolve then
        owner, state, ownerUnresolved = resolution.Resolve(
            record,
            runtime,
            now
        )
    else
        owner = Common.GetOwner(record)
        state = Internal.GetFollowState(record)
    end
    ownerResolved = owner ~= nil
    if ownerUnresolved then
        if runtime.abstractFollowOwnsForceLive == true then
            runtime.forceLive = nil
            runtime.abstractFollowOwnsForceLive = nil
        end
        runtime.abstractFollowMaterializeRequested = nil
        runtime.forcePresenceCheck = nil
        return true
    end
    if owner then
        if owner.getUsername then
            record.ownerUsername = owner:getUsername()
        end
        if owner.getOnlineID then
            record.ownerOnlineID = owner:getOnlineID()
        end
        if record.orderSpec
            and tostring(record.orderSpec.kind or "") == tostring(
                Const.ORDER_FOLLOW or "follow"
            )
        then
            record.orderSpec.ownerUsername = record.ownerUsername
            record.orderSpec.ownerOnlineID = record.ownerOnlineID
        end
        targetX = tonumber(owner:getX()) or beforeX
        targetY = tonumber(owner:getY()) or beforeY
        targetZ = tonumber(owner:getZ()) or beforeZ
        stopDistance = tonumber(Const.FOLLOW_DISTANCE) or 1.8
        reason = "abstract_follow_owner"
        state.mode = "abstract_follow"
        if auditEnabled then
            runtime.abstractFollowOwnerResolved = true
        end
    else
        -- An active follow order must never degrade into an anchor/home trip
        -- merely because the owner is not resolvable on this tick. This is
        -- common while an MP owner is changing relevance or during the live
        -- to abstract handoff. Hold the current abstract position and retry
        -- owner resolution on the normal follow cadence.
        targetX = beforeX
        targetY = beforeY
        targetZ = beforeZ
        stopDistance = 0
        reason = "abstract_follow_owner_unresolved_hold"
        state.mode = "owner_unresolved"
        if auditEnabled then
            runtime.abstractFollowOwnerResolved = false
        end
    end
    record.activeBehavior = owner and "FollowOwner:abstract"
        or "FollowOwner:owner_unresolved"
    runtime.followOrderActive = true
    runtime.target = nil
    runtime.attackAction = nil
    runtime.inCombatUntil = 0
    runtime.combatBlockReason = reason
    local movementHandoff = Internal.AbstractFollowOwnerMovementHandoff
    if movementHandoff and movementHandoff.Advance then
        movementHandoff.Advance(
            record,
            runtime,
            owner,
            targetX,
            targetY,
            targetZ,
            stopDistance,
            reason,
            ownerResolved,
            now,
            beforeX,
            beforeY,
            beforeZ,
            auditEnabled
        )
    end
    if owner then
        requestLiveHandoff(record, runtime, owner, now)
    end
    return true
end

return PNC.BehaviorCompanion
