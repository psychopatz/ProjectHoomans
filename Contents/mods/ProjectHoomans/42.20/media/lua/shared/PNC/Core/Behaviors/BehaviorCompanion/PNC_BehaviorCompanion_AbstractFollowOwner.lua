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
            runtime
        )
    else
        owner = Common.GetOwner(record)
        state = Internal.GetFollowState(record)
    end
    ownerResolved = owner ~= nil
    if ownerUnresolved then
        return true
    end
    if owner then
        if owner.getUsername then
            record.ownerUsername = owner:getUsername()
        end
        if owner.getOnlineID then
            record.ownerOnlineID = owner:getOnlineID()
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
        targetX = tonumber(record.anchorX) or beforeX
        targetY = tonumber(record.anchorY) or beforeY
        targetZ = tonumber(record.anchorZ) or beforeZ
        stopDistance = 0.8
        reason = "abstract_follow_owner_missing_return_anchor"
        state.mode = "returning_to_anchor"
        if auditEnabled then
            runtime.abstractFollowOwnerResolved = false
        end
    end
    record.activeBehavior = owner
        and "FollowOwner:abstract"
        or "FollowOwner:abstract_owner_missing"
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
    return true
end

return PNC.BehaviorCompanion
