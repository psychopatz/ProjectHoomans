-- Water-source provider for client world-object perception.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

local Perception = PNC.Perception.WorldObjects
local Internal = Perception.Internal

local function call(object, method, ...)
    return Internal.Call(object, method, ...)
end

local function number(value)
    return Internal.Number(value)
end

local function containsToken(values, token)
    token = string.lower(tostring(token or ""))
    if token == "" then return false end
    for index = 1, #(values or {}) do
        local value = string.lower(tostring(values[index] or ""))
        if string.find(value, token, 1, true) then return true end
    end
    return false
end

local SOURCE_NAME_TOKENS = {
    "sink", "faucet", "water cooler", "rain collector", "well", "pump",
}

local function namedWaterSource(metadata)
    metadata = type(metadata) == "table" and metadata or {}
    for index = 1, #SOURCE_NAME_TOKENS do
        local token = SOURCE_NAME_TOKENS[index]
        if containsToken(metadata.labels, token)
            or string.find(string.lower(tostring(metadata.objectName or "")),
                token, 1, true)
            or string.find(string.lower(tostring(metadata.displayName or "")),
                token, 1, true)
            or string.find(string.lower(tostring(metadata.spriteName or "")),
                token, 1, true)
        then
            return true
        end
    end
    return false
end

-- Property containers are the engine's reliable marker for a water sprite.
-- The typed enum is used when available; the string fallback keeps this
-- provider usable by lightweight test/runtime shims.
local function enumValue(enumName, key)
    local enum = enumName == "flag" and IsoFlagType or IsoPropertyType
    if not enum then return nil end
    local ok, value = pcall(function() return enum[key] end)
    return ok and value or nil
end

local function propertyContainer(source)
    return call(source, "getProperties")
end

local function propertyHas(source, key, enumKey)
    local properties = propertyContainer(source)
    if not properties or type(properties.has) ~= "function" then
        return false
    end
    local typed = enumValue("flag", enumKey or key)
    if typed ~= nil then
        local ok, result = pcall(properties.has, properties, typed)
        if ok and result == true then return true end
    end
    local ok, result = pcall(properties.has, properties, key)
    return ok and result == true
end

local function propertyValue(source, key, enumKey)
    local properties = propertyContainer(source)
    if not properties or type(properties.get) ~= "function" then return nil end
    local typed = enumValue("property", enumKey or key)
    if typed ~= nil then
        local ok, result = pcall(properties.get, properties, typed)
        if ok and result ~= nil then return result end
    end
    local ok, result = pcall(properties.get, properties, key)
    return ok and result or nil
end

local function fluidName(container)
    local primary = call(container, "getPrimaryFluid")
    if not primary then return "", nil end
    local value = call(primary, "getFluidTypeString")
        or call(primary, "getFluidType")
    return string.lower(tostring(value or "")), primary
end

local function isWaterFluid(name)
    return name == "" or name == "water" or name == "carbonatedwater"
end

-- `IsoObject:getFluidAmount()` and `IsoObject:hasFluid()` are not detection
-- markers. They are available on ordinary objects and may report puddle
-- fluid for a solid floor. Only sprite water flags, water amount properties,
-- explicit source markers, compatible water containers, or a source name can
-- make an object enter the water provider.
local function sourceInfo(object, square, metadata)
    local sprite = call(object, "getSprite")
    local container = call(object, "getFluidContainer")
    local primaryName, primary = fluidName(container)
    local objectSource = call(object, "isWaterSource") == true
    local objectWaterOnly = call(object, "isWaterOnlySource") == true
    local containerSource = call(container, "isWaterOnlySource") == true
        or call(container, "isWaterSource") == true
    local piped = propertyHas(sprite, "waterPiped", "waterPiped")
    local bodyWater = propertyHas(sprite, "water", "water")
    local spriteAmount = number(propertyValue(sprite, "waterAmount",
        "WATER_AMOUNT"))
    local spriteMaximum = number(propertyValue(sprite, "waterMaxAmount",
        "MAXIMUM_WATER_AMOUNT"))
    local external = call(object, "getUsesExternalWaterSource") == true
    local named = namedWaterSource(metadata)
    local compatibleContainer = container ~= nil and isWaterFluid(primaryName)
        and primary ~= nil
    local detected = objectSource or objectWaterOnly or containerSource
        or piped or bodyWater or spriteAmount ~= nil
        or spriteMaximum ~= nil or external or named
        or compatibleContainer
    return {
        detected = detected,
        container = container,
        primary = primary,
        primaryName = primaryName,
        objectSource = objectSource,
        objectWaterOnly = objectWaterOnly,
        containerSource = containerSource,
        piped = piped,
        bodyWater = bodyWater,
        spriteAmount = spriteAmount,
        spriteMaximum = spriteMaximum,
        external = external,
        named = named,
        compatibleContainer = compatibleContainer,
        waterCompatible = isWaterFluid(primaryName),
    }
