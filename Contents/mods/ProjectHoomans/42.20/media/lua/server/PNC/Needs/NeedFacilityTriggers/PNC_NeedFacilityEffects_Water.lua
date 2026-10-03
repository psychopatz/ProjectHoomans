if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedFacilityEffects = PNC.NeedFacilityEffects or {}

local Effects = PNC.NeedFacilityEffects
local Internal = Effects.Internal or {}
Effects.Internal = Internal
local WORLD_WATER_RETRY_COOLDOWN_MS =
    Internal.WORLD_WATER_RETRY_COOLDOWN_MS
local WATER_REFILL_RETRY_COOLDOWN_MS =
    Internal.WATER_REFILL_RETRY_COOLDOWN_MS
local hasLiveWaterSource = Internal.HasLiveWaterSource
local worldWaterFailure = Internal.WorldWaterFailure
local optionalBottleRefill = Internal.OptionalBottleRefill
local afterDelay

local function applyWorldWater(record, state, definition, now)
    if state.effectAttempted == true or not afterDelay(state, definition, now) then
        return true, false
    end
    local source = state.resource
    -- FacilityJobs intentionally stores only primitive resource descriptors in
    -- the activity state. Rehydrate that descriptor at the effect boundary so
    -- live item/IsoObject handles are never required to cross persistence.
    if not hasLiveWaterSource(source) and PNC.NearbyWaterService
        and PNC.NearbyWaterService.Resolve
    then
        source = PNC.NearbyWaterService.Resolve(record, state.resourceKey)
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
        if (tonumber(liters) or 0) <= 0 then
            return worldWaterFailure(record, now, "INSUFFICIENT_WATER")
        end
        if PNC.IndividualNeeds and PNC.IndividualNeeds.Commands
            and PNC.IndividualNeeds.Commands.ApplyDrink
        then
            PNC.IndividualNeeds.Commands.ApplyDrink(record, {
                thirst = (tonumber(liters) or 0) / 2,
            }, "camp_water_drink_abstract")
        end
        state.effectAttempted = true
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
    if source and source.object and PNC.NearbyWaterService
        and PNC.NearbyWaterService.IsInfiniteFaucet
        and PNC.NearbyWaterService.IsInfiniteFaucet(source.object)
    then
        available = nil
    end
    local liters = PNC.NearbyWaterService
        and PNC.NearbyWaterService.DesiredLiters
        and PNC.NearbyWaterService.DesiredLiters(record, available) or 0
    if state.debugForceWater == true and liters <= 0 then
        liters = (available == nil or available < 0)
            and 1 or math.min(1, available)
    end
    if (tonumber(liters) or 0) <= 0 then
        return worldWaterFailure(record, now, "INSUFFICIENT_WATER")
    end
    local ok, consumed, reason = false, nil, nil
    if PNC.NearbyWaterService
        and type(PNC.NearbyWaterService.Consume) == "function"
    then
        ok, consumed, reason = PNC.NearbyWaterService.Consume(
            record, source, liters)
    end
    if ok ~= true then
        return worldWaterFailure(record, now,
            reason or "INSUFFICIENT_WATER")
    end
    if (tonumber(consumed) or 0) <= 0 then
        return worldWaterFailure(record, now, "INSUFFICIENT_WATER")
    end
    local filledBottle, filledItemID, refillReason = optionalBottleRefill(
        record, state, source)
    if filledBottle ~= nil then
        state.optionalBottleFill = true
        state.optionalBottleFillItemID = filledItemID
        state.optionalBottleFillAmount = filledBottle
        Effects.ApplyWaterRefillSuccess(record, state, filledBottle)
    elseif PNC.IndividualNeeds and PNC.IndividualNeeds.Commands
        and PNC.IndividualNeeds.Commands.ApplyDrink
    then
        PNC.IndividualNeeds.Commands.ApplyDrink(record, {
            thirst = (tonumber(consumed) or 0) / 2,
        }, "world_water_drink")
        state.optionalBottleFill = false
        state.optionalBottleFillReason = refillReason
    end
    state.effectAttempted = true
    return true, true, "NEED_COMPLETE", consumed
end

local function applyWaterRefill(record, state, definition, now)
    local source
    local itemID
    local ok
    local filled
    local reason
    if state.effectAttempted == true or not afterDelay(state, definition, now) then
        return true, false
    end
    source = state.resource
    if (not source or not source.object)
        and PNC.NearbyWaterService
        and PNC.NearbyWaterService.ResolveFillSource
    then
        source = PNC.NearbyWaterService.ResolveFillSource(record,
            state.resourceKey)
    end
    itemID = state.activityItemID
        or record.runtime and record.runtime.activityItemID
    if not PNC.WaterContainerService
        or not PNC.WaterContainerService.Refill
    then
        reason = "WATER_CONTAINER_SERVICE_UNAVAILABLE"
    else
        ok, filled, reason = PNC.WaterContainerService.Refill(record, itemID,
            source)
    end
    if ok ~= true then
        -- Refill returns (false, reason) on failure and
        -- (true, amount, itemID) on success. Preserve the transaction
        -- reason when forwarding it to the activity/scene layer.
        reason = reason or filled or "WATER_REFILL_FAILED"
        record.runtime.waterRefillRetryAt = (tonumber(now) or 0)
            + WATER_REFILL_RETRY_COOLDOWN_MS
        Effects.ReportWaterRefillResult(record, state, false,
            reason, {
                stage = "transaction",
                itemID = itemID,
            })
        return false, true, reason
    end
    state.effectAttempted = true
    -- The physical refill is the commit point for the combined action. Clear
    -- thirst only after the bottle and source have both been committed, then
    -- publish a distinct journal event so this automatic drinking is not
    -- confused with consuming the bottle itself.
    Effects.ApplyWaterRefillSuccess(record, state, filled)
    return true, true, "WATER_REFILL_COMPLETE", filled
end

afterDelay = function(state, definition, now)
    state.effectReadyAt = state.effectReadyAt or ((tonumber(now) or 0)
        + (tonumber(definition.effectDelayMs) or 0))
    return (tonumber(now) or 0) >= state.effectReadyAt
end

Internal.ApplyWorldWater = applyWorldWater
Internal.ApplyWaterRefill = applyWaterRefill
Internal.AfterDelay = afterDelay

return Effects
