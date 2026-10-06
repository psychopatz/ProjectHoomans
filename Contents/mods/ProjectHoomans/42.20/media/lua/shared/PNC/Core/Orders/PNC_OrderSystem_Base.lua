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

local CAMP_BLOCKED_TASK_DOMAINS = {
    work = true,
    farming = true,
    fishing = true,
    scavenge = true,
    -- NeedFacility leases are also behavior owners. If they survive the
    -- camp transition they can immediately select a bed/chair/water scene
    -- and consume the tick before AtCamp gets a chance to move the NPC.
    NeedFacility = true,
}

local function releaseCampBlockedTask(record)
    local runtime = record and record.runtime or nil
    local lease = PNC.TaskLeaseService
        and PNC.TaskLeaseService.ForNPC
        and PNC.TaskLeaseService.ForNPC(record.id) or nil

    -- These tasking domains are colony/remote activities, not camp-local
    -- needs. Cancel them before installing camp so provider cleanup and
    -- previous-order restoration cannot overwrite the camp order.
    if lease and CAMP_BLOCKED_TASK_DOMAINS[tostring(lease.sourceDomain or "")]
        and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.CancelLease
    then
        return PNC.Tasking.Commands.CancelLease(lease.leaseId, "camp_entered")
    end

    -- Keep a compatibility fallback for work assignments created before the
    -- Tasking lease exists (or after a partial recovery).
    if runtime and runtime.workOrderId
        and PNC.WorkService and PNC.WorkService.Commands
        and PNC.WorkService.Commands.ReleaseWorker
    then
        local released, reason = PNC.WorkService.Commands.ReleaseWorker(
            record.id, "camp_entered")
        if released == true or reason == "WORK_ORDER_UNAVAILABLE" then
            return true
        end
        return false, reason or "WORK_ASSIGNMENT_RELEASE_FAILED"
    end
    return true
end

local function cancelSemanticActionPlan(record, reason)
    local semantics = PNC.Semantics
    local service = semantics and semantics.ActionPlanService or nil
    local mutable
    local result
    local ok
    if not record then return end
    if service and type(service.GetMutable) == "function" then
        ok, mutable = pcall(service.GetMutable, record.id)
        if not ok then mutable = nil end
    end
    if record.semanticActionPlan == nil and not mutable then return end
    if service and type(service.Cancel) == "function" then
        ok, result = pcall(service.Cancel, record.id,
            reason or "camp_entered")
        if ok and result == true then return end
        if Core.LogWarn then
            Core.LogWarn("semantic plan cleanup failed npc="
                .. tostring(record.id or "") .. " reason="
                .. tostring(reason or "camp_entered"))
        end
        if service.ByNPC then service.ByNPC[tostring(record.id)] = nil end
    end
    record.semanticActionPlan = nil
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
        local anchor = type(spec.homeAnchor) == "table"
            and spec.homeAnchor or nil
        local normalizedAnchor
        if anchor and tonumber(anchor.x) and tonumber(anchor.y) then
            normalizedAnchor = {
                baseId = anchor.baseId ~= nil
                    and tostring(anchor.baseId) or nil,
                x = tonumber(anchor.x),
                y = tonumber(anchor.y),
                z = tonumber(anchor.z) or tonumber(record.z) or 0,
                radius = math.max(1, tonumber(anchor.radius) or 3),
                homeZoneId = anchor.homeZoneId ~= nil
                    and tostring(anchor.homeZoneId) or nil,
                stockpileNodeId = anchor.stockpileNodeId ~= nil
                    and tostring(anchor.stockpileNodeId) or nil,
            }
        end
        return {
            kind = kind,
            ownerUsername = spec.ownerUsername or record.ownerUsername,
            ownerOnlineID = spec.ownerOnlineID or record.ownerOnlineID,
            -- Follow owns movement, but the last authoritative home anchor
            -- remains durable so an explicit Go Home can resume the same
            -- destination after an abstract/save-load interval.
            homeAnchor = normalizedAnchor,
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

-- Orders that move the NPC own the body: a live stationary facility lease
-- (sleep, seat, relax) is resolved before movement in MoveRecord and halts every
-- movement request with sleep_hold/seated_hold. The first facility abort above
-- is authoritative; this predicate lets the later block retry the release when a
-- movement order arrives and the lease survived that first attempt.
local function movementOrderKind(kind)
    kind = tostring(kind or "")
    if kind == "" then return false end
    return kind == tostring(Const.ORDER_FOLLOW or "follow")
        or kind == tostring(Const.ORDER_TRAVEL or "travel")
        or kind == tostring(Const.ORDER_GUARD or "guard")
        or kind == tostring(Const.ORDER_PATROL or "patrol")
        or kind == tostring(Const.ORDER_ROAM or "roam")
end


OrderSystem.Internal = OrderSystem.Internal or {}
OrderSystem.Internal.wakeRecord = wakeRecord
OrderSystem.Internal.releaseCampBlockedTask = releaseCampBlockedTask
OrderSystem.Internal.cancelSemanticActionPlan = cancelSemanticActionPlan
OrderSystem.Internal.fallbackOrder = fallbackOrder
OrderSystem.Internal.movementOrderKind = movementOrderKind
OrderSystem.Internal.Core = Core
OrderSystem.Internal.Const = Const
OrderSystem.Internal.Skills = Skills

return OrderSystem
