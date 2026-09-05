PNC = PNC or {}
PNC.OrderSystem = PNC.OrderSystem or {}

local OrderSystem = PNC.OrderSystem
local Const = PNC.Const
local Core = PNC.Core
local Skills = PNC.Skills

OrderSystem.Normalizers = OrderSystem.Normalizers or {}

-- Durable orders which do not have a Tasking lease still need the same
-- liveness boundary. The behavior code remains the owner of the order's
-- meaning; this table only tells the shared recovery probe which orders may
-- legitimately request locomotion.
OrderSystem.RECOVERY_TIMEOUT_MS =
    OrderSystem.RECOVERY_TIMEOUT_MS or 60000
OrderSystem.RECOVERY_MISSING_LANE_TIMEOUT_MS =
    OrderSystem.RECOVERY_MISSING_LANE_TIMEOUT_MS or 15000
OrderSystem.RECOVERY_RETRY_INTERVAL_MS =
    OrderSystem.RECOVERY_RETRY_INTERVAL_MS or 5000
OrderSystem.MAX_RECOVERY_ATTEMPTS =
    OrderSystem.MAX_RECOVERY_ATTEMPTS or 2
OrderSystem.RECOVERY_ORDERS = OrderSystem.RECOVERY_ORDERS or {
    follow = true,
    camp = true,
    guard = true,
    patrol = true,
    roam = true,
    hostile_roam = true,
    hostile_hunt = true,
    travel = true,
    colony_home = true,
    lumber = true,
}

local function wakeRecord(record)
    local now
    if not record then return end
    now = Core.Now()
    record.nextThinkAt = now
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, nil, now)
    end
    if PNC.Scheduler and PNC.Scheduler.Schedule then
        PNC.Scheduler.Schedule(
            record,
            now + (tonumber(PNC.Scheduler.SLOT_MS) or 50)
        )
    end
end

function OrderSystem.RegisterNormalizer(kind, normalizer)
    kind = tostring(kind or "")
    if kind == "" or type(normalizer) ~= "function" then return false end
    OrderSystem.Normalizers[kind] = normalizer
    return true
end

local function fallbackOrder(record)
    if record.tacticalClass == "hostile" then
        return { kind = Const.ORDER_HOSTILE_HUNT }
    end
    return { kind = Const.ORDER_GUARD, x = record.anchorX, y = record.anchorY, z = record.anchorZ }
end

function OrderSystem.Normalize(record, orderSpec)
    local spec = orderSpec or fallbackOrder(record)
    local kind = tostring(spec.kind or spec.mode or "")
    local normalizer
    local normalized

    if kind == "" then
        return fallbackOrder(record)
    end

    normalizer = OrderSystem.Normalizers[kind]
    if normalizer then
        normalized = normalizer(record, spec)
        if type(normalized) == "table" then return normalized end
        return fallbackOrder(record)
    end

    if kind == Const.ORDER_FOLLOW then
        return {
            kind = kind,
            ownerUsername = spec.ownerUsername or record.ownerUsername,
            ownerOnlineID = spec.ownerOnlineID or record.ownerOnlineID,
        }
    end

    if kind == Const.ORDER_GUARD then
        return {
            kind = kind,
            x = tonumber(spec.x) or record.anchorX,
            y = tonumber(spec.y) or record.anchorY,
            z = tonumber(spec.z) or record.anchorZ,
        }
    end

    if kind == Const.ORDER_PATROL then
        return {
            kind = kind,
            points = Core.DeepCopy(spec.points or record.patrolPoints or {
                { x = record.anchorX, y = record.anchorY, z = record.anchorZ },
            }),
        }
    end

    if kind == Const.ORDER_HOSTILE_HUNT then
        return {
            kind = kind,
            x = tonumber(spec.x) or record.anchorX,
            y = tonumber(spec.y) or record.anchorY,
            z = tonumber(spec.z) or record.anchorZ,
        }
    end

    return fallbackOrder(record)
