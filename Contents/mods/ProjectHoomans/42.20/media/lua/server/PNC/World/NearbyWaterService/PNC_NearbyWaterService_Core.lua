if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyWaterService = PNC.NearbyWaterService or {}
PNC.NearbyWaterServiceInternal =
    PNC.NearbyWaterServiceInternal or {}

local Service = PNC.NearbyWaterService
local H = PNC.NearbyWaterServiceInternal
local Locator = PNC.NearbyResourceLocator

PNC.WaterHydrationPolicy = PNC.WaterHydrationPolicy or {}
local Policy = PNC.WaterHydrationPolicy

function Policy.IsManualOverride(options)
    if type(options) ~= "table" then return false end
    if options.manualOverride == true then return true end
    -- Preserve already-running manual water activities from older saves that
    -- predate the explicit manualOverride field. Do not broaden this to every
    -- manual facility action: only the refill capability bypasses the water
    -- location policy.
    return options.manual == true
        and (options.resourceKind == "water_refill"
            or options.capability == "survival.fill.water")
end

function Policy.GetContext(record, options)
    if not record or record.alive == false then
        return nil, "NPC_UNAVAILABLE"
    end
    if Policy.IsManualOverride(options) then
        return {
            kind = "MANUAL_OVERRIDE",
            manualOverride = true,
        }
    end
    local routes = PNC.NeedFacilityAwayRoutes
    if routes and routes.IsCampContext
        and routes.IsCampContext(record) == true
    then
        return { kind = "CAMP" }
    end
    local home = PNC.HomeDutyService
    local base = home and home.GetBase and home.GetBase(record) or nil
    if base and home.IsAtHome
        and home.IsAtHome(record, base.id) == true
    then
        return { kind = "HOME", baseId = base.id }
    end
    return nil, "WATER_LOCATION_REQUIRED"
end

function Policy.IsTargetAllowed(record, context, target)
    if not context or type(target) ~= "table" then return false end
    if context.manualOverride == true then return true end
    if context.kind == "HOME" then
        local home = PNC.HomeDutyService
        return home and home.IsWithinHome
            and home.IsWithinHome(record, target.x, target.y, target.z,
                context.baseId) == true
            or false
    end
    if context.kind == "CAMP" then
        local camp = PNC.CampResourceService
        return camp and camp.IsWithinCamp
            and camp.IsWithinCamp(record, target) == true
            or false
    end
    return false
end

function Policy.RestrictTargets(record, context, source, target, approaches)
    if context and context.manualOverride == true then
        return target, approaches
    end
    if not Policy.IsTargetAllowed(record, context, source) then
        return nil, nil, "WATER_SOURCE_OUTSIDE_ALLOWED_CONTEXT"
    end
    local candidates = {}
    local selected
    local function append(candidate)
        if type(candidate) ~= "table"
            or not Policy.IsTargetAllowed(record, context, candidate)
        then
            return
        end
        candidates[#candidates + 1] = candidate
        if not selected then selected = candidate end
    end
    append(target)
    if type(approaches) == "table" then
        for index = 1, #approaches do
            append(approaches[index])
        end
    end
    if not selected then
        return nil, nil, "WATER_APPROACH_OUTSIDE_ALLOWED_CONTEXT"
    end
    return selected, candidates
end

function Policy.AllowsActivity(record, activity)
    if Policy.IsManualOverride(activity) then
        return true, "MANUAL_OVERRIDE"
    end
    local context, reason = Policy.GetContext(record)
    if not context then return false, reason end
    local expected = tostring(activity and activity.waterContextKind or "")
    if expected ~= "" and expected ~= context.kind then
        return false, "WATER_CONTEXT_CHANGED"
    end
    local expectedBase = tostring(activity and activity.waterBaseId or "")
    if expected == "HOME" and expectedBase ~= ""
        and tostring(context.baseId or "") ~= expectedBase
    then
        return false, "WATER_CONTEXT_CHANGED"
    end
    return true, context.kind
end
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
