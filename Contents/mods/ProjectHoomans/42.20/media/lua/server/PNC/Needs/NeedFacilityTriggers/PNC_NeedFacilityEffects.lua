if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedFacilityEffects = PNC.NeedFacilityEffects or {}

local Effects = PNC.NeedFacilityEffects
local afterDelay
local WORLD_WATER_RETRY_COOLDOWN_MS = 5000
local WATER_REFILL_RETRY_COOLDOWN_MS = 5000

local function resolveActivityOwner(record)
    local core = PNC.Core
    local order = record and record.orderSpec or {}
    local activity = record and record.runtime
        and record.runtime.facilityActivity or {}
    local previousOrder = activity.previousOrder or {}
    local player
    local onlineID = record and record.ownerOnlineID
        or order and order.ownerOnlineID
        or previousOrder.ownerOnlineID
    local username = record and record.ownerUsername
        or order and order.ownerUsername
        or previousOrder.ownerUsername
    if core and core.ResolvePlayerByOnlineID and onlineID ~= nil then
        player = core.ResolvePlayerByOnlineID(onlineID)
        if player then return player end
    end
    if core and core.ResolvePlayerByUsername and username then
        player = core.ResolvePlayerByUsername(username)
        if player then return player end
    end
    if getSpecificPlayer then return getSpecificPlayer(0) end
    return nil
end

-- The initial command reply only says that an activity was accepted. The
-- refill transaction happens later at the scene effect boundary, so publish
-- that final result through the same existing command-result transport.
function Effects.ReportWaterRefillResult(record, state, accepted, reason, details)
    local commandID
    local player
    local payload
    if not state or state.manual ~= true
        or state.manualActivityResultReported == true
    then
        return false
    end
    commandID = tostring(state.manualCommandID or "")
    if commandID == "" then commandID = "manual_refill" end
    state.manualActivityResultReported = true
    payload = {
        commandID = commandID,
        id = record and record.id,
        affected = accepted == true and 1 or 0,
        accepted = accepted == true,
        reason = tostring(reason or (accepted and "commanded"
            or "WATER_REFILL_FAILED")),
        targets = { record and tostring(record.id) or "" },
        requestID = state.manualRequestID,
        commandSource = state.manualCommandSource ~= ""
            and state.manualCommandSource or "colonist_activities",
        details = details,
    }
    player = resolveActivityOwner(record)
    if player and type(sendServerCommand) == "function" then
        sendServerCommand(player, PNC.Const.MODULE,
            PNC.Const.CMD_COMPANION_COMMAND_RESULT, payload)
    elseif type(triggerEvent) == "function" then
        triggerEvent("OnServerCommand", PNC.Const.MODULE,
            PNC.Const.CMD_COMPANION_COMMAND_RESULT, payload)
    end
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo("manual_activity_result npc="
            .. tostring(record and record.id or "")
            .. " command=" .. commandID
            .. " accepted=" .. tostring(accepted == true)
            .. " reason=" .. tostring(payload.reason)
            .. " requestID=" .. tostring(payload.requestID or ""))
    end
    return true
end

local function hasLiveWaterSource(source)
    return source and (source.object ~= nil or source.item ~= nil)
end

local function worldWaterFailure(record, now, reason)
    local runtime = record and record.runtime or nil
    local current = tonumber(now)
    if not current and PNC.Core and PNC.Core.Now then
        current = tonumber(PNC.Core.Now())
    end
    if runtime then
        runtime.worldWaterRetryAt = (current or 0)
            + WORLD_WATER_RETRY_COOLDOWN_MS
    end
    return false, true, reason
end

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
    if PNC.IndividualNeeds and PNC.IndividualNeeds.Commands
        and PNC.IndividualNeeds.Commands.ApplyDrink
    then
        PNC.IndividualNeeds.Commands.ApplyDrink(record, {
            thirst = (tonumber(consumed) or 0) / 2,
        }, "world_water_drink")
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
        record.runtime.waterRefillRetryAt = (tonumber(now) or 0)
            + WATER_REFILL_RETRY_COOLDOWN_MS
        Effects.ReportWaterRefillResult(record, state, false,
            reason or "WATER_REFILL_FAILED", {
                stage = "transaction",
                itemID = itemID,
            })
        return false, true, reason or "WATER_REFILL_FAILED"
    end
    state.effectAttempted = true
    return true, true, "WATER_REFILL_COMPLETE", filled
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
                recoveryPerGameHour = definition.recoveryPerGameHour,
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