end

function OrderSystem.SetOrder(record, orderSpec)
    local zombie
    local previousOrder = record.orderSpec
    local previousKind = tostring(previousOrder and previousOrder.kind or "")
    local requestedKind = tostring(orderSpec
        and (orderSpec.kind or orderSpec.mode) or "")
    local activeFacility = record.runtime
        and record.runtime.facilityActivity or nil
    record.runtime = record.runtime or {}

    -- A blocking facility scene owns the behavior tick until it is stopped.
    -- Commands such as follow/home must revoke that lease before the new order
    -- is normalized; otherwise the old relaxing scene consumes every tick and
    -- the command appears to have been ignored.
    if previousKind == "facility_activity"
        and requestedKind ~= "facility_activity"
        and activeFacility
        and PNC.FacilityJobs
        and PNC.FacilityJobs.AbortForOrderChange
    then
        PNC.FacilityJobs.AbortForOrderChange(record, nil, "order_changed")
    end

    record.orderSpec = OrderSystem.Normalize(record, orderSpec)
    -- A return complaint belongs only to the follow order that created it.
    -- Clear it at the durable order boundary so an NPC that is reassigned
    -- while abstract cannot later deliver stale follow-phase commentary.
    if previousKind == tostring(Const.ORDER_FOLLOW or "follow")
        and tostring(record.orderSpec.kind or "")
            ~= tostring(Const.ORDER_FOLLOW or "follow")
        and record.followerAbandonment
    then
        record.followerAbandonment = nil
    end
    if record.orderSpec.kind == Const.ORDER_FOLLOW then
        record.ownerUsername = record.orderSpec.ownerUsername
        record.ownerOnlineID = record.orderSpec.ownerOnlineID
    end
    record.runtime.target = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.followState = nil
    record.runtime.roaming = nil
    record.runtime.roamGoalX = nil
    record.runtime.roamGoalY = nil
    record.runtime.roamGoalZ = nil
    record.activeJob = nil
    record.activeBehavior = nil
    zombie = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if PNC.PathService and PNC.PathService.Commands
        and PNC.PathService.Commands.Reset
    then
        PNC.PathService.Commands.Reset(record, zombie, "order_changed")
    elseif PNC.PathService and PNC.PathService.Reset then
        PNC.PathService.Reset(zombie, record)
    else
        record.runtime.moveIntent = nil
        record.runtime.pathing = nil
    end
    if record.orderSpec.kind == Const.ORDER_PATROL and record.patrolIndex == nil then
        record.patrolIndex = 1
    end
    if Skills and Skills.SyncRecruitment then
        Skills.SyncRecruitment(record)
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "order")
    end
    if PNC.CampResourceService and PNC.CampResourceService.OnOrderChanged then
        PNC.CampResourceService.OnOrderChanged(
            record, previousOrder, record.orderSpec)
    end
    -- Camp is a durable order boundary. Need severity can already be high
    -- when a follower enters camp, so no severity_changed event is guaranteed
    -- to arrive after the order change. Wake tasking after the snapshot has
    -- been captured; facility_activity transitions are intentionally excluded
    -- so starting a need task cannot immediately re-enter task evaluation.
    if tostring(record.orderSpec.kind or "")
        == tostring(Const.ORDER_CAMP or "camp")
        and previousKind ~= tostring(Const.ORDER_CAMP or "camp")
        and PNC.Tasking and PNC.Tasking.Events
        and PNC.Tasking.Events.Emit
    then
        PNC.Tasking.Events.Emit("NPC_NEEDS_CHANGED", {
            npcId = record.id, source = "OrderSystem",
            entityId = record.id, cause = "CAMP_ENTERED",
        })
    end
    wakeRecord(record)
end

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

