if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyWaterService = PNC.NearbyWaterService or {}
PNC.NearbyWaterServiceInternal =
    PNC.NearbyWaterServiceInternal or {}

local Service = PNC.NearbyWaterService
local H = PNC.NearbyWaterServiceInternal
local Locator = PNC.NearbyResourceLocator
-- Discovery is intentionally wider than interaction. NPCs can acquire a
-- nearby source from a useful search window, then path to an adjacent tile;
-- consumption still validates a short server-side interaction range.
local DISCOVERY_RADIUS = 24
local COMMIT_RADIUS = 3
local MAX_DRINK_LITERS = 1
local APPROACH_OFFSETS = {
    { x = 0, y = 1 }, { x = 0, y = -1 },
    { x = 1, y = 0 }, { x = -1, y = 0 },
    { x = 1, y = 1 }, { x = -1, y = 1 },
    { x = 1, y = -1 }, { x = -1, y = -1 },
}

Service.DISCOVERY_RADIUS = DISCOVERY_RADIUS
Service.COMMIT_RADIUS = COMMIT_RADIUS
Service.MAX_DRINK_LITERS = MAX_DRINK_LITERS
Service.MAX_REFILL_LITERS = 4
-- IsoObject#getFluidAmount() returns 10000 for Build 42's infinite piped
-- water sources. It is deliberately not zero, so treating only nil/zero as
-- infinite makes a sink look finite and causes source-debit verification to
-- reject an otherwise successful transfer.
Service.INFINITE_SOURCE_AMOUNT = 9999

function H.Call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

function H.TryCall(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return false, nil end
    local ok, value = pcall(fn, object, ...)
    return ok, value
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

function Service.IsInfiniteFaucet(object)
    if not object then return false end
    local container = H.Call(object, "getFluidContainer")
    local marked = H.Call(object, "isWaterSource") == true
        or H.Call(container, "isWaterOnlySource") == true
        or H.Call(container, "isWaterSource") == true
        or H.Call(object, "hasFluid") == true
    if not marked then return false end
    local amount = tonumber(H.Call(object, "getFluidAmount"))
        or tonumber(H.Call(object, "getWaterAmount"))
        or tonumber(H.Call(container, "getAmount"))
    return amount == nil or amount <= 0
        or amount >= Service.INFINITE_SOURCE_AMOUNT
end

function Service.IsCleanFaucet(object)
    if not object then return false end
    if H.Call(object, "isTaintedWater") == true then return false end
    local container = H.Call(object, "getFluidContainer")
    local waterSource = H.Call(object, "isWaterSource") == true
        or H.Call(container, "isWaterOnlySource") == true
        or H.Call(container, "isWaterSource") == true
        or H.Call(object, "hasFluid") == true
        or H.Call(object, "getFluidAmount") ~= nil
        or H.Call(object, "getWaterAmount") ~= nil
    -- A sink can expose an empty FluidContainer while the world object itself
    -- remains an infinite water source. Only reject an empty container when no
    -- source marker exists on the object/container.
    if container and H.Call(container, "isEmpty") == true
        and not waterSource
    then return false end
    local amount = tonumber(H.Call(object, "getFluidAmount"))
        or tonumber(H.Call(object, "getWaterAmount"))
        or tonumber(H.Call(container, "getAmount"))
    if amount == 0 and not Service.IsInfiniteFaucet(object) then return false end
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
    return waterSource and (amount == nil or amount <= 0
        and Service.IsInfiniteFaucet(object) or amount > 0)
end

-- Drinkability and refillability are separate capabilities. A sink, well,
-- or pump may expose enough state to drink from while not exposing any safe
-- way to transfer water into an inventory container. Keep this predicate in
-- the shared water service so discovery, planning, and commit use the same
-- source contract.
function Service.IsFillableFaucet(object)
    local container
    if not Service.IsCleanFaucet(object) then return false end
    container = H.Call(object, "getFluidContainer")
    return type(object.transferFluidTo) == "function"
        or type(object.moveFluidToTemporaryContainer) == "function"
        or type(object.useFluid) == "function"
        or type(object.useWater) == "function"
        or type(object.setWaterAmount) == "function"
        or container and type(container.adjustAmount) == "function"
end

return Service
