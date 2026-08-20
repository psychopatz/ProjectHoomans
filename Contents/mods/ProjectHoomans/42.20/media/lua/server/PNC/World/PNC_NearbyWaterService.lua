if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyWaterService = PNC.NearbyWaterService or {}

local Service = PNC.NearbyWaterService
local Locator = PNC.NearbyResourceLocator
local RADIUS = 12
local MAX_DRINK_LITERS = 1
local APPROACH_OFFSETS = {
    { x = 0, y = 1 }, { x = 0, y = -1 },
    { x = 1, y = 0 }, { x = -1, y = 0 },
    { x = 1, y = 1 }, { x = -1, y = 1 },
    { x = 1, y = -1 }, { x = -1, y = -1 },
}

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

function Service.IsCleanFaucet(object)
    if not object then return false end
    if call(object, "isTaintedWater") == true then return false end
    local container = call(object, "getFluidContainer")
    if container and call(container, "isEmpty") == true then return false end
    local amount = tonumber(call(object, "getFluidAmount"))
        or tonumber(call(object, "getWaterAmount"))
        or tonumber(call(container, "getAmount"))
    local waterSource = call(object, "isWaterSource") == true
        or call(container, "isWaterOnlySource") == true
        or call(container, "isWaterSource") == true
        or call(object, "hasFluid") == true
    if amount == 0 then return false end
    if amount == nil and not waterSource then return false end
    if container then
        local primary = call(container, "getPrimaryFluid")
        local fluidName = waterType(primary)
        if fluidName ~= "" and fluidName ~= "Water"
            and fluidName ~= "CarbonatedWater"
        then return false end
        local tainted = Fluid and Fluid.TaintedWater or nil
        if tainted and call(container, "contains", tainted) == true then
            return false
        end
    end
    return waterSource and (amount == nil or amount < 0 or amount > 0)
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

local function listSize(list)
    return list and list.size and list:size() or 0
end

local function listItem(list, index)
    return list and list.get and list:get(index) or nil
end

local function squarePosition(square)
    local x, y, z = call(square, "getX"), call(square, "getY"),
        call(square, "getZ")
    if x == nil or y == nil then return nil end
    return tonumber(x) + 0.5, tonumber(y) + 0.5, tonumber(z) or 0
end

local function facingToward(fromX, fromY, toX, toY)
    local dx, dy = toX - fromX, toY - fromY
    local vertical = dy > 0.25 and "S" or dy < -0.25 and "N" or ""
    local horizontal = dx > 0.25 and "E" or dx < -0.25 and "W" or ""
    return vertical .. horizontal
end

local function canOccupy(x, y, z)
    local internal = PNC.PathService and PNC.PathService.Internal
    if internal and internal.isSquareWalkable then
        local ok, walkable = pcall(internal.isSquareWalkable, x, y, z)
        if ok then return walkable == true end
    end
    local cell = getCell and getCell() or nil
    local square = cell and cell.getGridSquare
        and cell:getGridSquare(math.floor(x), math.floor(y), z) or nil
    if not square then return false end
    if type(square.isFree) == "function" then
        local ok, free = pcall(square.isFree, square, false)
        if ok then return free == true end
    end
    return true
end

local function sourceEntry(object, square, ordinal)
    if not object or not square or not Service.IsCleanFaucet(object) then
        return nil
    end
    local x, y, z = squarePosition(square)
    if not x then return nil end
    return {
        kind = "faucet", object = object, square = square,
        x = x, y = y, z = z,
        key = Locator.ObjectKeyFor(object, x, y, z, ordinal),
    }
end

local function find(record, key)
    local origin = originFor(record)
    if not origin then return nil end
    local itemEntry = Locator.Find(origin, {
        radius = RADIUS, cacheKey = "nearby_water:" .. tostring(record.id),
        accept = function(entry)
            return (not key or entry.key == key) and Service.IsCleanWater(
                entry.item)
        end,
    })
    local faucetEntry = Locator.FindObject(origin, {
        radius = RADIUS, cacheKey = "nearby_water:" .. tostring(record.id),
        accept = function(entry)
            return (not key or entry.key == key)
                and Service.IsCleanFaucet(entry.object)
        end,
    })
    if faucetEntry then
        faucetEntry.kind = "faucet"
        faucetEntry.key = faucetEntry.key or Locator.ObjectKeyFor(
            faucetEntry.object, faucetEntry.x, faucetEntry.y, faucetEntry.z)
    end
    if not itemEntry then return faucetEntry end
    if not faucetEntry or itemEntry.distSq <= faucetEntry.distSq then
        itemEntry.kind = "container"
        return itemEntry
    end
    return faucetEntry
