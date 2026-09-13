if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyWaterService = PNC.NearbyWaterService or {}
PNC.NearbyWaterServiceInternal =
    PNC.NearbyWaterServiceInternal or {}

local Service = PNC.NearbyWaterService
local H = PNC.NearbyWaterServiceInternal
local Locator = PNC.NearbyResourceLocator
local RADIUS = Service.COMMIT_RADIUS or 3
local MAX_DRINK_LITERS = 1
local APPROACH_OFFSETS = {
    { x = 0, y = 1 }, { x = 0, y = -1 },
    { x = 1, y = 0 }, { x = -1, y = 0 },
    { x = 1, y = 1 }, { x = -1, y = 1 },
    { x = 1, y = -1 }, { x = -1, y = -1 },
}

local EPSILON = 0.0001

local function sourceAmount(object, container)
    if Service.IsInfiniteFaucet and Service.IsInfiniteFaucet(object) then
        return -1
    end
    return tonumber(H.Call(object, "getFluidAmount"))
        or tonumber(H.Call(object, "getWaterAmount"))
        or tonumber(H.Call(container, "getAmount"))
end

local function amountMatches(object, container, expected)
    local actual = sourceAmount(object, container)
    return actual ~= nil and math.abs(actual - expected) <= EPSILON
end

local function syncSource(object)
    if object and type(object.sync) == "function" then
        pcall(object.sync, object)
    end
end

local function restoreAmount(object, container, amount)
    local ok
    if amount == nil then return true end
    if container and type(container.adjustAmount) == "function" then
        ok = H.TryCall(container, "adjustAmount", amount)
        if ok and amountMatches(object, container, amount) then
            syncSource(object)
            return true
        end
    end
    if object and type(object.setWaterAmount) == "function" then
        ok = H.TryCall(object, "setWaterAmount", amount)
        if ok and amountMatches(object, container, amount) then
            syncSource(object)
            return true
        end
    end
    return false
end

local function disposeTemporary(temporary)
    if temporary and FluidContainer
        and FluidContainer.DisposeContainer
    then
        pcall(FluidContainer.DisposeContainer, temporary)
    end
end

local function temporaryAmount(temporary)
    return tonumber(H.Call(temporary, "getAmount"))
        or tonumber(temporary and temporary.amount)
end

local function mutateFaucet(object, container, amount, remaining, before)
    local ok
    local consumed
    local temporary
    local after
    local attempted
    local function failedMutation(api)
        attempted = api
        after = sourceAmount(object, container)
        if after ~= nil and math.abs(after - before) > EPSILON
            and not restoreAmount(object, container, before)
        then
            return false, "WATER_FAUCET_ROLLBACK_FAILED", api
        end
        return nil
    end

    -- Build 42.20's IsoObject exposes useFluid(float), which consumes a
    -- finite faucet amount and synchronizes the world object. This is the
    -- preferred finite-source adapter; useWater is not a Build 42 API.
    if type(object.useFluid) == "function" then
        ok, consumed = H.TryCall(object, "useFluid", amount)
        after = sourceAmount(object, container)
        if ok and tonumber(consumed) and tonumber(consumed) >= amount - EPSILON
            and amountMatches(object, container, remaining)
        then
            return true, "useFluid", tonumber(consumed)
        end
        local failure, failureReason, api = failedMutation("useFluid")
        if failure == false then return false, failureReason, api end
    end
    if type(object.moveFluidToTemporaryContainer) == "function" then
        ok, temporary = H.TryCall(object,
            "moveFluidToTemporaryContainer", amount)
        after = sourceAmount(object, container)
        if ok and (temporaryAmount(temporary) == nil
                or temporaryAmount(temporary) >= amount - EPSILON)
            and amountMatches(object, container, remaining)
        then
            disposeTemporary(temporary)
            return true, "moveFluidToTemporaryContainer", amount
        end
        disposeTemporary(temporary)
        local failure, failureReason, api = failedMutation(
            "moveFluidToTemporaryContainer")
        if failure == false then return false, failureReason, api end
    end
    if container and type(container.adjustAmount) == "function" then
        attempted = "fluidContainer.adjustAmount"
        ok = H.TryCall(container, "adjustAmount", remaining)
        if ok and amountMatches(object, container, remaining) then
            syncSource(object)
            return true, attempted, amount
        end
        local failure, failureReason, api = failedMutation(attempted)
        if failure == false then return false, failureReason, api end
    end
    if type(object.setWaterAmount) == "function" then
        ok = H.TryCall(object, "setWaterAmount", remaining)
        if ok and amountMatches(object, container, remaining) then
            syncSource(object)
            return true, "setWaterAmount", amount
        end
        local failure, failureReason, api = failedMutation("setWaterAmount")
        if failure == false then return false, failureReason, api end
    end
    if type(object.useWater) == "function" then
        ok, consumed = H.TryCall(object, "useWater", amount)
        if ok and amountMatches(object, container, remaining) then
            return true, "useWater", tonumber(consumed) or amount
        end
        local failure, failureReason, api = failedMutation("useWater")
        if failure == false then return false, failureReason, api end
    end
    return false, "WATER_FAUCET_NOT_MUTABLE", attempted
end

