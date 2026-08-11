if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.NeedHealthConsequences = PNC.NeedHealthConsequences or {}

local Consequences = PNC.NeedHealthConsequences
local Definitions = PNC.NeedsDefinitions

-- Installed Build 42 BodyDamage uses healthReductionFromSevereBadMoodles
-- (0.0165 per update): level-4 hunger divides it by 50 and level-4 thirst by
-- 10. These world-hour rates preserve those coefficients relative to the
-- already calibrated vanilla need rates in NeedsDefinitions.
Consequences.DAMAGE_PER_WORLD_HOUR = {
    hunger = Definitions.VANILLA_RATES_PER_HOUR.hunger
        * ((0.0165 / 50) / (0.0000032 * 3)),
    hydration = Definitions.VANILLA_RATES_PER_HOUR.hydration
        * ((0.0165 / 10) / (0.0000040 * 2)),
}

local function isEmergency(needType, value)
    local thresholds = Definitions.MOODLE_THRESHOLDS[needType]
    return thresholds and (tonumber(value) or 0) > thresholds[#thresholds]
end

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

function Consequences.Calculate(state, elapsedHours)
    local output = {}
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    for _, needType in ipairs({ "hunger", "hydration" }) do
        output[needType] = isEmergency(needType, state and state[needType])
            and Consequences.DAMAGE_PER_WORLD_HOUR[needType] * elapsedHours
            or 0
    end
    return output
end

function Consequences.Apply(record, elapsedHours)
    if not record or record.alive == false or not PNC.Health
        or not PNC.Health.ApplyDamage
    then return 0 end
    local damage = Consequences.Calculate(record.needs, elapsedHours)
    local applied = 0
    local body = liveBody(record)
    for _, needType in ipairs({ "hunger", "hydration" }) do
        local amount = damage[needType] or 0
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
    end
    return applied
end

return Consequences
