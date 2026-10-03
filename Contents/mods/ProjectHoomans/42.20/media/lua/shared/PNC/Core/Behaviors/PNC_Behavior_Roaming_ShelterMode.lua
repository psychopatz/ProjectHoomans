-- Shelter roaming mode provider.

PNC = PNC or {}
PNC.BehaviorRoaming = PNC.BehaviorRoaming or {}

local Roaming = PNC.BehaviorRoaming
local H = Roaming.Internal and Roaming.Internal.ShelterMode
if type(H) ~= "table" then
    return Roaming
end

local Core = H.Core
local Const = H.Const
local Common = H.Common
local BehaviorCombat = H.BehaviorCombat
local resolveRoamingThreat = H.ResolveRoamingThreat

function H.Run(record, zombie, order)
    record.runtime = record.runtime or {}
    local state = record.runtime.roaming or {}
    local now = Core.Now()
    local target
    local targetX = tonumber(order.x) or record.anchorX or record.x
    local targetY = tonumber(order.y) or record.anchorY or record.y
    local targetZ = tonumber(order.z) or record.anchorZ or record.z
    local targetID = order.shelterSiteID
    record.runtime.roaming = state
    target = resolveRoamingThreat(
        record,
        state,
        math.max(1, tonumber(order.targetRadius) or Const.ROAM_TARGET_RADIUS),
        now
    )
    if target then
        state.phase = "combat"
        Common.SetCombatTarget(record, target, "roaming_threat")
        BehaviorCombat.TickEngage(record, zombie, target)
        return true
    end
    if record.runtime.target ~= nil then
        Common.ClearCombatTarget(record, "shelter_target_lost", zombie)
    end
    if state.targetX ~= targetX or state.targetY ~= targetY
        or state.targetZ ~= targetZ or state.targetID ~= targetID
    then
        state.targetX, state.targetY, state.targetZ = targetX, targetY, targetZ
        state.targetID = targetID
        state.reached = false
    end
    if state.reached
        or Core.Distance(record.x, record.y, targetX, targetY)
            <= math.max(0.1, tonumber(order.reachedDistance) or 3)
    then
        state.reached = true
        state.phase = "sheltered"
        Common.ClearCombatTarget(record, "sheltered", zombie)
        Common.HaltMovement(record, zombie, "mobile_shelter")
        record.activeBehavior = "Roam:shelter:sheltered"
        if order.ambientMobile == true
            and order.ambientObjective == "shelter"
            and PNC.AmbientVisitService
            and PNC.AmbientVisitService.TryStartMobileShelter
        then
            PNC.AmbientVisitService.TryStartMobileShelter(
                record,
                zombie,
                order,
                now
            )
        end
        return true
    end
    Common.ClearCombatTarget(record, "moving_to_shelter", zombie)
    Common.MoveRecord(
        record,
        zombie,
        targetX,
        targetY,
        targetZ,
        tostring(order.moveMode or "walk"),
        math.max(0.1, tonumber(order.reachedDistance) or 3),
        "mobile_shelter"
    )
    return true
end

return Roaming

