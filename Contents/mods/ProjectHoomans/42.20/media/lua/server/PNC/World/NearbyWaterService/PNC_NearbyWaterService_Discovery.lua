if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyWaterService = PNC.NearbyWaterService or {}
PNC.NearbyWaterServiceInternal =
    PNC.NearbyWaterServiceInternal or {}

local Service = PNC.NearbyWaterService
local H = PNC.NearbyWaterServiceInternal
local Locator = PNC.NearbyResourceLocator
local RADIUS = Service.DISCOVERY_RADIUS or 20
local DISCOVERY_CACHE_MS = 5000
local HYDRATION_PLAN_CACHE_MS = 5000

H.HydrationPlanCache = H.HydrationPlanCache or {}
local APPROACH_OFFSETS = {
    { x = 0, y = 1 }, { x = 0, y = -1 },
    { x = 1, y = 0 }, { x = -1, y = 0 },
    { x = 1, y = 1 }, { x = -1, y = 1 },
    { x = 1, y = -1 }, { x = -1, y = -1 },
}

function H.SourceEntry(object, square, ordinal)
    if not object or not square or not Service.IsCleanFaucet(object) then
        return nil
    end
    local x, y, z = H.SquarePosition(square)
    if not x then return nil end
    return {
        kind = "faucet", object = object, square = square,
        x = x, y = y, z = z,
        key = Locator.ObjectKeyFor(object, x, y, z, ordinal),
        capabilities = {
            drink = true,
            fill = Service.IsFillableFaucet(object) == true,
        },
    }
end

function H.WorldAvailability(origin)
    if not origin then return "origin_missing" end
    local cell = getCell and getCell() or nil
    if not cell or type(cell.getGridSquare) ~= "function" then
        return "world_unavailable"
    end
    local x, y, z = H.Call(origin, "getX"), H.Call(origin, "getY"),
        H.Call(origin, "getZ") or 0
    if x == nil or y == nil then return "origin_missing" end
    local ok, square = pcall(cell.getGridSquare, cell, math.floor(x),
        math.floor(y), math.floor(z))
    return ok and square and "loaded" or "unloaded"
end

local function noSourceReason(origin)
    local availability = H.WorldAvailability(origin)
    if availability == "origin_missing" then return "WATER_ORIGIN_UNAVAILABLE" end
    if availability == "unloaded" then return "WATER_WORLD_UNLOADED" end
    if availability == "world_unavailable" then return "WATER_WORLD_UNAVAILABLE" end
    return "WATER_SOURCE_UNAVAILABLE"
end

local function sourceAccepts(object, mode)
    if mode == "fill" then
        return Service.IsFillableFaucet(object) == true
    end
    return Service.IsCleanFaucet(object) == true
end

local function attachCapabilities(entry)
    if not entry then return nil end
    if entry.object then
        entry.kind = "faucet"
        entry.capabilities = {
            drink = Service.IsCleanFaucet(entry.object) == true,
            fill = Service.IsFillableFaucet(entry.object) == true,
        }
    elseif entry.item then
        entry.kind = "container"
        entry.capabilities = { drink = true, fill = false }
    end
    return entry
end

function H.FindInternal(record, key, mode)
    local origin = H.OriginFor(record)
    if not origin then return nil, noSourceReason(origin) end
    local itemEntry
    if mode ~= "fill" then
        itemEntry = Locator.Find(origin, {
            radius = RADIUS, cacheMs = DISCOVERY_CACHE_MS,
            cacheKey = "world_water:" .. tostring(record.id),
            accept = function(entry)
                return (not key or entry.key == key)
                    and Service.IsCleanWater(entry.item)
            end,
        })
    end
    local faucetEntry = Locator.FindObject(origin, {
        radius = RADIUS, cacheMs = DISCOVERY_CACHE_MS,
        cacheKey = mode == "fill"
            and "world_water_fill:" .. tostring(record.id)
            or "world_water:" .. tostring(record.id),
        accept = function(entry)
            return (not key or entry.key == key)
                and sourceAccepts(entry.object, mode)
        end,
    })
    if faucetEntry then
        faucetEntry.key = faucetEntry.key or Locator.ObjectKeyFor(
            faucetEntry.object, faucetEntry.x, faucetEntry.y, faucetEntry.z)
        attachCapabilities(faucetEntry)
    end
    if not itemEntry then
        if faucetEntry then return faucetEntry end
        return nil, noSourceReason(origin)
    end
    if not faucetEntry or itemEntry.distSq <= faucetEntry.distSq then
        return attachCapabilities(itemEntry)
    end
    return faucetEntry