local function safeFallbackOrder(record, kind)
    local hostile = record and record.tacticalClass == "hostile"
        or kind == "hostile_roam" or kind == "hostile_hunt"
    local x = tonumber(record and record.x) or tonumber(record and record.anchorX)
    local y = tonumber(record and record.y) or tonumber(record and record.anchorY)
    local z = tonumber(record and record.z) or tonumber(record and record.anchorZ) or 0
    if hostile then
        return {
            kind = Const.ORDER_HOSTILE_HUNT or "hostile_hunt",
            x = x, y = y, z = z,
        }
    end
    return { kind = Const.ORDER_GUARD or "guard", x = x, y = y, z = z }
end

local function recoverDirectOrder(record, zombie, now, snapshot)
    local state = recoveryState(record,
        record.orderSpec and record.orderSpec.kind or "")
    local attempts = (tonumber(state.attempts) or 0) + 1
    local kind = tostring(record.orderSpec and record.orderSpec.kind or "")
    local reason = tostring(snapshot and snapshot.recoveryReason
        or "order_progress_timeout")
    local currentOrder = Core.DeepCopy(record.orderSpec)
    state.attempts = attempts
    state.lastRecoveryAt = now
    state.lastReason = reason
    if attempts >= OrderSystem.MAX_RECOVERY_ATTEMPTS then
        OrderSystem.SetOrder(record, safeFallbackOrder(record, kind))
        record.runtime = record.runtime or {}
        record.runtime.orderRecovery = {
            kind = tostring(record.orderSpec and record.orderSpec.kind or ""),
            attempts = 0,
            fallbackFrom = kind,
            lastReason = reason,
        }
        return true
    end
    OrderSystem.SetOrder(record, currentOrder)
    record.runtime = record.runtime or {}
    record.runtime.orderRecovery = {
        kind = kind,
        attempts = attempts,
        observedProgressAt = state.observedProgressAt,
        nextAttemptAt = now + OrderSystem.RECOVERY_RETRY_INTERVAL_MS,
        missingSince = now,
        lastRecoveryAt = now,
        lastReason = reason,
    }
    return true
end

function OrderSystem.RecoverStalled(record, zombie, now)
    now = tonumber(now) or Core.Now()
    local snapshot = OrderSystem.GetRecoveryState(record, zombie, now)
    local progressAt
    local timeoutMs
    if not snapshot or snapshot.watchable ~= true then return false end
    if snapshot.action == true and snapshot.forceRecovery == true then
        if PNC.Combat and PNC.Combat.CancelAttackAction then
            PNC.Combat.CancelAttackAction(record, zombie, nil,
                snapshot.recoveryReason or "combat_action_timeout")
        elseif record.runtime then
            record.runtime.attackAction = nil
        end
        return true
    end
    progressAt = tonumber(snapshot.lastProgressAt) or now
    timeoutMs = tonumber(snapshot.timeoutMs)
        or OrderSystem.RECOVERY_TIMEOUT_MS
    if snapshot.forceRecovery ~= true and now - progressAt < timeoutMs then
        return false
    end
    return recoverDirectOrder(record, zombie, now, snapshot)
end

function OrderSystem.SetHostility(record, modeSpec)
    record.hostility = record.hostility or {}
    if modeSpec and modeSpec.mode ~= nil then
        record.hostility.mode = tostring(modeSpec.mode)
    else
        record.hostility.mode = tostring(record.hostility.mode or "neutral")
    end
    if modeSpec and modeSpec.attackPlayers ~= nil then
        record.hostility.attackPlayers = modeSpec.attackPlayers == true
    else
        record.hostility.attackPlayers = record.hostility.attackPlayers == true
    end
    if modeSpec and modeSpec.attackNPCs ~= nil then
        record.hostility.attackNPCs = modeSpec.attackNPCs == true
    else
        record.hostility.attackNPCs = record.hostility.attackNPCs == true
    end
    if modeSpec and modeSpec.attackZombies ~= nil then
        record.hostility.attackZombies = modeSpec.attackZombies == true
    else
        record.hostility.attackZombies = record.hostility.attackZombies == true
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "hostility")
    end
    wakeRecord(record)
end
