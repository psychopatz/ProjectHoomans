-- Self-registering clean water faucet detector for the unified object registry.
--
-- Keeps water-source discovery pluggable alongside bed, sofa, and seat
-- detectors so camp, settlement, and roaming consumers share one definition.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityResources = PNC.FacilityResources or {}

local Resources = PNC.FacilityResources

local function spriteName(object)
    if not object or type(object.getSprite) ~= "function" then return nil end
    local sprite = object:getSprite()
    if not sprite or type(sprite.getName) ~= "function" then return nil end
    return sprite:getName()
end

local function waterService()
    return PNC.NearbyWaterService
end

local function locatorService()
    return PNC.NearbyResourceLocator
end

Resources.Register("faucet", {
    resourceKind = "water_source",
    capability = "survival.drink.world",
    role = "survival.world_water",
    targetResolver = "faucet",
    exclusive = false,
    matches = function(_, object)
        local water = waterService()
        return water ~= nil and type(water.IsCleanFaucet) == "function"
            and water.IsCleanFaucet(object) == true
    end,
    describe = function(square, object, context)
        local water = waterService()
        if not water or type(water.IsCleanFaucet) ~= "function"
            or water.IsCleanFaucet(object) ~= true
        then
            return nil
        end
        local x = square and square.getX and square:getX() or nil
        local y = square and square.getY and square:getY() or nil
        local z = square and square.getZ and square:getZ() or 0
        if x == nil or y == nil then return nil end
        local ordinal = type(context) == "table" and context.objectIndex or 0
        local locator = locatorService()
        local key = locator and type(locator.ObjectKeyFor) == "function"
            and locator.ObjectKeyFor(object, x, y, z, ordinal) or nil
        key = tostring(key or ("faucet:" .. tostring(x) .. ":" .. tostring(y)
            .. ":" .. tostring(z or 0) .. ":" .. tostring(ordinal or 0)))
        return {
            kind = "discovered",
            detectorId = "faucet",
            targetResolver = "faucet",
            resourceKind = "water_source",
            capability = "survival.drink.world",
            role = "survival.world_water",
            resourceKey = key,
            key = key,
            x = x + 0.5,
            y = y + 0.5,
            z = z or 0,
            originX = x,
            originY = y,
            originZ = z or 0,
            sprite = spriteName(object),
            exclusive = false,
            available = true,
            readOnly = true,
        }
    end,
    key = function(resource)
        return tostring(resource and (resource.resourceKey or resource.key) or "")
    end,
})

return Resources
