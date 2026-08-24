if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyWaterService = PNC.NearbyWaterService or {}
PNC.NearbyWaterServiceInternal =
    PNC.NearbyWaterServiceInternal or {}

local Service = PNC.NearbyWaterService
local H = PNC.NearbyWaterServiceInternal
local Locator = PNC.NearbyResourceLocator
local RADIUS = 12
local MAX_DRINK_LITERS = 1
local APPROACH_OFFSETS = {
    { x = 0, y = 1 }, { x = 0, y = -1 },
    { x = 1, y = 0 }, { x = -1, y = 0 },
    { x = 1, y = 1 }, { x = -1, y = 1 },
    { x = 1, y = -1 }, { x = -1, y = -1 },
}

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
    if faucet then
        local sourceContainer = H.Call(entry.object, "getFluidContainer")
        local available = tonumber(H.Call(entry.object, "getFluidAmount"))
            or tonumber(H.Call(entry.object, "getWaterAmount"))
            or tonumber(H.Call(sourceContainer, "getAmount"))
        local requested = math.max(0, tonumber(liters) or 0)
        amount = (available == nil or available < 0)
            and requested or math.min(available, requested)
        if amount <= 0 then return false, "INSUFFICIENT_WATER" end
        if available ~= nil and available >= 0 then
            remaining = math.max(0, available - amount)
            if type(entry.object.moveFluidToTemporaryContainer) == "function"
            then
                local temporary = H.Call(entry.object,
                    "moveFluidToTemporaryContainer", amount)
                if not temporary then
                    return false, "WATER_FAUCET_NOT_MUTABLE"
                end
                if FluidContainer and FluidContainer.DisposeContainer then
                    pcall(FluidContainer.DisposeContainer, temporary)
                end
            elseif sourceContainer
                and type(sourceContainer.adjustAmount) == "function"
            then
                pcall(sourceContainer.adjustAmount, sourceContainer, remaining)
            elseif type(entry.object.setWaterAmount) == "function" then
                pcall(entry.object.setWaterAmount, entry.object, remaining)
            elseif type(entry.object.useWater) == "function" then
                pcall(entry.object.useWater, entry.object, amount)
            else
                return false, "WATER_FAUCET_NOT_MUTABLE"
            end
        else
            remaining = available
        end
    else
        local container = H.Call(entry.item, "getFluidContainer")
        local available = tonumber(H.Call(container, "getAmount")) or 0
        amount = math.max(0, math.min(available, tonumber(liters) or 0))
        remaining = available - amount
        local adjusted = H.Call(container, "adjustAmount", remaining)
        if adjusted == nil and type(container.adjustAmount) ~= "function" then
            return false, "WATER_CONTAINER_NOT_MUTABLE"
        end
        if type(entry.item.syncItemFields) == "function" then
            pcall(entry.item.syncItemFields, entry.item)
        end
        if sendItemStats then pcall(sendItemStats, entry.item) end
    end
    if amount <= 0 then return false, "INSUFFICIENT_WATER" end
    if Locator.Invalidate then
        Locator.Invalidate("nearby_water:" .. tostring(record.id))
    end
    return true, amount, remaining
end

Service.RADIUS = RADIUS
Service.MAX_DRINK_LITERS = MAX_DRINK_LITERS

return Service

