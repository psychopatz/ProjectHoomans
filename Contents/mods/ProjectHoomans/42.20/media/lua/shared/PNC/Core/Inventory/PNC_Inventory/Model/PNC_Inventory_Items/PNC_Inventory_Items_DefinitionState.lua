-- PZ definition baselines and canonical item state projection.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Defaults = require "PsychopatzCore/Inventory/PsychopatzItemStateDefaults"
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Profiles = require "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"

Internal.ItemDefinitionStateCache =
    Internal.ItemDefinitionStateCache or {}

local function copyKnown(source, target, fields)
    local i
    local field
    local value
    for i = 1, #fields do
        field = fields[i]
        value = source and source[field]
        if value ~= nil then target[field] = Util.copy(value) end
    end
end

local function sameNumber(left, right)
    left, right = tonumber(left), tonumber(right)
    return left ~= nil and right ~= nil
        and math.abs(left - right) <= 0.000001
end

-- Build one immutable baseline from the PZ definition/probe.  Instance
-- records never store this table; it is cached by full type and used only to
-- remove or resolve deviations.
function Internal.getItemDefinitionState(fullType)
    fullType = Internal.normalizeString(fullType)
    local cached
    local item
    local state = {}
    local fluid
    local food
    local profile
    local capabilities
    local value
    if not fullType then return nil end
    cached = Internal.ItemDefinitionStateCache[fullType]
    if cached ~= nil then return cached end
    item = Internal.createItemProbe(fullType)
    if not item then
        Internal.ItemDefinitionStateCache[fullType] = false
        return nil
    end

    profile = Profiles.ClassifyNative(item)
    capabilities = profile.capabilities or {}

    if capabilities.condition then
        value = Util.call(item, "getConditionMax")
        if value ~= nil then state.condition = tonumber(value) end
    end
    if capabilities.uses then
        value = Util.call(item, "getUsedDelta")
        if value ~= nil then state.usedDelta = tonumber(value) end
    end

    if capabilities.fluid then fluid = Portable.CaptureFluid(item) end
    if fluid then
        copyKnown(fluid, state, {
            "fluidAmount", "fluidCapacity", "fluidPrimaryType",
            "fluidInputLocked", "fluidCanPlayerEmpty", "fluidRainCatcher",
            "fluids",
        })
    end

    profile = Internal.getFoodProfile(fullType)
    if capabilities.food and profile and profile.food == true then
        food = Portable.CaptureFood(item)
        copyKnown(food, state, {
            "age", "cooked", "burnt", "frozen", "freezingTime",
            "hungChange", "thirstChange", "dangerousUncooked", "poison",
            "calories", "carbohydrates", "proteins", "lipids",
            "poisonDetectionLevel", "poisonLevelForRecipe", "poisonPower",
            "rottenTime", "cookedInMicrowave", "tainted", "fertilized",
            "fertilizedTime", "heat", "lastCookMinute", "cookingTime",
        })
    end

    if capabilities.ammo then
        value = Util.call(item, "getCurrentAmmoCount")
        if value ~= nil then state.ammoCount = tonumber(value) end
        value = Util.call(item, "isRoundChambered")
        if value ~= nil then state.roundChambered = value == true end
        value = Util.call(item, "isJammed")
        if value ~= nil then state.jammed = value == true end
    end
    if capabilities.clothing then
        value = Util.call(item, "getWetness")
        if value ~= nil then state.wetness = tonumber(value) end
        value = Util.call(item, "getBloodlevel")
        if value == nil then value = Util.call(item, "getBloodLevel") end
        if value ~= nil then state.bloodLevel = tonumber(value) end
        value = Util.call(item, "getDirtiness")
        if value ~= nil then state.dirtyness = tonumber(value) end
    end

    if Internal.countMapEntries(state) <= 0 then
        Internal.ItemDefinitionStateCache[fullType] = false
        return nil
    end
    Internal.ItemDefinitionStateCache[fullType] = state
    return state
end

function Inventory.GetItemDefinitionState(fullType)
    return Util.copy(Internal.getItemDefinitionState(fullType))
end

-- Canonicalize incoming abstract state against the PZ baseline.  Zero and
-- false are retained when they differ; absent fields continue to mean the
-- default.  The old full-water seed is deliberately not recreated.
function Inventory.NormalizeItemState(item)
    local raw
    local delta
    local normalized
    local fullType
    local before
    local beforeUses
    local definition
    if type(item) ~= "table" then return false end
    fullType = Internal.normalizeItemType(item.type)
    raw = Internal.sanitizeItemState(item.itemState)
    beforeUses = item.uses
    if fullType == "Base.WaterBottle" and item.uses ~= nil
        and tonumber(item.uses) == 0
        and Internal.countMapEntries(raw) <= 0
    then
        raw.fluidAmount = 0
        item.uses = nil
    end
    definition = Internal.getItemDefinitionState(fullType)
    if definition then
        if sameNumber(item.uses, definition.usedDelta) then
            item.uses = nil
        end
        if sameNumber(item.cond, definition.condition) then
            item.cond = nil
        end
        if sameNumber(item.ammoCount, definition.ammoCount) then
            item.ammoCount = nil
        end
    end
    before = Util.canonical(raw)
    delta = Defaults.Diff(fullType, raw)
    normalized = Internal.sanitizeItemState(delta)
    if Internal.countMapEntries(normalized) <= 0 then
        item.itemState = nil
    else
        item.itemState = normalized
    end
    return before ~= Util.canonical(item.itemState or {})
        or beforeUses ~= item.uses
end

function Inventory.ResolveItemState(item)
    if type(item) ~= "table" then return {} end
    return Defaults.Effective(item)
end

Defaults.RegisterProvider(function(fullType)
    return Internal.getItemDefinitionState(fullType)
end, 1)
