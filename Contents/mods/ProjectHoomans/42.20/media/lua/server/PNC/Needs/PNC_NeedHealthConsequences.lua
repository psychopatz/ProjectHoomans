if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedHealthConsequences = PNC.NeedHealthConsequences or {}

local Consequences = PNC.NeedHealthConsequences
local Definitions = PNC.NeedsDefinitions
local Registry = PNC.Registry
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

-- A need must be completely depleted before its Whole Body ailment starts
-- building. The values are intentionally data-driven so future conditions
-- such as flu can use the same persistent body state and damage gate.
Consequences.WHOLE_BODY_AILMENT_POLICIES = {
    starvation = {
        needType = "hunger", damageType = "starvation", trigger = 1.0,
        buildupPerWorldHour = 0.10, recoveryPerWorldHour = 0.20,
    },
    dehydration = {
        needType = "thirst", damageType = "dehydration", trigger = 1.0,
        buildupPerWorldHour = 0.10, recoveryPerWorldHour = 0.20,
    },
}

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

local function ailmentMap(record)
    local wholeBody = PNC.NPCWounds and PNC.NPCWounds.WholeBody
    if wholeBody and wholeBody.Ensure then
        return wholeBody.Ensure(record)
    end
    local health = PNC.Health and PNC.Health.Ensure
        and PNC.Health.Ensure(record) or record and record.health
    if not health then return nil end
    health.body = type(health.body) == "table" and health.body or {}
    health.body.wholeBodyAilments =
        type(health.body.wholeBodyAilments) == "table"
        and health.body.wholeBodyAilments or {}
    return health.body.wholeBodyAilments
end

local function ailmentSeverity(value)
    if type(value) == "table" then
        return math.max(0, math.min(1, tonumber(value.severity) or 0))
    end
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function setAilmentSeverity(record, ailmentID, value)
    local wholeBody = PNC.NPCWounds and PNC.NPCWounds.WholeBody
    if wholeBody and wholeBody.SetSeverity then
        return wholeBody.SetSeverity(record, ailmentID, value)
    end
    local ailments = ailmentMap(record)
    if not ailments then return 0, false end
    local id = tostring(ailmentID or "")
    local previous = ailmentSeverity(ailments[id])
    value = math.max(0, math.min(1, tonumber(value) or 0))
    if value <= 0 then
        ailments[id] = nil
    else
        ailments[id] = { severity = value }
    end
    return value, math.abs(previous - value) > 0.000001
end

local function hoursAtTrigger(before, after, rate, elapsed, trigger)
    if elapsed <= 0 or after < trigger then return 0 end
    if before >= trigger then return elapsed end
    if rate <= 0 then return 0 end
    return math.max(0, math.min(elapsed,
        elapsed - math.max(0, (trigger - before) / rate)))
end

local function updateAilment(record, ailmentID, policy, beforeState, state,
    rates, elapsedHours)
    local ailments = ailmentMap(record)
    local current = ailments and ailmentSeverity(ailments[ailmentID]) or 0
    local before = tonumber(beforeState and beforeState[policy.needType]) or 0
    local after = tonumber(state and state[policy.needType]) or 0
    local trigger = tonumber(policy.trigger) or 1
    local buildupRate = math.max(0, tonumber(policy.buildupPerWorldHour) or 0)
    local recoveryRate = math.max(0, tonumber(policy.recoveryPerWorldHour) or 0)
    local needRate = math.max(0, tonumber(rates and rates[policy.needType]) or 0)
    local exposedHours = hoursAtTrigger(before, after, needRate,
        elapsedHours, trigger)
    local damageHours = 0
    local nextValue
    local buildup

    if after >= trigger then
        buildup = exposedHours * buildupRate
        if current >= 1 then
            damageHours = exposedHours
        elseif buildupRate > 0 and current + buildup >= 1 then
            damageHours = (current + buildup - 1) / buildupRate
        end
        nextValue = math.min(1, current + buildup)
    else
        nextValue = math.max(0, current - elapsedHours * recoveryRate)
    end
    local changed
    nextValue, changed = setAilmentSeverity(record, ailmentID, nextValue)
    if changed and Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "whole_body_ailment")
    end
    return nextValue, damageHours
end

function Consequences.Calculate(beforeState, state, rates, elapsedHours)
    local output = {}
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    for _, ailmentID in ipairs(Definitions.WHOLE_BODY_AILMENT_ORDER or {}) do
        local policy = Consequences.WHOLE_BODY_AILMENT_POLICIES[ailmentID]
        if policy then
            local before = tonumber(beforeState and beforeState[policy.needType]) or 0
            local after = tonumber(state and state[policy.needType]) or 0
            local exposedHours = hoursAtTrigger(before, after,
                tonumber(rates and rates[policy.needType]) or 0,
                elapsedHours, tonumber(policy.trigger) or 1)
            output[ailmentID] = {
                exposureHours = exposedHours,
                damagePerWorldHour = Consequences.DAMAGE_PER_WORLD_HOUR[
                    policy.needType] or 0,
            }
        end
    end
    return output
end

function Consequences.Apply(record, beforeState, state, rates, elapsedHours)
    if not record or record.alive == false or not PNC.Health
        or not PNC.Health.ApplyDamage
    then return 0 end
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    local body = liveBody(record)
    local mortality = PNC.Sandbox
        and PNC.Sandbox.PlayerOwnedNPCNeedMortalityEnabled
        and PNC.Sandbox.PlayerOwnedNPCNeedMortalityEnabled()
    local damageRequests = {}
    local applied = 0

    for _, ailmentID in ipairs(Definitions.WHOLE_BODY_AILMENT_ORDER or {}) do
        local policy = Consequences.WHOLE_BODY_AILMENT_POLICIES[ailmentID]
        if policy then
            local _, damageHours = updateAilment(record, ailmentID, policy,
                beforeState, state, rates, elapsedHours)
            if damageHours > 0 then
                damageRequests[#damageRequests + 1] = {
                    id = ailmentID,
                    type = policy.damageType,
                    amount = damageHours * (
                        Consequences.DAMAGE_PER_WORLD_HOUR[policy.needType] or 0
                    ),
                }
            end
        end
    end

    for _, request in ipairs(damageRequests) do
        local amount = math.max(0, tonumber(request.amount) or 0)
        if not mortality then
            local current = tonumber(record.health and record.health.current) or 100
            amount = math.max(0, math.min(amount,
                current - Definitions.CONSEQUENCES.nonlethalHealthFloor))
        end
        if amount > 0 and PNC.Health.ApplyDamage(record, body, {
            amount = amount,
            type = request.type,
            attackerKind = "environment",
        }) then
            applied = applied + amount
        end
    end

    if applied > 0 then
        record.runtime = record.runtime or {}
        record.runtime.needs = record.runtime.needs or {}
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
