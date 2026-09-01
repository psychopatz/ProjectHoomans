if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedFacilityEffects = PNC.NeedFacilityEffects or {}

local Effects = PNC.NeedFacilityEffects
local afterDelay

local function applyNearbyWater(record, state, definition, now)
    if state.effectAttempted == true or not afterDelay(state, definition, now) then
        return true, false
    end
    state.effectAttempted = true
    local source = state.resource
    if not source and PNC.NearbyWaterService
        and PNC.NearbyWaterService.Resolve
    then
        source = PNC.NearbyWaterService.Resolve(record, state.resourceKey)
        state.resource = source
    end
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    -- An abstract Camp retains a primitive faucet descriptor, not an
    -- IsoObject. The captured resource is still authoritative proof that the
    -- NPC can drink here, so apply the logical hydration effect without
    -- trying to mutate an unloaded world object. Materialized Camp activity
    -- continues through the normal live Consume path below.
    if activity and activity.campActivity == true
        and activity.abstract == true
        and (not source or (not source.object and not source.item))
    then
        local liters = PNC.NearbyWaterService
            and PNC.NearbyWaterService.DesiredLiters
            and PNC.NearbyWaterService.DesiredLiters(record, nil) or 1
        if PNC.IndividualNeeds and PNC.IndividualNeeds.Commands
            and PNC.IndividualNeeds.Commands.ApplyDrink
        then
            PNC.IndividualNeeds.Commands.ApplyDrink(record, {
                thirst = (tonumber(liters) or 0) / 2,
            }, "camp_water_drink_abstract")
        end
        return true, true, "NEED_COMPLETE", liters
    end
    local container = source and source.item
        and source.item.getFluidContainer
        and source.item:getFluidContainer() or nil
    local available = container and container.getAmount
        and tonumber(container:getAmount()) or nil
    if available == nil and source and source.object
        and source.object.getWaterAmount
    then
        available = tonumber(source.object:getWaterAmount())
    end
    local liters = PNC.NearbyWaterService
        and PNC.NearbyWaterService.DesiredLiters
        and PNC.NearbyWaterService.DesiredLiters(record, available) or 0
    if state.debugForceWater == true and liters <= 0 then
        liters = (available == nil or available < 0)
            and 1 or math.min(1, available)
    end
    local ok, consumed, reason = false, nil, nil
    if PNC.NearbyWaterService
        and type(PNC.NearbyWaterService.Consume) == "function"
    then
        ok, consumed, reason = PNC.NearbyWaterService.Consume(
            record, source, liters)
    end
    if ok ~= true then return false, true, reason or "INSUFFICIENT_WATER" end
    if PNC.IndividualNeeds and PNC.IndividualNeeds.Commands
        and PNC.IndividualNeeds.Commands.ApplyDrink
    then
        PNC.IndividualNeeds.Commands.ApplyDrink(record, {
            thirst = (tonumber(consumed) or 0) / 2,
        }, "nearby_water_drink")
    end
    return true, true, "NEED_COMPLETE", consumed
end

afterDelay = function(state, definition, now)
    state.effectReadyAt = state.effectReadyAt or ((tonumber(now) or 0)
        + (tonumber(definition.effectDelayMs) or 0))
    return (tonumber(now) or 0) >= state.effectReadyAt
end

local function applyPrimitive(record, state, definition, now)
    if state.effectAttempted == true or not afterDelay(state, definition, now) then
        return true, false
    end
    state.effectAttempted = true
    local ok, reason = PNC.NeedSupplyBridge
        and PNC.NeedSupplyBridge.RequestForNeed
        and PNC.NeedSupplyBridge.RequestForNeed(
            record, definition.primitiveNeed, false)
    return ok == true, true, reason or (ok and "NEED_COMPLETE"
        or "PROVISION_NOT_FOUND")
end

local function applyWater(record, state, definition, now)
    if state.effectAttempted == true or not afterDelay(state, definition, now) then
        return true, false
    end
    state.effectAttempted = true
    local ok, reason = PNC.WaterUtilityService
        and PNC.WaterUtilityService.Consume
        and PNC.WaterUtilityService.Consume(
            state.facilityId, definition.waterLiters or 1)
    if ok ~= true then return false, true, reason or "INSUFFICIENT_WATER" end
    if PNC.IndividualNeeds and PNC.IndividualNeeds.Commands
        and PNC.IndividualNeeds.Commands.ApplyDrink
    then
        PNC.IndividualNeeds.Commands.ApplyDrink(record, {
            thirst = definition.thirstRelief or 0.50,
        }, "facility_spigot_drink")
    end
    return true, true, "NEED_COMPLETE"
end

local function applyNeed(record, definition, elapsed)
    if definition.needType == "fatigue" and PNC.IndividualNeeds.Commands
        and PNC.IndividualNeeds.Commands.ApplyRest
    then
        local ok, reason, value = PNC.IndividualNeeds.Commands.ApplyRest(
            record, elapsed, "facility_need_route")
        return ok, reason == "REST_COMPLETE"
            or value ~= nil and value <= definition.completionThreshold,
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
        return applyPrimitive(record, state, definition, now)
    end
    if definition.needEffect == "water" then
        return applyWater(record, state, definition, now)
    end
    if definition.needEffect == "nearby_water" then
        return applyNearbyWater(record, state, definition, now)
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