end

function Service.FindSource(record, mode, key)
    local value = tostring(key or "")
    return H.FindInternal(record, value ~= "" and value or nil,
        mode == "fill" and "fill" or "drink")
end

function Service.Find(record, key)
    return Service.FindSource(record, "drink", key)
end

function Service.FindFillSource(record, key)
    return Service.FindSource(record, "fill", key)
end

function Service.FindWithStatus(record, key)
    return Service.FindSource(record, "drink", key)
end

local function optionalKey(key)
    local value = tostring(key or "")
    return value ~= "" and value or nil
end

function Service.Resolve(record, key)
    return Service.FindSource(record, "drink", optionalKey(key))
end

function Service.ResolveFillSource(record, key)
    return Service.FindSource(record, "fill", optionalKey(key))
end

local function inventoryState(record)
    local inventory = PNC.Inventory
    local inv
    if not inventory then return nil, nil, nil end
    if inventory.EnsureRecordInventory then
        inv = inventory.EnsureRecordInventory(record)
    else
        inv = record and record.inventory
    end
    return inventory, inv, tonumber(inv and inv.revision) or 0
end

local function originSignature(record)
    local origin = H.OriginFor(record)
    if not origin then return nil end
    return math.floor(tonumber(H.Call(origin, "getX")) or 0),
        math.floor(tonumber(H.Call(origin, "getY")) or 0),
        math.floor(tonumber(H.Call(origin, "getZ")) or 0)
end

local function cachedPlanValid(cached, record, revision, now, x, y, z,
        mode)
    if not cached or cached.record ~= record then return false end
    if cached.inventoryRevision ~= revision
        or cached.originX ~= x or cached.originY ~= y or cached.originZ ~= z
    then return false end
    if mode ~= "hydrate" or cached.action ~= "drink_container"
        and now - (tonumber(cached.createdAt) or 0)
            > HYDRATION_PLAN_CACHE_MS
    then return false end
    return true
end

local function genericPersonalDrink(record)
    local service = PNC.NPCSupplyService
    local needs = PNC.IndividualNeeds
    local thirst = needs and needs.Get and needs.Get(record, "thirst")
        or record and record.needs and record.needs.thirst
    local available
    local fullType
    if not service or not service.HasPersonalSupply then return nil end
    available, fullType = service.HasPersonalSupply(record, "HYDRATION", {
        hunger = 0,
        thirst = math.max(0.001, tonumber(thirst) or 0.001),
    })
    if not available then return nil end
    return {
        action = "drink_container",
        resourceKind = "personal_drink",
        capability = "survival.drink.inventory",
        activityItemFullType = fullType,
    }
end

function Service.InvalidateHydrationPlan(record)
    local id = record and tostring(record.id or "") or ""
    if id ~= "" then
        H.HydrationPlanCache[id] = nil
        H.HydrationPlanCache[id .. "|hydrate"] = nil
        H.HydrationPlanCache[id .. "|refill"] = nil
    end
end

