if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedHealthConsequences = PNC.NeedHealthConsequences or {}

local Consequences = PNC.NeedHealthConsequences
local Definitions = PNC.NeedsDefinitions
local EventBus = require "PsychopatzCore/Events/PC_EventBus"

-- Installed Build 42 BodyDamage uses healthReductionFromSevereBadMoodles
-- (0.0165 per update): level-4 hunger divides it by 50 and level-4 thirst by
-- 10. These world-hour rates preserve those coefficients relative to the
-- already calibrated vanilla need rates in NeedsDefinitions.
Consequences.DAMAGE_PER_WORLD_HOUR = {
    hunger = Definitions.VANILLA_RATES_PER_HOUR.hunger
        * ((0.0165 / 50) / (0.0000032 * 3)),
    thirst = Definitions.VANILLA_RATES_PER_HOUR.thirst
        * ((0.0165 / 10) / (0.0000040 * 2)),
}

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

function Consequences.Calculate(beforeState, state, rates, elapsedHours)
    local output = {}
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    for _, needType in ipairs({ "hunger", "thirst" }) do
        local threshold = Definitions.CONSEQUENCES.criticalThreshold
        local before = tonumber(beforeState and beforeState[needType]) or 0
        local after = tonumber(state and state[needType]) or 0
        local criticalHours = 0
        if before >= threshold then
            criticalHours = elapsedHours
        elseif after > threshold then
            local rate = math.max(0, tonumber(rates and rates[needType]) or 0)
            if rate > 0 then
                criticalHours = math.min(elapsedHours,
                    math.max(0, (after - threshold) / rate))
            end
        end
        output[needType] = Consequences.DAMAGE_PER_WORLD_HOUR[needType]
            * criticalHours
    end
    return output
end

function Consequences.Apply(record, beforeState, state, rates, elapsedHours)
    if not record or record.alive == false or not PNC.Health
        or not PNC.Health.ApplyDamage
    then return 0 end
    local damage = Consequences.Calculate(beforeState, state, rates,
        elapsedHours)
    local applied = 0
    local body = liveBody(record)
    local mortality = PNC.Sandbox
        and PNC.Sandbox.PlayerOwnedNPCNeedMortalityEnabled
        and PNC.Sandbox.PlayerOwnedNPCNeedMortalityEnabled()
    for _, needType in ipairs({ "hunger", "thirst" }) do
        local amount = damage[needType] or 0
        if not mortality then
            local current = tonumber(record.health and record.health.current) or 100
            amount = math.max(0, math.min(amount,
                current - Definitions.CONSEQUENCES.nonlethalHealthFloor))
        end
        if amount > 0 and PNC.Health.ApplyDamage(record, body, {
            amount = amount,
            type = needType == "hunger" and "starvation" or "dehydration",
            attackerKind = "environment",
        }) then
            applied = applied + amount
        end
    end
    if applied > 0 then
        record.runtime = record.runtime or {}
        record.runtime.needs = record.runtime.needs or {}
        record.runtime.needs.lastHealthDamage = applied
        record.runtime.needs.lastHealthDamageAt = PNC.NeedsUtils.WorldAgeHours()
        if record.runtime.needs.criticalDamageJournaled ~= true then
            record.runtime.needs.criticalDamageJournaled = true
            EventBus.emit(PNC.EventTypes.NPC_NEED_CRITICAL_DAMAGE, record,
                applied, mortality == true)
        end
    elseif record.runtime and record.runtime.needs then
        record.runtime.needs.criticalDamageJournaled = nil
    end
    return applied
end

return Consequences
