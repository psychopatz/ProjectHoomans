-- Live/abstract controller for the durable PNC journey service.

PNC = PNC or {}
PNC.BehaviorTravel = PNC.BehaviorTravel or {}

local Travel = PNC.BehaviorTravel
local Const = PNC.Const
local Service = PNC.Travel and PNC.Travel.Service
local Common = PNC.BehaviorCommon
local Animation = PNC.Animation
local Core = PNC.Core
local Perception = PNC.Perception
local Stealth = PNC.Stealth
local BehaviorCombat = PNC.BehaviorCombat
local TravelTactics = require "PNC/Core/Behaviors/PNC_Behavior_Travel_Tactics"
local TRAVEL_NAVIGATION = {
    navigationPolicy = "travel",
}

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
    local combatTarget
    local travelStealth
    local wasInTravelCombat
    local now
    if not journey then
        if Stealth and Stealth.ClearTravel then
            Stealth.ClearTravel(record, "no_journey", zombie)
        end
        return false
    end

    record.activeBehavior = "Travel:" .. tostring(journey.state or "unknown")

    if record.presenceState ~= Const.PRESENCE_LIVE or not zombie then
        if Stealth and Stealth.ClearTravel then
            Stealth.ClearTravel(record, "abstract_travel", zombie)
        end
        Common.ClearCombatTarget(record, "travel", zombie)
        Service.Advance(record, Service.WorldHour())
        return true
    end

    now = Core.Now()
    combatTarget = Perception
        and Perception.ResolveRecentAttacker
        and Perception.ResolveRecentAttacker(record, now)
        or nil
    if combatTarget and BehaviorCombat and BehaviorCombat.TickEngage then
        if Stealth and Stealth.SetTravelCombatActive then
            Stealth.SetTravelCombatActive(record, zombie, true)
        end
        record.runtime = record.runtime or {}
        Common.SetCombatTarget(record, combatTarget, "travel_recent_attacker")
        record.activeBehavior = "Travel:Combat:"
            .. tostring(combatTarget.kind or "unknown")
        BehaviorCombat.TickEngage(record, zombie, combatTarget)
        return true
    end

    wasInTravelCombat = Stealth
        and Stealth.IsTravelCombatActive
        and Stealth.IsTravelCombatActive(record)
        or false
    if Stealth and Stealth.SetTravelCombatActive and wasInTravelCombat then
        Stealth.SetTravelCombatActive(record, zombie, false)
    end
    Common.ClearCombatTarget(
        record,
        wasInTravelCombat and "travel_combat_clear" or "travel",
        zombie
    )

    target, state = Service.TickLive(
        record,
        zombie,
        Service.WorldHour()
    )
    record.activeBehavior = "Travel:" .. tostring(state or journey.state)
    if state == "en_route" and target then
        local tactics = TravelTactics and TravelTactics.Evaluate
            and TravelTactics.Evaluate(record, zombie, target, now)
            or { action = "proceed" }
        if tactics.action == "engage" and tactics.combatTarget
            and BehaviorCombat and BehaviorCombat.TickEngage
        then
            if Stealth and Stealth.SetTravelCombatActive then
                Stealth.SetTravelCombatActive(record, zombie, true)
            end
            Common.SetCombatTarget(record, tactics.combatTarget, "travel_proactive_threat")
            record.activeBehavior = "Travel:Combat:Proactive"
            BehaviorCombat.TickEngage(record, zombie, tactics.combatTarget)
            return true
        elseif (tactics.action == "flank" or tactics.action == "flee")
            and tactics.moveX and tactics.moveY
        then
            record.activeBehavior = tactics.action == "flee" and "Travel:Flee" or "Travel:Flank"
            Common.MoveRecord(
                record,
                zombie,
                tactics.moveX,
                tactics.moveY,
                tactics.moveZ or target.z,
                tactics.mode or "run",
                2.0,
                "journey_" .. tactics.action .. ":" .. tostring(journey.journeyId),
                TRAVEL_NAVIGATION
            )
            return true
        end
        travelStealth = Stealth
            and Stealth.UpdateTravelState
            and Stealth.UpdateTravelState(record, zombie, now)
            or false
        Common.MoveRecord(
            record,
            zombie,
            target.x,
            target.y,
            target.z,
            travelStealth and "sneak" or target.mode,
            target.stopDistance,
            "journey:" .. tostring(journey.journeyId),
            TRAVEL_NAVIGATION
        )
    else
        if Stealth and Stealth.ClearTravel then
            Stealth.ClearTravel(
                record,
                "journey_" .. tostring(state),
                zombie
            )
        end
        if PNC.NavigationRouter and PNC.NavigationRouter.Clear then
            PNC.NavigationRouter.Clear(record)
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
