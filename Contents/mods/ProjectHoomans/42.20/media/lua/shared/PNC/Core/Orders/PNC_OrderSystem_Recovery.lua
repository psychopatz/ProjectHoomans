local OrderSystem = require "PNC/Core/Orders/PNC_OrderSystem_Base"
local Internal = OrderSystem.Internal or {}
local Core = Internal.Core
local Const = Internal.Const

local function bodyCoordinate(body, method, fallback)
    if body and type(body[method]) == "function" then
        return tonumber(body[method](body)) or tonumber(fallback) or 0
    end
    return tonumber(fallback) or 0
end

local function moveIntent(record, kind)
    local intent = record and record.runtime
        and record.runtime.moveIntent or nil
    local requestedOrder = intent and intent.requestedOrder or nil
    if not intent or intent.kind ~= "move" then return nil end
    if requestedOrder ~= nil
        and tostring(requestedOrder) ~= tostring(kind)
    then
        return nil
    end
    return intent
end

local function isAtIntentGoal(record, zombie, intent)
    local x = tonumber(intent and (intent.x or intent.finalX))
    local y = tonumber(intent and (intent.y or intent.finalY))
    local z = tonumber(intent and (intent.z or intent.finalZ))
    local currentX = bodyCoordinate(zombie, "getX", record and record.x)
    local currentY = bodyCoordinate(zombie, "getY", record and record.y)
    local currentZ = bodyCoordinate(zombie, "getZ", record and record.z)
    local stopDistance = math.max(0.1,
        tonumber(intent and intent.stopDistance) or 0.7)
    local dx
    local dy
    if x == nil or y == nil then return false end
    dx = x - currentX
    dy = y - currentY
    return (dx * dx) + (dy * dy) <= stopDistance * stopDistance
        and math.abs((z or currentZ) - currentZ) < 0.75
end

local function recoveryState(record, kind)
    local runtime = record and record.runtime
    local state = runtime and runtime.orderRecovery or nil
    if not runtime then return nil end
    if type(state) ~= "table"
        or tostring(state.kind or "") ~= tostring(kind or "")
    then
        state = { kind = tostring(kind or ""), attempts = 0 }
        runtime.orderRecovery = state
    end
    return state
end

local function noteProgress(state, progressAt)
    progressAt = tonumber(progressAt)
    if not state or not progressAt or progressAt <= 0 then return end
    if progressAt ~= tonumber(state.observedProgressAt) then
        state.observedProgressAt = progressAt
        state.attempts = 0
        state.missingSince = nil
        state.blockedSince = nil
        state.quarantined = nil
    end
end

local function directOrderKind(kind)
    return OrderSystem.RECOVERY_ORDERS[tostring(kind or "")] == true
end

local function attackRecoveryState(record, now)
    local action = record and record.runtime
        and record.runtime.attackAction or nil
    local startedAt
    local finishAt
    local stale
    if type(action) ~= "table" then return nil end
    startedAt = tonumber(action.startedAt) or now
    finishAt = tonumber(action.finishAt) or 0
    -- finishAt is the action owner's explicit deadline (reloads can be
    -- longer than ordinary melee clips). Use the generic cap only for a
    -- malformed action that never published a deadline.
    stale = finishAt > 0 and now >= finishAt + 1000
        or finishAt <= 0 and now - startedAt >= 10000
    return {
        action = true,
        watchable = stale,
        forceRecovery = stale,
        phase = "COMMITTED_ACTION",
        lastProgressAt = startedAt,
        timeoutMs = 10000,
        recoveryReason = "combat_action_timeout",
    }
end

-- Observe movement progress without becoming a second path owner. PathService
-- remains authoritative for physical progress and traversal deadlines; this
-- boundary only decides when an order should be re-issued after that lane has
-- gone stale or disappeared.
function OrderSystem.GetRecoveryState(record, zombie, now)
    local kind = tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
    local runtime = record and record.runtime or nil
    local intent
    local pathService
    local movement
    local state
    local progressAt
    if not record or record.alive == false then return { terminal = true } end
    now = tonumber(now) or Core.Now()

    local action = attackRecoveryState(record, now)
    if action then return action end
    if not directOrderKind(kind) then return nil end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    if runtime and runtime.orderRecovery
        and now < (tonumber(runtime.orderRecovery.nextAttemptAt) or 0)
    then
        return { phase = "RECOVERY_BACKOFF", watchable = false }
    end

    intent = moveIntent(record, kind)
    pathService = PNC.PathService
    movement = pathService and pathService.GetMovementRecoveryState
        and pathService.GetMovementRecoveryState(record, zombie, now)
        or nil
    state = recoveryState(record, kind)

    -- A hold or an already-reached target is a valid idle state, not a stall.
    if not intent or isAtIntentGoal(record, zombie, intent) then
        if state then
            state.missingSince = nil
            state.blockedSince = nil
        end
        return nil
    end

    if movement and movement.traversal == true
        and movement.forceRecovery ~= true
    then
        return {
            phase = "TRAVEL",
            watchable = false,
            movement = movement,
        }
    end

    if movement and movement.active == true then
        if movement.watchable == false then
            return {
                phase = "TRAVEL",
                watchable = false,
                movement = movement,
            }
        end
        progressAt = tonumber(movement.lastProgressAt)
        if not progressAt or progressAt <= 0 then progressAt = now end
        noteProgress(state, progressAt)
        return {
            phase = "TRAVEL",
            watchable = true,
            forceRecovery = movement.forceRecovery == true,
            lastProgressAt = progressAt,
            timeoutMs = OrderSystem.RECOVERY_TIMEOUT_MS,
            recoveryReason = movement.forceRecovery == true
                and "path_traversal_timeout" or "order_movement_timeout",
            movement = movement,
            attempts = state.attempts,
        }
    end

    if movement and movement.phase == "blocked" then
        state.blockedSince = state.blockedSince or now
        return {
            phase = "TRAVEL",
            watchable = true,
            lastProgressAt = state.blockedSince,
            timeoutMs = OrderSystem.RECOVERY_MISSING_LANE_TIMEOUT_MS,
            recoveryReason = "order_path_blocked",
            movement = movement,
            attempts = state.attempts,
        }
    end

    -- Behavior runs before PathService.Pump. A newly-issued intent can
    -- therefore have one tick with no lane; only a prolonged absence is
    -- recoverable, so normal ordering never gets mistaken for a stall.
    state.missingSince = state.missingSince or now
    return {
        phase = "TRAVEL",
        watchable = true,
        lastProgressAt = state.missingSince,
        timeoutMs = OrderSystem.RECOVERY_MISSING_LANE_TIMEOUT_MS,
        recoveryReason = "order_path_lane_missing",
        attempts = state.attempts,
    }
end


Internal.recoveryState = recoveryState
return OrderSystem
