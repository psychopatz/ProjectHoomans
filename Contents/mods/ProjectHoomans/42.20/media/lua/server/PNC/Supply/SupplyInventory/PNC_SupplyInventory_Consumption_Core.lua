if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC.SupplyInventory = PNC.SupplyInventory or {}
PNC.SupplyInventoryInternal = PNC.SupplyInventoryInternal or {}

local SupplyInventory = PNC.SupplyInventory
local H = PNC.SupplyInventoryInternal
local Utility = PNC.ItemUtility
local Selector = PNC.SupplySelector
local Metrics = PNC.SupplyMetrics
local InventoryCommands = PNC.Inventory.Commands or PNC.Inventory
local CoreInventory =
    require "PsychopatzCore/Inventory/PsychopatzInventory"
local ItemRecord =
    require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local StateCodec = require
    "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"
local C = require
    "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require
    "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Portable = require
    "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local ItemTransfer =
    require "PsychopatzCore/Inventory/PsychopatzItemTransfer"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes =
    require "PNC/Core/Events/PNC_EventDefinitions"
local FLUID_EPSILON = 0.0001

local function syncPhysicalItem(nativeItem)
    if nativeItem and type(nativeItem.syncItemFields) == "function" then
        nativeItem:syncItemFields()
    end
    if type(sendItemStats) == "function" and nativeItem then
        sendItemStats(nativeItem)
    end
end

local function removePhysicalUnit(adapter, nativeItem)
    local count
    if nativeItem and type(nativeItem.getCount) == "function" then
        count = tonumber(nativeItem:getCount())
    end
    if count and count > 1 then
        if type(nativeItem.setCount) ~= "function" then
            return false, "physical_stack_update_unavailable"
        end
        nativeItem:setCount(count - 1)
        return true, nil, function()
            nativeItem:setCount(count)
            syncPhysicalItem(nativeItem)
            return true
        end
    end
    if not adapter:_nativeRemove(nativeItem) then
        return false, "physical_remove_failed"
    end
    return true, nil, function()
        local restored = adapter:_nativeAdd(nativeItem)
        syncPhysicalItem(nativeItem)
        return restored
    end
end

local function fluidStateAfterUse(item, current, remaining)
    local source = item and item.itemState
    local effective = PNC.Inventory.ResolveItemState
        and PNC.Inventory.ResolveItemState(item) or source
    local amount
    local ratio
    local state
    if type(effective) ~= "table" then return nil end
    amount = tonumber(effective.fluidAmount)
    if amount == nil then return nil end
    state = PNC.Core.DeepCopy(type(source) == "table" and source or {})
    ratio = current > 0 and remaining / current or 0
    state.fluidAmount = math.max(0, amount * ratio)
    if type(source) == "table" and type(source.fluids) == "table" then
        state.fluids = {}
        for index = 1, #source.fluids do
            local entry = source.fluids[index]
            if type(entry) == "table" and tonumber(entry.amount) then
                state.fluids[#state.fluids + 1] = {
                    type = entry.type,
                    amount = math.max(0, tonumber(entry.amount) * ratio),
                }
            end
        end
    end
    if state.fluidAmount <= 0.0001 then
        state.fluidType = nil
        state.fluidPrimaryType = nil
        state.fluids = nil
    end
    return state
end

local function currentUseDelta(item)
    local current = tonumber(item and item.uses)
    local resolved
    if current == nil and PNC.Inventory.ResolveItemState then
        resolved = PNC.Inventory.ResolveItemState(item)
        current = resolved and tonumber(resolved.usedDelta) or nil
    end
    return current or 1
end

local function fluidStateAfterDrain(item, amount)
    local source = item and item.itemState
    local effective = PNC.Inventory.ResolveItemState
        and PNC.Inventory.ResolveItemState(item) or source
    local current = effective and tonumber(effective.fluidAmount) or nil
    local drained = math.max(0, tonumber(amount) or 0)
    local state
    local ratio
    if not current or current <= 0.000001 or drained <= 0 then
        return nil, 0
    end
    drained = math.min(current, drained)
    state = PNC.Core.DeepCopy(type(source) == "table" and source or {})
    state.fluidAmount = math.max(0, current - drained)
    ratio = current > 0 and state.fluidAmount / current or 0
    if type(source) == "table" and type(source.fluids) == "table" then
        state.fluids = {}
        for index = 1, #source.fluids do
            local entry = source.fluids[index]
            if type(entry) == "table" and tonumber(entry.amount) then
                state.fluids[#state.fluids + 1] = {
                    type = entry.type,
                    amount = math.max(0, tonumber(entry.amount) * ratio),
                }
            end
        end
    end
    if state.fluidAmount <= 0.0001 then
        state.fluidType = nil
        state.fluidPrimaryType = nil
        state.fluids = nil
    end
    return state, drained
end

local function splitItem(item, state)
    local split = {}
    for key, value in pairs(item) do
        if key ~= "id" and key ~= "stack" and key ~= "uses" then
            split[key] = type(value) == "table"
                and PNC.Core.DeepCopy(value) or value
        end
    end
    split.stack = 1
    split.itemState = state
    return split
end

local function replacementFullType(itemType, replacement)
    local module
    replacement = tostring(replacement or "")
    if replacement == "" then return nil end
    if string.find(replacement, ".", 1, true) then return replacement end
    module = string.match(tostring(itemType or ""), "^([^%.]+)%.")
    return module and module .. "." .. replacement or nil
end