end

local function waterCandidate(object, square, metadata)
    local info = sourceInfo(object, square, metadata)
    return info.detected and info.waterCompatible
end

local function waterProvider(object, square, record)
    local metadata = record and record.metadata or {}
    local info = sourceInfo(object, square, metadata)
    if not info.detected or not info.waterCompatible then return nil end

    local container = info.container
    -- Read an amount only after a strict source marker has been established.
    -- This is the important boundary that prevents every dry floor from
    -- becoming an ACTIVE water tile merely because IsoObject exposes the
    -- method.
    local amount = number(call(object, "getFluidAmount"))
        or number(call(object, "getWaterAmount"))
        or number(call(container, "getAmount"))
    local infiniteMarker = info.bodyWater
        or info.spriteAmount and info.spriteAmount >= 9999
        or info.spriteMaximum and info.spriteMaximum >= 9999
        or info.objectSource or info.objectWaterOnly
    local tainted = call(object, "isTaintedWater") == true
    local taintedFluid = Fluid and Fluid.TaintedWater or nil
    if not tainted and taintedFluid and container
        and call(container, "contains", taintedFluid) == true
    then
        tainted = true
    end

    local state
    if tainted then
        state = "UNSAFE"
    elseif amount == nil then
        state = (infiniteMarker or info.piped or info.external)
            and "ACTIVE" or "UNKNOWN"
    elseif amount >= 9999 then
        state = "ACTIVE"
    elseif amount <= 0 then
        state = infiniteMarker and "ACTIVE" or "DEPLETED"
    else
        state = "ACTIVE"
    end

    local active = state == "ACTIVE"
    -- Method presence is not a capability check: IsoObject exposes transfer
    -- methods broadly. The source evidence above is the capability contract
    -- for this diagnostic layer, while state still controls active use.
    local fillable = active and (info.bodyWater or info.piped or info.external
        or info.objectSource or info.objectWaterOnly
        or info.containerSource or info.named) or false
    local usage = { "Water Source (" .. state .. ")" }
    if active and not tainted then usage[#usage + 1] = "Drinking" end
    if fillable then usage[#usage + 1] = "Filling water" end
    local jobs = {}
    if active and not tainted then jobs[#jobs + 1] = "survival.drink.world" end
    if fillable then jobs[#jobs + 1] = "survival.fill.water" end
    return {
        waterDetected = true,
        waterState = state,
        waterAmount = amount,
        waterInfinite = infiniteMarker,
        validWater = active and not tainted,
        validDrinking = active and not tainted,
        validWaterFill = fillable,
        usage = usage,
        jobs = jobs,
        capabilities = jobs,
    }
end

Perception.Internal.WaterProvider = waterProvider
Perception.Internal.WaterCandidate = waterCandidate
Perception.RegisterProvider("water", {
    order = 50,
    labelKey = "UI_PNC_PerceptionDebug_ProviderWater",
    candidate = waterCandidate,
    describe = waterProvider,
})

return Perception
