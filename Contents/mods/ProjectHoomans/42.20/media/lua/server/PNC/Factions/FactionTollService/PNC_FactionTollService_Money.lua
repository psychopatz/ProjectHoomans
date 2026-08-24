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

return Tolls