end

function Service.Find(record)
    return find(record)
end

function Service.Resolve(record, key)
    return find(record, tostring(key or ""))
end

function Service.FindAt(record, x, y, z)
    local origin = originFor(record)
    if not origin then return nil end
    x, y, z = math.floor(tonumber(x) or 0), math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    local cell = getCell and getCell() or nil
    local square = cell and cell.getGridSquare
        and cell:getGridSquare(x, y, z) or nil
    local objects = square and call(square, "getObjects") or nil
    for index = 0, listSize(objects) - 1 do
        local entry = sourceEntry(listItem(objects, index), square, index)
        if entry then return entry end
    end
    return nil
end

function Service.BuildApproach(record, entry)
    if not record or not entry then return nil, "WATER_SOURCE_UNAVAILABLE" end
    local sourceX, sourceY, sourceZ = tonumber(entry.x), tonumber(entry.y),
        tonumber(entry.z) or 0
    if sourceX == nil or sourceY == nil then
        return nil, "WATER_SOURCE_POSITION_MISSING"
    end
    local origin = originFor(record)
    local originX = origin and tonumber(call(origin, "getX")) or sourceX
    local originY = origin and tonumber(call(origin, "getY")) or sourceY
    local candidates = {}
    local baseX, baseY = math.floor(sourceX), math.floor(sourceY)
    for _, offset in ipairs(APPROACH_OFFSETS) do
        local x, y = baseX + offset.x + 0.5, baseY + offset.y + 0.5
        if canOccupy(x, y, sourceZ) then
            local dx, dy = x - originX, y - originY
            candidates[#candidates + 1] = {
                x = x, y = y, z = sourceZ,
                interactionFacing = facingToward(x, y, sourceX, sourceY),
                approachKey = tostring(math.floor(x)) .. ":"
                    .. tostring(math.floor(y)) .. ":" .. tostring(sourceZ),
                distSq = dx * dx + dy * dy,
            }
        end
    end
    table.sort(candidates, function(a, b)
        if a.distSq ~= b.distSq then return a.distSq < b.distSq end
        return a.approachKey < b.approachKey
    end)
    if #candidates == 0 then return nil, "WATER_APPROACH_UNAVAILABLE" end
    for _, candidate in ipairs(candidates) do candidate.distSq = nil end
    return candidates[1], candidates
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
    local origin = originFor(record)
    if not origin then return false, "WATER_SOURCE_UNAVAILABLE" end
    local dx, dy = origin:getX() - entry.x, origin:getY() - entry.y
    if dx * dx + dy * dy > (RADIUS + 1) * (RADIUS + 1)
        or math.abs((tonumber(origin:getZ()) or 0) - entry.z) >= 0.5
    then
        return false, "WATER_SOURCE_OUT_OF_RANGE"
    end
    local amount, remaining
    if faucet then
        local sourceContainer = call(entry.object, "getFluidContainer")
        local available = tonumber(call(entry.object, "getFluidAmount"))
            or tonumber(call(entry.object, "getWaterAmount"))
            or tonumber(call(sourceContainer, "getAmount"))
        local requested = math.max(0, tonumber(liters) or 0)
        amount = (available == nil or available < 0)
            and requested or math.min(available, requested)
        if amount <= 0 then return false, "INSUFFICIENT_WATER" end
        if available ~= nil and available >= 0 then
            remaining = math.max(0, available - amount)
            if type(entry.object.moveFluidToTemporaryContainer) == "function"
            then
                local temporary = call(entry.object,
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
        local container = call(entry.item, "getFluidContainer")
        local available = tonumber(call(container, "getAmount")) or 0
        amount = math.max(0, math.min(available, tonumber(liters) or 0))
        remaining = available - amount
        local adjusted = call(container, "adjustAmount", remaining)
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
