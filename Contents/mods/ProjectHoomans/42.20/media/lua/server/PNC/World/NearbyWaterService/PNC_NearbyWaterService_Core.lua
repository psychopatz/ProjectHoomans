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

function H.Call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

function H.WaterType(fluid)
    return tostring(H.Call(fluid, "getFluidTypeString") or "")
end

function Service.IsCleanWater(item)
    local container = H.Call(item, "getFluidContainer")
    if not container or H.Call(container, "isEmpty") == true then return false end
    local primary = H.Call(container, "getPrimaryFluid")
    local fluidName = H.WaterType(primary)
    if fluidName ~= "Water" and fluidName ~= "CarbonatedWater" then
        return false
    end
    local tainted = Fluid and Fluid.TaintedWater or nil
    if tainted and H.Call(container, "contains", tainted) == true then
        return false
    end
    if H.Call(item, "isTaintedWater") == true then return false end
    return (tonumber(H.Call(container, "getAmount")) or 0) > 0
end

function Service.IsCleanFaucet(object)
    if not object then return false end
    if H.Call(object, "isTaintedWater") == true then return false end
    local container = H.Call(object, "getFluidContainer")
    if container and H.Call(container, "isEmpty") == true then return false end
    local amount = tonumber(H.Call(object, "getFluidAmount"))
        or tonumber(H.Call(object, "getWaterAmount"))
        or tonumber(H.Call(container, "getAmount"))
    local waterSource = H.Call(object, "isWaterSource") == true
        or H.Call(container, "isWaterOnlySource") == true
        or H.Call(container, "isWaterSource") == true
        or H.Call(object, "hasFluid") == true
    if amount == 0 then return false end
    if amount == nil and not waterSource then return false end
    if container then
        local primary = H.Call(container, "getPrimaryFluid")
        local fluidName = H.WaterType(primary)
        if fluidName ~= "" and fluidName ~= "Water"
            and fluidName ~= "CarbonatedWater"
        then return false end
        local tainted = Fluid and Fluid.TaintedWater or nil
        if tainted and H.Call(container, "contains", tainted) == true then
            return false
        end
    end
    return waterSource and (amount == nil or amount < 0 or amount > 0)
end

return Service

