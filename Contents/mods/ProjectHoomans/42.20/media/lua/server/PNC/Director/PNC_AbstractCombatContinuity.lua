-- Modular live-to-abstract combat continuity bridge.
-- When an NPC abstracts out of player range while actively engaged in live
-- combat, finishes the skirmish off-camera via AbstractHazardResolver using
-- their current HP/equipment instead of silently dropping the fight.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.AbstractCombatContinuity = PNC.AbstractCombatContinuity or {}

local Continuity = PNC.AbstractCombatContinuity

local function isInLiveCombat(record, nowMs)
    local rt = type(record and record.runtime) == "table" and record.runtime or nil
    if not rt then return false end
    if rt.combatTarget ~= nil or rt.inCombat == true then
        return true
    end
    local untilMs = tonumber(rt.inCombatUntil) or 0
    if untilMs > 0 and (tonumber(nowMs) or 0) <= untilMs then
        return true
    end
    return false
end

function Continuity.OnLiveCombatAbstracted(record, body, reason, worldHour, nowMs)
    if type(record) ~= "table" or record.alive == false then
        return false, "invalid_record"
    end
    -- Only bridge genuine out-of-range abstractions (not explicit debug/cleanup removals).
    local r = tostring(reason or "")
    if r ~= "range_exit" and r ~= "distance_exit" and r ~= "abstract" then
        return false, "non_range_reason"
    end
    nowMs = tonumber(nowMs) or (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
    if not isInLiveCombat(record, nowMs) then
        return false, "not_in_combat"
    end
    local hazard = PNC.AbstractHazardResolver
    if not hazard or type(hazard.ResolveForParticipants) ~= "function" then
        return false, "hazard_resolver_unavailable"
    end
    local x = body and body.getX and tonumber(body:getX()) or tonumber(record.x) or 0
    local y = body and body.getY and tonumber(body:getY()) or tonumber(record.y) or 0
    local threatCount = tonumber(record.runtime and record.runtime.travelTactics
        and record.runtime.travelTactics.lastDecision
        and record.runtime.travelTactics.lastDecision.threatCount) or 4
    local baseThreat = hazard.EvaluateThreatAt and hazard.EvaluateThreatAt(x, y, worldHour) or { totalThreat = 0 }
    local combinedThreat = math.max(55, (tonumber(baseThreat.totalThreat) or 0), threatCount * 18)

    local res = hazard.ResolveForParticipants(
        { record },
        x,
        y,
        worldHour,
        {
            entityId = "live_combat_handoff:" .. tostring(record.id),
            isPlayerColonist = record.recruited == true,
            threatOverride = { totalThreat = combinedThreat },
        }
    )
    return true, res and res.outcome or "RESOLVED", res
end

return Continuity