-- Resolve the complete hydration decision once. The returned plan is kept in
-- the service cache, not in save data, because source/item handles are live
-- Java objects. The activity stores only stable item/source identifiers.
function Service.ResolveHydrationPlan(record, mode)
    local inventory
    local inv
    local revision
    local planningMode = tostring(mode or "") == "refill"
        and "refill" or "hydrate"
    local now = H.NowMs and H.NowMs() or 0
    local x, y, z = originSignature(record)
    local id = record and tostring(record.id or "") or ""
    local cacheKey = id ~= "" and id .. "|" .. planningMode or nil
    local cached
    local item
    local description
    local source
    local sourceReason
    local plan
    local noPlanReason = planningMode == "refill"
        and "WATER_CONTAINER_NOT_REFILLABLE" or "HYDRATION_UNAVAILABLE"
    if not record or record.alive == false then
        return nil, "NPC_UNAVAILABLE"
    end
    inventory, inv, revision = inventoryState(record)
    cached = cacheKey and H.HydrationPlanCache[cacheKey] or nil
    if cachedPlanValid(cached, record, revision, now, x, y, z, planningMode)
    then
        if cached.noPlan == true then
            return nil, cached.reason or "HYDRATION_UNAVAILABLE"
        end
        return cached
    end
    if inventory and inventory.ReconcileWaterContainer then
        inventory.ReconcileWaterContainer(record)
        inv = record.inventory or inv
        revision = tonumber(inv and inv.revision) or revision
    end
    if inventory then
        item = inventory.GetWaterContainer
            and inventory.GetWaterContainer(record)
            or inventory.FindWaterContainer
            and inventory.FindWaterContainer(record)
            or nil
        description = item and inventory.DescribeLiquidContainer
            and inventory.DescribeLiquidContainer(item) or nil
        if planningMode == "refill" then
            local freeCapacity = description and
                (tonumber(description.freeCapacity) or
                    (tonumber(description.capacity) or 0)
                        - (tonumber(description.amount) or 0)) or 0
            if not item or not description then
                noPlanReason = "WATER_CONTAINER_NOT_REFILLABLE"
            elseif freeCapacity <= 0 then
                noPlanReason = "WATER_CONTAINER_FULL"
            elseif not description.canFill then
                noPlanReason = "WATER_CONTAINER_NOT_REFILLABLE"
            else
                source, sourceReason = Service.FindSource(record, "fill")
                if source then
                    plan = {
                        action = "fill_container",
                        resourceKind = "water_refill",
                        capability = "survival.fill.water",
                        container = item,
                        containerID = item.id,
                        activityItemID = item.id,
                        activityItemFullType = item.type,
                        containerDescription = description,
                        source = source,
                        sourceKey = source.key,
                    }
                else
                    noPlanReason = sourceReason
                        or "WATER_FILL_SOURCE_UNAVAILABLE"
                end
            end
        elseif item and description and description.canDrink then
            plan = {
                action = "drink_container",
                resourceKind = "personal_drink",
                capability = "survival.drink.inventory",
                container = item,
                containerID = item.id,
                activityItemID = item.id,
                activityItemFullType = item.type,
            }
        elseif item and description and description.canFill then
            source, sourceReason = Service.FindSource(record, "fill")
            if source then
                plan = {
                    action = "fill_container",
                    resourceKind = "water_refill",
                    capability = "survival.fill.water",
                    container = item,
                    containerID = item.id,
                    activityItemID = item.id,
                    activityItemFullType = item.type,
                    containerDescription = description,
                    source = source,
                    sourceKey = source.key,
                }
            else
                noPlanReason = sourceReason or noPlanReason
            end
        end
    end
    if planningMode ~= "refill" then
        if not plan then plan = genericPersonalDrink(record) end
        if not plan and (not item or not description) then
            source = Service.FindSource(record, "drink")
            if source then
                plan = {
                    action = "drink_source",
                    resourceKind = "world_water",
                    capability = "survival.drink.world",
                    source = source,
                    sourceKey = source.key,
                }
            end
        elseif not plan and item and description then
            -- An empty container must not prevent hydration if the source is
            -- drinkable but cannot be used as a refill facility.
            source = Service.FindSource(record, "drink")
            if source then
                plan = {
                    action = "drink_source",
                    resourceKind = "world_water",
                    capability = "survival.drink.world",
                    source = source,
                    sourceKey = source.key,
                    containerID = item.id,
                }
            end
        end
    end
    if not plan then
        if cacheKey then
            H.HydrationPlanCache[cacheKey] = {
                record = record,
                action = "none",
                noPlan = true,
                inventoryRevision = revision,
                originX = x, originY = y, originZ = z,
                createdAt = now,
                reason = noPlanReason,
            }
        end
        return nil, noPlanReason
    end
    plan.record = record
    plan.inventoryRevision = revision
    plan.originX, plan.originY, plan.originZ = x, y, z
    plan.createdAt = now
    if cacheKey then H.HydrationPlanCache[cacheKey] = plan end
    return plan
end

function Service.FindAt(record, x, y, z)
    local origin = H.OriginFor(record)
    if not origin then return nil end
    x, y, z = math.floor(tonumber(x) or 0), math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    local cell = getCell and getCell() or nil
    local square = cell and cell.getGridSquare
        and cell:getGridSquare(x, y, z) or nil
    local objects = square and H.Call(square, "getObjects") or nil
    for index = 0, H.ListSize(objects) - 1 do
        local entry = H.SourceEntry(H.ListItem(objects, index), square, index)
        if entry then return entry end
    end
    return nil
end

return Service
