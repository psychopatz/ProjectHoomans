if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionTolls = PNC.FactionTolls or {}
PNC.FactionTollServiceInternal =
    PNC.FactionTollServiceInternal or {}

local Tolls = PNC.FactionTolls
local H = PNC.FactionTollServiceInternal
local Core = PNC.Core
local Const = PNC.Const
local Factions = PNC.Factions
local Communities = PNC.Communities
local EntityRef = PNC.EntityRef
local Currency = PsychopatzCore and PsychopatzCore.Currency

local PUMP_INTERVAL_MS = 1000
local DEMAND_LIFETIME_HOURS = 0.05
local DEPARTURE_GRACE_HOURS = 0.02
local PAID_PACIFICATION_HOURS = 24

function H.MoneyItems(inventory, fullType)
    if not inventory or not inventory.getItemsFromType then
        return {}
    end
    local values = inventory:getItemsFromType(fullType, true)
    local output = {}
    if not values or not values.size or not values.get then
        return output
    end
    local index
    for index = 0, values:size() - 1 do
        output[#output + 1] = values:get(index)
    end
    return output
end

function H.RemoveItem(inventory, item)
    local container = item and item.getContainer
        and item:getContainer() or inventory
    if container and container.Remove then
        container:Remove(item)
        return true
    end
    return false
end

function H.RemoveMoney(player, amount)
    local inventory = player and player.getInventory
        and player:getInventory() or nil
    if not inventory then return false, 0 end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if Currency and type(Currency.Snapshot) == "function"
        and type(Currency.RemoveUnits) == "function"
    then
        local snapshot = Currency.Snapshot(inventory, { recursive = true })
        if snapshot.units < amount then return false, snapshot.units end
        local removed, reason = Currency.RemoveUnits(
            inventory, amount, { recursive = true })
        if not removed then return false, snapshot.units end
        return true, snapshot.units - amount
    end
    local loose = H.MoneyItems(inventory, "Base.Money")
    local wealth = #loose
    if wealth < amount then return false, wealth end
    local remaining = amount
    local index = 1
    while remaining > 0 and loose[index] do
        H.RemoveItem(inventory, loose[index])
        remaining = remaining - 1
        index = index + 1
    end
    return true, wealth - amount
end

local function marketSenseItemValue(fullType, item, opts)
    opts = type(opts) == "table" and opts or {}
    local ms = opts.marketSense or rawget(_G, "MarketSense")
    if type(ms) == "table" and type(ms.GetPriceDetails) == "function" then
        local ok, details = pcall(ms.GetPriceDetails, fullType)
        if ok and type(details) == "table" then
            local v = tonumber(details.finalPrice or details.price or details.basePrice or details.value)
            if v and v > 0 then return v end
        end
    end
    local weight = item and item.getActualWeight and tonumber(item:getActualWeight()) or 0.5
    return math.max(5, math.floor(weight * 12))
end

local function isSkipTributeType(fullType)
    local lower = string.lower(tostring(fullType or ""))
    if lower == "" or lower == "base.money" or string.find(lower, "keyring", 1, true)
        or string.find(lower, "key", 1, true)
    then
        return true
    end
    return false
end

-- Actor-agnostic MarketSense tribute inspector: checks cash first, and if cash
-- is insufficient (or a standout valuable item is carried/worn), picks a
-- grounded item demand (e.g. "Leather Jacket") so looters ask dynamically.
function H.InspectTargetTribute(actor, cashDemand, opts)
    cashDemand = math.max(1, math.floor(tonumber(cashDemand) or 10))
    local inventory = actor and actor.getInventory and actor:getInventory() or nil
    local cashAvailable = 0
    if inventory then
        if Currency and type(Currency.Snapshot) == "function" then
            local snap = Currency.Snapshot(inventory, { recursive = true })
            cashAvailable = tonumber(snap and snap.units) or 0
        else
            cashAvailable = #H.MoneyItems(inventory, "Base.Money")
        end
    end

    local bestItem = nil
    local bestValue = 0
    if inventory and type(inventory.getItems) == "function" then
        local items = inventory:getItems()
        local count = items and items.size and tonumber(items:size()) or 0
        for i = 0, math.min(count, 64) - 1 do
            local item = items:get(i)
            local ft = item and item.getFullType and tostring(item:getFullType() or "") or ""
            if ft ~= "" and not isSkipTributeType(ft) then
                local val = marketSenseItemValue(ft, item, opts)
                if val > bestValue then
                    bestValue = val
                    bestItem = {
                        fullType = ft,
                        displayName = (item.getDisplayName and tostring(item:getDisplayName() or "")) or ft,
                        value = val,
                    }
                end
            end
        end
    end

    if cashAvailable >= cashDemand then
        if bestItem and bestValue >= 45 then
            local reducedCash = math.max(5, math.floor(cashDemand * 0.5))
            return {
                mode = "item_and_cash",
                cashAmount = reducedCash,
                itemFullType = bestItem.fullType,
                itemName = bestItem.displayName,
                itemValue = bestItem.value,
                cashAvailable = cashAvailable,
            }
        end
        return {
            mode = "cash_only",
            cashAmount = cashDemand,
            itemFullType = nil,
            itemName = nil,
            itemValue = 0,
            cashAvailable = cashAvailable,
        }
    end

    if bestItem then
        local askCash = math.min(cashAvailable, math.max(0, math.floor(cashDemand * 0.5)))
        return {
            mode = askCash > 0 and "item_and_cash" or "item_only",
            cashAmount = askCash,
            itemFullType = bestItem.fullType,
            itemName = bestItem.displayName,
            itemValue = bestItem.value,
            cashAvailable = cashAvailable,
        }
    end

    return {
        mode = "cash_only",
        cashAmount = cashDemand,
        itemFullType = nil,
        itemName = nil,
        itemValue = 0,
        cashAvailable = cashAvailable,
    }
end

function H.RemoveDemandedItem(actor, fullType)
    if not actor or not fullType or fullType == "" then return false end
    local inventory = actor.getInventory and actor:getInventory() or nil
    if not inventory then return false end
    local items = H.MoneyItems(inventory, fullType)
    if #items > 0 then
        return H.RemoveItem(inventory, items[1])
    end
    if type(inventory.getItems) == "function" then
        local all = inventory:getItems()
        local count = all and all.size and tonumber(all:size()) or 0
        for i = 0, count - 1 do
            local item = all:get(i)
            if item and item.getFullType and tostring(item:getFullType()) == fullType then
                return H.RemoveItem(inventory, item)
            end
        end
    end
    return false
end

return Tolls
