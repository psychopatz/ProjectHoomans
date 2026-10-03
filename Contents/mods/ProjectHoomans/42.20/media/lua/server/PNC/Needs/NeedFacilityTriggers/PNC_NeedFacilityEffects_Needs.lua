if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedFacilityEffects = PNC.NeedFacilityEffects or {}

local Effects = PNC.NeedFacilityEffects
local Internal = Effects.Internal or {}
Effects.Internal = Internal
local afterDelay = Internal.AfterDelay
local applyWorldWater = Internal.ApplyWorldWater
local applyWaterRefill = Internal.ApplyWaterRefill

local function applyPrimitive(record, state, definition, now)
    if state.effectAttempted == true or not afterDelay(state, definition, now) then
        return true, false
    end
    state.effectAttempted = true
    local ok, reason = PNC.NeedSupplyBridge
        and PNC.NeedSupplyBridge.RequestForNeed
        and PNC.NeedSupplyBridge.RequestForNeed(
            record, definition.primitiveNeed,
            state.manual == true)
    return ok == true, true, reason or (ok and "NEED_COMPLETE"
        or "PROVISION_NOT_FOUND")
end

local function applyPersonalItem(record, state, definition, now)
    local runtime = record and record.runtime
        and record.runtime.facilityActivity or nil
    local itemID = state and state.activityItemID
        or runtime and runtime.activityItemID
    local needs = PNC.IndividualNeeds
    local needType = definition and definition.primitiveNeed
    local resourceKind
    local current
    local target
    local supply
    local required
    local ok
    local reason
    local effect
    if needType ~= "hunger" and needType ~= "thirst" then
        return applyPrimitive(record, state, definition, now)
    end
    if not itemID or tostring(itemID) == ""
        or not PNC.NPCSupplyService
        or not PNC.NPCSupplyService.ConsumePersonalItem
    then
        return applyPrimitive(record, state, definition, now)
    end
    if state.effectAttempted == true or not afterDelay(state, definition, now) then
        return true, false
    end
    resourceKind = needType == "hunger" and "FOOD" or "HYDRATION"
    current = needs and needs.Get and needs.Get(record, needType)
        or record and record.needs and record.needs[needType]
    supply = PNC.NeedsDefinitions and PNC.NeedsDefinitions.SUPPLY
        and PNC.NeedsDefinitions.SUPPLY[needType] or nil
    target = supply and tonumber(supply.target) or 0.10
    required = math.max(0.001, (tonumber(current) or 0) - target)
    if state.manual == true or runtime and runtime.manual == true then
        required = math.max(required,
            supply and tonumber(supply.manualMinimum) or 0.001)
    end
    ok, reason, effect = PNC.NPCSupplyService.ConsumePersonalItem(
        record, itemID, required, resourceKind)
    if not ok then
        state.effectAttempted = true
        return false, true, reason or "PERSONAL_ITEM_CONSUME_FAILED"
    end
    state.effectAttempted = true
    return true, true, "NEED_COMPLETE", effect and effect[needType]
end

local function applyNeed(record, definition, elapsed)
    if definition.needType == "fatigue" and PNC.IndividualNeeds.Commands
        and PNC.IndividualNeeds.Commands.ApplyRest
    then
        local state = record.runtime
            and record.runtime.facilityActivity or nil
        local manualSleep = state and state.manual == true
            and state.manualToggleable == true
        local ok, reason, value = PNC.IndividualNeeds.Commands.ApplyRest(
            record, elapsed, "facility_need_route", {
                ignoreCompletion = manualSleep,
            })
        local complete = not manualSleep and (reason == "REST_COMPLETE"
            or value ~= nil and value <= definition.completionThreshold)
        return ok, complete,
            reason, value
    end
    local value = PNC.IndividualNeeds.Modify(record, definition.needType,
        -(tonumber(definition.recoveryPerGameHour) or 0) * elapsed,
        "facility_need_route")
    return value ~= nil,
        value ~= nil and value <= (tonumber(definition.completionThreshold) or 0),
        value and "NEED_PROGRESS" or "NEED_UPDATE_FAILED", value
end

local function applyHealth(record, definition, elapsed)
    local health = PNC.Health and PNC.Health.Ensure
        and PNC.Health.Ensure(record) or record.health
    if not health then return false, true, "HEALTH_STATE_MISSING" end
    local maximum = math.max(1, tonumber(health.max) or 100)
    local amount = maximum
        * (tonumber(definition.recoveryPerGameHour) or 0) * elapsed
    if PNC.NPCWounds and PNC.NPCWounds.ApplyBodyHealing then
        health.current = PNC.NPCWounds.ApplyBodyHealing(record, amount)
            or health.current
    else
        health.current = math.min(maximum,
            (tonumber(health.current) or maximum) + amount)
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "hospital_recovery")
    end
    local ratio = health.current / maximum
    return true, ratio >= (tonumber(definition.completionThreshold) or 0.98),
        "HEALTH_PROGRESS", ratio
end

local function applyRecreation(record, definition, elapsed)
    local condition = PNC.ConditionStats and PNC.ConditionStats.Ensure
        and PNC.ConditionStats.Ensure(record) or record.conditionStats
    if not condition then return false, true, "CONDITION_STATE_MISSING" end
    condition.boredom = math.max(0, (tonumber(condition.boredom) or 0)
        - (tonumber(definition.boredomReliefPerGameHour) or 0) * elapsed)
    condition.stress = math.max(0, (tonumber(condition.stress) or 0)
        - (tonumber(definition.stressReliefPerGameHour) or 0) * elapsed)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "recreation_recovery")
    end
    return true, condition.boredom <=
        (tonumber(definition.completionThreshold) or 15),
        "RECREATION_PROGRESS", condition.boredom
end

function Effects.Tick(record, state, definition, elapsed, now)
    if not definition or not definition.needEffect then return true, false end
    if definition.needEffect == "primitive" then
        return applyPersonalItem(record, state, definition, now)
    end
    if definition.needEffect == "world_water" then
        return applyWorldWater(record, state, definition, now)
    end
    if definition.needEffect == "water_refill" then
        return applyWaterRefill(record, state, definition, now)
    end
    if elapsed <= 0 then return true, false end
    if definition.needEffect == "need" then
        return applyNeed(record, definition, elapsed)
    end
    if definition.needEffect == "health" then
        return applyHealth(record, definition, elapsed)
    end
    if definition.needEffect == "recreation" then
        return applyRecreation(record, definition, elapsed)
    end
    return false, true, "UNKNOWN_NEED_EFFECT"
end

return Effects
