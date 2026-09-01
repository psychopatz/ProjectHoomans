PNC = PNC or {}
PNC.OrderSystem = PNC.OrderSystem or {}

local OrderSystem = PNC.OrderSystem
local Const = PNC.Const
local Core = PNC.Core
local Skills = PNC.Skills

OrderSystem.Normalizers = OrderSystem.Normalizers or {}

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