local function foodReplacement(item, descriptor)
    if not descriptor or descriptor.food ~= true then return nil end
    return replacementFullType(item and item.type,
        descriptor.replaceOnUse or descriptor.replaceOnDeplete)
end

function H.CanonicalConsumptionOps(item, descriptor, request)
    local stack = math.max(1, math.floor(tonumber(item.stack) or 1))
    -- Build 42 fluid containers do not expose a dependable thirstChange or
    -- useDelta in their script definition. Drain the requested volume while
    -- keeping the bottle as an empty container after its last sip.
    if descriptor.fluidHydration == true
        and request and tonumber(request.consumeAmount) ~= nil
    then
        local fluidState, drained = fluidStateAfterDrain(
            item, request.consumeAmount)
        local currentUses = currentUseDelta(item)
        local currentAmount = tonumber(
            PNC.Inventory.ResolveItemState(item).fluidAmount) or 0
        local remainingUses = currentAmount > 0
            and currentUses * math.max(0,
                (currentAmount - drained) / currentAmount) or 0
        if not fluidState or drained <= 0.000001 then
            return nil, 0, 0, 0
        end
        local consumedFraction = currentAmount > 0
            and math.min(1, drained / currentAmount) or 1
        if stack > 1 then
            return {
                { op = "update", itemID = item.id, stack = stack - 1 },
                { op = "add", item = (function()
                    local split = splitItem(item, fluidState)
                    split.uses = remainingUses
                    return split
                end)() },
            }, remainingUses, drained, consumedFraction
        end
        return {{ op = "update", itemID = item.id, uses = remainingUses,
            itemState = fluidState }}, remainingUses, drained,
            consumedFraction
    end
    if descriptor.food == true and request
        and request.resourceKind == "FOOD"
    then
        local replacement = foodReplacement(item, descriptor)
        if stack > 1 then
            local ops = {
                { op = "update", itemID = item.id, stack = stack - 1 },
            }
            if replacement then
                ops[#ops + 1] = { op = "add", item = {
                    type = replacement, stack = 1,
                    container = item.container or "root", itemState = {},
                } }
            end
            return ops, 0, nil, 1
        end
        if replacement then
            return {
                { op = "remove", itemID = item.id },
                { op = "add", item = {
                    type = replacement, stack = 1,
                    container = item.container or "root", itemState = {},
                } },
            }, 0, nil, 1
        end
        return {{ op = "remove", itemID = item.id }}, 0, nil, 1
    end
    if descriptor.hydration and descriptor.useDelta > 0 then
        local current = currentUseDelta(item)
        local remaining = math.max(0, current - descriptor.useDelta)
        if remaining > 0.0001 then
            local fluidState = descriptor.hydration
                and fluidStateAfterUse(item, current, remaining) or nil
            -- usedDelta is the amount remaining in the current item unit;
            -- useDelta is the portion consumed by this action.  Scale against
            -- the original unit, not against the shrinking remainder, so
            -- four quarter-uses contribute exactly one full serving.
            local consumedFraction = math.min(1, math.max(0,
                math.min(current, descriptor.useDelta)))
            if stack > 1 then
                local split = {}
                for key, value in pairs(item) do
                    if key ~= "id" and key ~= "stack" then
                        split[key] = type(value) == "table"
                            and PNC.Core.DeepCopy(value) or value
                    end
                end
                split.stack = 1
                split.uses = remaining
                if fluidState then split.itemState = fluidState end
                return {
                    { op = "update", itemID = item.id, stack = stack - 1 },
                    { op = "add", item = split },
                }, remaining, nil, consumedFraction
            end
            local update = {
                op = "update", itemID = item.id, uses = remaining,
            }
            if fluidState then update.itemState = fluidState end
            return { update }, remaining, nil, consumedFraction
        end
    end
    if stack > 1 then
        return {{ op = "update", itemID = item.id, stack = stack - 1 }}, 0, nil, 1
    end
    return {{ op = "remove", itemID = item.id }}, 0, nil, 1
end

function H.BuildConsumptionEffect(descriptor, consumedFraction)
    local fraction = math.max(0, math.min(1,
        tonumber(consumedFraction) or 1))
    local burntMultiplier = descriptor.burntMultiplier
        or (descriptor.burnt == true and 0.20 or 1)
    local valueMultiplier = descriptor.effectiveValues == true
        and 1 or burntMultiplier
    local multiplier = fraction * valueMultiplier
    local realism = PNC.Sandbox
        and PNC.Sandbox.PlayerOwnedNPCNutritionRealismEnabled
        and PNC.Sandbox.PlayerOwnedNPCNutritionRealismEnabled() == true
    local effect = {
        hunger = (tonumber(descriptor.hunger) or 0) * multiplier,
        thirst = (tonumber(descriptor.thirst) or 0) * multiplier,
        calories = realism and (tonumber(descriptor.calories) or 0)
            * multiplier or 0,
        consumedFraction = fraction,
        burntMultiplier = burntMultiplier,
        fullType = descriptor.fullType,
        typeId = descriptor.typeId,
    }
    if realism then
        effect.carbohydrates = (tonumber(descriptor.carbohydrates) or 0)
            * multiplier
        effect.proteins = (tonumber(descriptor.proteins) or 0) * multiplier
        effect.lipids = (tonumber(descriptor.lipids) or 0) * multiplier
    end
    return effect
end
H.Consumption = H.Consumption or {}
H.Consumption.SyncPhysicalItem = syncPhysicalItem
H.Consumption.RemovePhysicalUnit = removePhysicalUnit
H.Consumption.FoodReplacement = foodReplacement
