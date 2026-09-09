--[[
    PNC Behavior Move Intent
    Owns behavior-authored movement intent so follow, combat, and hold logic
    can describe desired locomotion without directly resetting engine path
    state. The path service consumes this intent as the single live move lane.
]]

PNC = PNC or {}
PNC.BehaviorMoveIntent = PNC.BehaviorMoveIntent or {}

local MoveIntent = PNC.BehaviorMoveIntent
local Core = PNC.Core

local function sameNumber(left, right)
    if left == nil or right == nil then
        return left == right
    end
    return tonumber(left) == tonumber(right)
end

-- Behavior ticks are more frequent than meaningful movement changes. Keep the
-- revision stable when the same lane is being described again; PathService
-- uses the revision to decide whether it must consume a fresh command.
local function sameMoveIntent(
    intent,
    record,
    x,
    y,
    z,
    mode,
    stopDistance,
    reason,
    navigation
)
    local runtime = record and record.runtime or nil
    local requestedByJob = tostring(record.activeJob or "none")
    local requestedByBehavior = tostring(
        record.activeBehavior or record.activeJob or "none"
    )
    local requestedOrder = tostring(
        record.orderSpec and record.orderSpec.kind or "none"
    )
    local combatReason = tostring(runtime and runtime.combatBlockReason or "none")
    local finalX = navigation and tonumber(navigation.finalX) or tonumber(x)
    local finalY = navigation and tonumber(navigation.finalY) or tonumber(y)
    local finalZ = navigation and tonumber(navigation.finalZ) or tonumber(z)
    if not intent or intent.kind ~= "move" then return false end
    return sameNumber(intent.x, x)
        and sameNumber(intent.y, y)
        and sameNumber(intent.z, z)
        and tostring(intent.mode or "walk") == tostring(mode or "walk")
        and sameNumber(intent.stopDistance, stopDistance)
        and tostring(intent.reason or "") == tostring(reason or "")
        and intent.requestedByJob == requestedByJob
        and intent.requestedByBehavior == requestedByBehavior
        and intent.requestedOrder == requestedOrder
        and intent.combatReason == combatReason
        and intent.navigationPolicy == (navigation
            and navigation.navigationPolicy or nil)
        and intent.navigationProvider == (navigation
            and navigation.navigationProvider or nil)
        and sameNumber(intent.finalX, finalX)
        and sameNumber(intent.finalY, finalY)
        and sameNumber(intent.finalZ, finalZ)
        and sameNumber(intent.waypointIndex, navigation
            and tonumber(navigation.waypointIndex) or nil)
        and sameNumber(intent.steeringIndex, navigation
            and tonumber(navigation.steeringIndex) or nil)
        and intent.steeringKind == (navigation
            and tostring(navigation.steeringKind or "") or nil)
end

local function ensureRuntime(record)
    record.runtime = record.runtime or {}
    return record.runtime
end

function MoveIntent.RequestMove(
    record,
    x,
    y,
    z,
    mode,
    stopDistance,
    reason,
    navigation
)
    local runtime
    local intent
    if not record then
        return false
    end
    runtime = ensureRuntime(record)
    intent = runtime.moveIntent
    if not intent or intent.kind ~= "move" then
        intent = {}
        runtime.moveIntent = intent
    end
    local unchanged = sameMoveIntent(
        intent,
        record,
        x,
        y,
        z,
        mode,
        stopDistance,
        reason,
        navigation
    )
    intent.kind = "move"
    intent.x = tonumber(x) or record.x
    intent.y = tonumber(y) or record.y
    intent.z = tonumber(z) or record.z or 0
    intent.mode = tostring(mode or "walk")
    intent.stopDistance = tonumber(stopDistance) or 0.7
    intent.reason = reason or "move_request"
    intent.requestedByJob = tostring(record.activeJob or "none")
    intent.requestedByBehavior = tostring(
        record.activeBehavior or record.activeJob or "none"
    )
    intent.requestedOrder = tostring(
        record.orderSpec and record.orderSpec.kind or "none"
    )
    intent.combatReason = tostring(runtime.combatBlockReason or "none")
    intent.navigationPolicy = navigation
        and navigation.navigationPolicy or nil
    intent.navigationProvider = navigation
        and navigation.navigationProvider or nil
    intent.finalX = navigation and tonumber(navigation.finalX) or intent.x
    intent.finalY = navigation and tonumber(navigation.finalY) or intent.y
    intent.finalZ = navigation and tonumber(navigation.finalZ) or intent.z
    intent.waypointIndex = navigation
        and tonumber(navigation.waypointIndex) or nil
    intent.steeringIndex = navigation
        and tonumber(navigation.steeringIndex) or nil
    intent.steeringKind = navigation
        and tostring(navigation.steeringKind or "") or nil
    intent.updatedAt = Core.Now()
    if not unchanged then
        intent.revision = (tonumber(intent.revision) or 0) + 1
    end
    return true
end

function MoveIntent.Hold(record, reason)
    local runtime
    local intent
    if not record then
        return false
    end
    runtime = ensureRuntime(record)
    intent = runtime.moveIntent
    if not intent or intent.kind ~= "hold" then
        intent = {}
        runtime.moveIntent = intent
    end
    intent.kind = "hold"
    intent.reason = reason or "hold"
    intent.requestedByJob = tostring(record.activeJob or "none")
    intent.requestedByBehavior = tostring(
        record.activeBehavior or record.activeJob or "none"
    )
    intent.requestedOrder = tostring(
        record.orderSpec and record.orderSpec.kind or "none"
    )
    intent.updatedAt = Core.Now()
    intent.revision = (tonumber(intent.revision) or 0) + 1
    return true
end

function MoveIntent.Get(record)
    return record and record.runtime and record.runtime.moveIntent or nil
end
