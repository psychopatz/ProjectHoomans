if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyWaterService = PNC.NearbyWaterService or {}

local Service = PNC.NearbyWaterService
local Locator = PNC.NearbyResourceLocator
local RADIUS = 12
local MAX_DRINK_LITERS = 1

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function waterType(fluid)
    return tostring(call(fluid, "getFluidTypeString") or "")
end

function Service.IsCleanWater(item)
    local container = call(item, "getFluidContainer")
    if not container or call(container, "isEmpty") == true then return false end
    local primary = call(container, "getPrimaryFluid")
    local fluidName = waterType(primary)
    if fluidName ~= "Water" and fluidName ~= "CarbonatedWater" then
        return false
    end
    local tainted = Fluid and Fluid.TaintedWater or nil
    if tainted and call(container, "contains", tainted) == true then
        return false
    end
    if call(item, "isTaintedWater") == true then return false end
    return (tonumber(call(container, "getAmount")) or 0) > 0
end

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

local function originFor(record)
    local body = liveBody(record)
    if body then return body end
    if not record or record.x == nil or record.y == nil then return nil end
    return {
        getX = function() return record.x end,
        getY = function() return record.y end,
        getZ = function() return record.z or 0 end,
    }
end

local function find(record, key)
    local origin = originFor(record)
    if not origin then return nil end
    return Locator.Find(origin, {
        radius = RADIUS, cacheKey = "nearby_water:" .. tostring(record.id),
        accept = function(entry)
            return (not key or entry.key == key)
                and Service.IsCleanWater(entry.item)
        end,
    })
end

function Service.Find(record)
    return find(record)
end

function Service.Resolve(record, key)
    return find(record, tostring(key or ""))
end

function Service.DesiredLiters(record, available)
    local thirst = PNC.IndividualNeeds and PNC.IndividualNeeds.Get
        and tonumber(PNC.IndividualNeeds.Get(record, "thirst")) or 0
    return math.max(0, math.min(MAX_DRINK_LITERS, thirst * 2,
        tonumber(available) or 0))
end

function Service.Consume(record, entry, liters)
    if not record or not entry or not entry.item then
        return false, "WATER_SOURCE_UNAVAILABLE"
    end
    if not Service.IsCleanWater(entry.item) then
        return false, "WATER_SOURCE_NOT_CLEAN"
    end
    local origin = originFor(record)
    if not origin then return false, "WATER_SOURCE_UNAVAILABLE" end
    local dx, dy = origin:getX() - entry.x, origin:getY() - entry.y
    if dx * dx + dy * dy > (RADIUS + 1) * (RADIUS + 1)
        or math.abs((tonumber(origin:getZ()) or 0) - entry.z) >= 0.5
    then
        return false, "WATER_SOURCE_OUT_OF_RANGE"
    end
    local container = call(entry.item, "getFluidContainer")
    local available = tonumber(call(container, "getAmount")) or 0
    local amount = math.max(0, math.min(available, tonumber(liters) or 0))
    if amount <= 0 then return false, "INSUFFICIENT_WATER" end
    local adjusted = call(container, "adjustAmount", available - amount)
    if adjusted == nil and type(container.adjustAmount) ~= "function" then
        return false, "WATER_CONTAINER_NOT_MUTABLE"
    end
    if type(entry.item.syncItemFields) == "function" then
        pcall(entry.item.syncItemFields, entry.item)
    end
    if sendItemStats then pcall(sendItemStats, entry.item) end
    if Locator.Invalidate then
        Locator.Invalidate("nearby_water:" .. tostring(record.id))
    end
    return true, amount, available - amount
end

Service.RADIUS = RADIUS
Service.MAX_DRINK_LITERS = MAX_DRINK_LITERS

return Service
