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

local function metadataHasWaterMarker(object, metadata)
    local container = call(object, "getFluidContainer")
    local direct = call(object, "isWaterSource") == true
        or call(object, "hasFluid") == true
        or call(object, "getFluidAmount") ~= nil
        or call(object, "getWaterAmount") ~= nil
    local containerMarker = call(container, "isWaterOnlySource") == true
        or call(container, "isWaterSource") == true
    local named = containsToken(metadata and metadata.labels, "sink")
        or containsToken(metadata and metadata.labels, "faucet")
        or containsToken(metadata and metadata.labels, "water source")
        or containsToken(metadata and metadata.labels, "well")
        or containsToken(metadata and metadata.labels, "pump")
    return direct or containerMarker or named, container, direct, containerMarker
end

local function waterProvider(object, square, record)
    local metadata = record and record.metadata or {}
    local detected, container, direct, containerMarker =
        metadataHasWaterMarker(object, metadata)
    if not detected then return nil end

    local amount = number(call(object, "getFluidAmount"))
        or number(call(object, "getWaterAmount"))
        or number(call(container, "getAmount"))
    local infiniteMarker = direct or containerMarker
    local tainted = call(object, "isTaintedWater") == true
    local taintedFluid = Fluid and Fluid.TaintedWater or nil
    if not tainted and taintedFluid and container
        and call(container, "contains", taintedFluid) == true
    then
        tainted = true
    end

    local primary = call(container, "getPrimaryFluid")
    local fluidName = string.lower(tostring(
        call(primary, "getFluidTypeString") or ""))
    if fluidName ~= "" and fluidName ~= "water"
        and fluidName ~= "carbonatedwater"
    then
        return {
            waterDetected = true,
            waterState = "UNKNOWN",
            diagnostics = { "non_water_fluid" },
        }
    end

    local state
    if tainted then
        state = "UNSAFE"
    elseif amount == nil then
        state = infiniteMarker and "ACTIVE" or "UNKNOWN"
    elseif amount >= 9999 then
        state = "ACTIVE"
    elseif amount <= 0 then
        state = infiniteMarker and "ACTIVE" or "DEPLETED"
    else
        state = "ACTIVE"
    end

    local active = state == "ACTIVE"
    local fillable = active and (
        type(object.transferFluidTo) == "function"
        or type(object.moveFluidToTemporaryContainer) == "function"
        or type(object.useFluid) == "function"
        or type(object.useWater) == "function"
        or type(object.setWaterAmount) == "function"
        or container and type(container.adjustAmount) == "function"
    ) or false
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
Perception.RegisterProvider("water", {
    order = 50,
    labelKey = "UI_PNC_PerceptionDebug_ProviderWater",
    describe = waterProvider,
})

return Perception