local function mutateItem(container, amount, remaining, before)
    local ok, consumed
    local attempted
    if type(container.removeFluid) == "function" then
        attempted = "fluidContainer.removeFluid"
        -- PZ 42's ItemRecord path uses the two-argument overload. Keep the
        -- one-argument fallback for test doubles and older fluid containers,
        -- but prefer the engine signature so item drinking actually mutates.
        ok, consumed = H.TryCall(container, "removeFluid", amount, false)
        if not ok then
            ok, consumed = H.TryCall(container, "removeFluid", amount)
        end
        if ok and consumed and type(consumed.release) == "function" then
            pcall(consumed.release, consumed)
        end
        if ok and amountMatches(nil, container, remaining) then
            return true, attempted, amount
        end
        if not restoreAmount(nil, container, before) then
            return false, "WATER_CONTAINER_ROLLBACK_FAILED", attempted
        end
    end
    if type(container.adjustAmount) == "function" then
        attempted = "fluidContainer.adjustAmount"
        ok = H.TryCall(container, "adjustAmount", remaining)
        if ok and amountMatches(nil, container, remaining) then
            return true, attempted, amount
        end
        if not restoreAmount(nil, container, before) then
            return false, "WATER_CONTAINER_ROLLBACK_FAILED", attempted
        end
    end
    return false, "WATER_CONTAINER_NOT_MUTABLE", attempted
end

function Service.DesiredLiters(record, available)
    local thirst = PNC.IndividualNeeds and PNC.IndividualNeeds.Get
        and tonumber(PNC.IndividualNeeds.Get(record, "thirst")) or 0
    local amount = tonumber(available)
    if amount == nil or amount < 0 then amount = MAX_DRINK_LITERS end
    return math.max(0, math.min(MAX_DRINK_LITERS, thirst * 2, amount))
end

function Service.Consume(record, entry, liters)
    if not record or not entry then
        return false, "WATER_SOURCE_UNAVAILABLE"
    end
    local faucet = entry.kind == "faucet" or entry.object ~= nil
    if faucet then
        if not Service.IsCleanFaucet(entry.object) then
            return false, "WATER_SOURCE_NOT_CLEAN"
        end
    elseif not entry.item or not Service.IsCleanWater(entry.item) then
        return false, "WATER_SOURCE_NOT_CLEAN" end
    local origin = H.OriginFor(record)
    if not origin then return false, "WATER_SOURCE_UNAVAILABLE" end
    local dx, dy = origin:getX() - entry.x, origin:getY() - entry.y
    if dx * dx + dy * dy > (RADIUS + 1) * (RADIUS + 1)
        or math.abs((tonumber(origin:getZ()) or 0) - entry.z) >= 0.5
    then
        return false, "WATER_SOURCE_OUT_OF_RANGE"
    end
    local amount, remaining
    local details = {}
    if faucet then
        local sourceContainer = H.Call(entry.object, "getFluidContainer")
        local available = sourceAmount(entry.object, sourceContainer)
        local requested = math.max(0, tonumber(liters) or 0)
        details.sourceAmountBefore = available
        amount = (available == nil or available < 0)
            and requested or math.min(available, requested)
        if amount <= 0 then return false, "INSUFFICIENT_WATER" end
        if available ~= nil and available >= 0 then
            remaining = math.max(0, available - amount)
            local mutationOK, mutationAPI, mutationAmount = mutateFaucet(
                entry.object, sourceContainer, amount, remaining, available)
            details.sourceMutationAPI = mutationAPI
            details.sourceConsumedAmount = mutationAmount
            details.sourceAmountAfter = sourceAmount(entry.object,
                sourceContainer)
            if mutationOK ~= true
            then
                details.sourceMutationAPI = mutationAmount
                details.sourceConsumptionResult = mutationAPI
                return false, mutationAPI or "WATER_FAUCET_NOT_MUTABLE",
                    0, details
            end
        else
            remaining = available
            details.sourceMutationAPI = "infinite_source_no_debit"
            details.sourceConsumedAmount = amount
            details.sourceAmountAfter = sourceAmount(entry.object,
                sourceContainer)
        end
    else
        local container = H.Call(entry.item, "getFluidContainer")
        local available = tonumber(H.Call(container, "getAmount")) or 0
        amount = math.max(0, math.min(available, tonumber(liters) or 0))
        remaining = available - amount
        details.sourceAmountBefore = available
        if amount <= 0 then return false, "INSUFFICIENT_WATER" end
        local mutationOK, mutationAPI, mutationAmount = mutateItem(
            container, amount, remaining, available)
        details.sourceMutationAPI = mutationAPI
        details.sourceConsumedAmount = mutationAmount
        details.sourceAmountAfter = tonumber(H.Call(container, "getAmount"))
        if mutationOK ~= true then
            details.sourceMutationAPI = mutationAmount
            details.sourceConsumptionResult = mutationAPI
            return false, mutationAPI or "WATER_CONTAINER_NOT_MUTABLE", 0,
                details
        end
        if type(entry.item.syncItemFields) == "function" then
            pcall(entry.item.syncItemFields, entry.item)
        end
        if sendItemStats then pcall(sendItemStats, entry.item) end
    end
    if amount <= 0 then return false, "INSUFFICIENT_WATER" end
    if Locator.Invalidate then
        Locator.Invalidate("world_water:" .. tostring(record.id))
    end
    if Service.InvalidateHydrationPlan then
        Service.InvalidateHydrationPlan(record)
    end
    return true, amount, remaining, details
end

Service.INTERACTION_RADIUS = RADIUS
-- Keep the public legacy field as the discovery radius for callers that use
-- it to size a search, while exposing the stricter commit radius separately.
Service.RADIUS = Service.DISCOVERY_RADIUS or RADIUS
Service.MAX_DRINK_LITERS = MAX_DRINK_LITERS

return Service
