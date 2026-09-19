-- PZ native fluid access and item-state adapter for water containers.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Runtime = Internal.WaterContainerRuntime or {}
Internal.WaterContainerRuntime = Runtime
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Profiles = require "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"

Runtime.EPSILON = Runtime.EPSILON or 0.0001
local EPSILON = Runtime.EPSILON
Internal.WaterContainerCapabilityCache =
    Internal.WaterContainerCapabilityCache or {}

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    return fn(object, ...)
end

function Runtime.Probe(fullType)
    local cached = Internal.WaterContainerCapabilityCache[fullType]
    local item
    local profile
    if cached ~= nil then return cached.item, cached.fluid == true end
    if PNC.Equipment and PNC.Equipment.CreateItem then
        item = PNC.Equipment.CreateItem(fullType)
    end
    if type(item) == "table" and not item.getFluidContainer and item[1] then
        item = item[1]
    end
    profile = item and Profiles.ClassifyNative(item) or Profiles.Get(fullType)
    cached = {
        item = item,
        fluid = profile and profile.capabilities
            and profile.capabilities.fluid == true
            or item and (call(item, "getFluidContainer") ~= nil
                or call(item, "isFluidContainer") == true
                or call(item, "IsFluidContainer") == true),
    }
    Internal.WaterContainerCapabilityCache[fullType] = cached
    return cached.item, cached.fluid == true
end

function Runtime.NativeFluidCapable(item)
    return item and (call(item, "getFluidContainer") ~= nil
        or call(item, "isFluidContainer") == true
        or call(item, "IsFluidContainer") == true)
end

local function hasFluidState(state)
    return type(state) == "table"
        and (state.fluidAmount ~= nil or state.fluidCapacity ~= nil
            or state.fluidPrimaryType ~= nil or type(state.fluids) == "table")
end

function Runtime.StateFor(item, nativeItem, nativeAuthoritative)
    local state
    if nativeAuthoritative and nativeItem then
        state = Portable.CaptureFluid(nativeItem)
    end
    if state then return state end
    if Inventory.ResolveItemState then
        state = Inventory.ResolveItemState(item) or {}
        if hasFluidState(state) then return state end
    end
    if nativeItem then return Portable.CaptureFluid(nativeItem) or {} end
    return type(item and item.itemState) == "table" and item.itemState or {}
end

local function waterFluid()
    local fluidClass = rawget(_G, "Fluid")
    if fluidClass
        and type(fluidClass.FluidsInitialized) == "function"
        and fluidClass.FluidsInitialized()
        and type(fluidClass.Get) == "function"
    then
        return fluidClass.Get("Water")
    end
    return nil
end

function Runtime.CanAcceptWater(nativeItem, state, freeCapacity)
    local container = nativeItem and call(nativeItem, "getFluidContainer")
    local water = waterFluid()
    local result
    if container and water and type(container.canAddFluid) == "function" then
        result = call(container, "canAddFluid", water)
        if result == false then return false end
    end
    return (tonumber(freeCapacity) or 0) > EPSILON
        and state.fluidInputLocked ~= true
end
