-- Bounded world discovery and shared camp snapshot cache.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
local Const = PNC.Const or {}
local Resources = PNC.FacilityResources
local Water = PNC.NearbyWaterService
local Locator = PNC.NearbyResourceLocator
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics and PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"
local function number(value, fallback)
    return Internal.Number(value, fallback)
end

local function worldHour()
    return Internal.WorldHour()
end

local function eachObject(square, visitor)
    local objects = square and square.getObjects
        and square:getObjects() or nil
    if not objects then return end
    if objects.size and objects.get then
        for index = 0, objects:size() - 1 do
            visitor(objects:get(index), index)
        end
        return
    end
    for index = 1, #objects do visitor(objects[index], index) end
end

local function primitiveCopyValue(value)
    local valueType = type(value)
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" then return nil end
    local output = {}
    for key, child in pairs(value) do
        local copied = primitiveCopyValue(child)
        if copied ~= nil then output[key] = copied end
    end
    return output
end

local function primitiveCopy(source)
    return primitiveCopyValue(source) or {}
end

local function spriteName(object)
    if not object or type(object.getSprite) ~= "function" then return nil end
    local sprite = object:getSprite()
    if not sprite or type(sprite.getName) ~= "function" then return nil end
    return sprite:getName()
end

local function bedKey(resource)
    return "bed:" .. tostring(math.floor((number(resource.x, 0) * 2) + 0.5))
        .. ":" .. tostring(math.floor((number(resource.y, 0) * 2) + 0.5))
        .. ":" .. tostring(number(resource.z, 0))
end

local function addResource(resources, seen, resource)
    if type(resource) ~= "table" then return end
    local copy = primitiveCopy(resource)
    local key = tostring(copy.resourceKey or copy.key or "")
    if key == "" or seen[key] then return end
    copy.resourceKey = key
    copy.kind = copy.kind or "discovered"
    copy.readOnly = true
    if type(copy.seatSpots) == "table" then
        local maximum = math.max(1, math.floor(number(
            Const.CAMP_RESOURCE_SPOT_MAX, 8)))
        while #copy.seatSpots > maximum do
            table.remove(copy.seatSpots)
        end
    end
    seen[key] = true
    resources[#resources + 1] = copy
end

local function describeSleepResource(square, object, detectorId)
    local detector = Resources and Resources.GetDetector
        and Resources.GetDetector(detectorId) or nil
    if not detector or type(detector.matches) ~= "function"
        or type(detector.describe) ~= "function"
    then return nil end
    local matched = detector.matches(square, object)
    if matched ~= true then return nil end
    matched = detector.describe(square, object)
    if type(matched) ~= "table" then return nil end
    matched = primitiveCopy(matched)
    matched.resourceKey = type(detector.key) == "function"
        and detector.key(matched) or bedKey(matched)
    matched.detectorId = detectorId
    matched.targetResolver = detectorId
    matched.resourceKind = matched.resourceKind or "sleep_surface"
    matched.role = matched.role or detector.role
    matched.sleepSurface = matched.sleepSurface or detector.sleepSurface
        or detectorId
    matched.sleepPriority = matched.sleepPriority
        or detector.sleepPriority or 0
    matched.exclusive = matched.exclusive ~= false
    matched.available = true
    matched.originX = square and square.getX and square:getX() or matched.originX
    matched.originY = square and square.getY and square:getY() or matched.originY
    matched.originZ = square and square.getZ and square:getZ() or matched.originZ
    return matched
end

local function describeFaucet(square, object, ordinal)
    if not Water or not Water.IsCleanFaucet
        or not Water.IsCleanFaucet(object)
    then return nil end
    local x = square and square.getX and square:getX() or nil
    local y = square and square.getY and square:getY() or nil
    local z = square and square.getZ and square:getZ() or nil
    if x == nil or y == nil then return nil end
    local key
    if Locator and Locator.ObjectKeyFor then
        key = Locator.ObjectKeyFor(object, x, y, z or 0, ordinal)
    end
    key = tostring(key or ("faucet:" .. tostring(x) .. ":" .. tostring(y)
        .. ":" .. tostring(z or 0) .. ":" .. tostring(ordinal or 0)))
    return {
        kind = "discovered", detectorId = "faucet",
        targetResolver = "faucet", resourceKind = "water_source",
        role = "survival.world_water", capability = "survival.drink.world",
        resourceKey = key, key = key, x = x + 0.5, y = y + 0.5,
        z = z or 0, originX = x, originY = y, originZ = z or 0,
        sprite = spriteName(object), exclusive = false, available = true,
        readOnly = true,
    }
end

local function describeSeat(square, object, context, ordinal)
    local detector = Resources and Resources.GetDetector
        and Resources.GetDetector("seat") or nil
    if not detector or type(detector.matches) ~= "function"
        or type(detector.describe) ~= "function"
    then return nil end
    local matched = detector.matches(square, object)
    if matched ~= true then return nil end
    local resource = detector.describe(
        square,
        object,
        { objectIndex = ordinal, character = context and context.character }
    )
    if type(resource) ~= "table" then return nil end
    resource.detectorId = "seat"
    resource.targetResolver = "seat"
    resource.resourceKind = "seating_surface"
    resource.role = "living.chair"
    resource.exclusive = true
    resource.available = true
    return resource
end


Internal.EachObject = eachObject
Internal.PrimitiveCopy = primitiveCopy
Internal.SpriteName = spriteName
Internal.BedKey = bedKey
Internal.AddResource = addResource
Internal.DescribeSleepResource = describeSleepResource
Internal.DescribeFaucet = describeFaucet
Internal.DescribeSeat = describeSeat

return Service
