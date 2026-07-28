-- Live/abstract controller for the durable PNC journey service.

PNC = PNC or {}
PNC.BehaviorTravel = PNC.BehaviorTravel or {}

local Travel = PNC.BehaviorTravel
local Const = PNC.Const
local Service = PNC.Travel and PNC.Travel.Service
local Common = PNC.BehaviorCommon
local Animation = PNC.Animation
local LocalPathPlanner = PNC.LocalPathPlanner

local function normalizeTravelOrder(record, spec)
    local journey = record and record.travel or nil
    return {
        kind = Const.ORDER_TRAVEL or "travel",
        journeyId = spec and spec.journeyId
            or journey and journey.journeyId
            or nil,
    }
end

function Travel.Tick(record, zombie, _, _)
    local journey = Service and Service.Get(record) or nil
    local target
    local state
    if not journey then return false end

    record.activeBehavior = "Travel:" .. tostring(journey.state or "unknown")
    Common.ClearCombatTarget(record, "travel", zombie)

    if record.presenceState ~= Const.PRESENCE_LIVE or not zombie then
        Service.Advance(record, Service.WorldHour())
        return true
    end

    target, state = Service.TickLive(
        record,
        zombie,
        Service.WorldHour()
    )
    record.activeBehavior = "Travel:" .. tostring(state or journey.state)
    if state == "en_route" and target then
        local steeringTarget = LocalPathPlanner
            and LocalPathPlanner.GetSteeringTarget
            and LocalPathPlanner.GetSteeringTarget(record, zombie, target)
            or target
        Common.MoveRecord(
            record,
            zombie,
            steeringTarget.x,
            steeringTarget.y,
            steeringTarget.z,
            steeringTarget.mode or target.mode,
            steeringTarget.stopDistance or target.stopDistance,
            "journey:" .. tostring(journey.journeyId)
        )
    else
        if LocalPathPlanner and LocalPathPlanner.Clear then
            LocalPathPlanner.Clear(record)
        end
        Common.HaltMovement(record, zombie, "journey_" .. tostring(state))
        if Animation and Animation.Apply then
            Animation.Apply(zombie, record, "Idle")
        end
    end
    return true
end

if PNC.OrderSystem and PNC.OrderSystem.RegisterNormalizer then
    PNC.OrderSystem.RegisterNormalizer(
        Const.ORDER_TRAVEL or "travel",
        normalizeTravelOrder
    )
end
if PNC.JobSystem and PNC.JobSystem.RegisterOrder then
    PNC.JobSystem.RegisterOrder(
        Const.ORDER_TRAVEL or "travel",
        "Travel"
    )
end
if PNC.BehaviorRegistry and PNC.BehaviorRegistry.Register then
    PNC.BehaviorRegistry.Register("Travel", Travel.Tick)
end

return Travel
