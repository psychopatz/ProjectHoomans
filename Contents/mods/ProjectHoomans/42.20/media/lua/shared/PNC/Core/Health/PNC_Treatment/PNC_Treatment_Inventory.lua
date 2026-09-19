-- Player and NPC medical-item lookup, consumption, and inventory summaries.

PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}
PNC.Treatment.Internal = PNC.Treatment.Internal or {}

local Treatment = PNC.Treatment
local Internal = Treatment.Internal
local Core = PNC.Core
local Const = PNC.Const
local Inventory = PNC.Inventory

local function findNPCBandage(record, requestedType)
    local inv
    local types
    local searchTypes
    local i
    local item
    local stack
    if not record then return nil end
    inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record) or record.inventory
    types = Internal.BandageTypes()
    if requestedType ~= nil then
        if not Internal.IsBandageType(requestedType) then return nil end
        searchTypes = { tostring(requestedType) }
    else
        searchTypes = types
    end
    for i = 1, #searchTypes do
        for _, item in pairs(inv and inv.items or {}) do
            stack = item and tonumber(item.stack) or 1
            if item and tostring(item.type or "") == tostring(searchTypes[i])
                and stack > 0
            then
                return {
                    itemID = item.id,
                    fullType = item.type,
                    displayName = Internal.BandageDisplayName(item.type),
                }
            end
        end
    end
    return nil
end

local function consumeNPCBandage(record, supply, reason)
    if not record or not supply then return false, nil end
    if PNC.SupplyInventory and PNC.SupplyInventory.Consume then
        local ok, _, effect = PNC.SupplyInventory.Consume(
            record,
            supply.itemID,
            {
                resourceKind = "MEDICAL",
                treatment = "BANDAGE",
                required = {},
                source = reason or "npc_bandage",
            }
        )
        return ok, effect and effect.undo or nil
    end
    local inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record) or record.inventory
    local item = inv and inv.items and inv.items[supply.itemID] or nil
    if not item or not Inventory or not Inventory.ApplyDelta then
        return false, nil
    end
    local undo = Core.DeepCopy(inv)
    local stack = math.max(1, math.floor(tonumber(item.stack) or 1))
    local op = stack > 1
        and { op = "update", itemID = item.id, stack = stack - 1 }
        or { op = "remove", itemID = item.id }
    local applied = Inventory.ApplyDelta(record, { op }, reason or "npc_bandage") == true
    return applied, applied and function()
        record.inventory = undo
        return true
    end or nil
end

local function findBandage(player, requestedType)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local types = requestedType and { requestedType } or Internal.BandageTypes()
    local i
    local found
    local item
    local container
    if not Internal.IsBandageType(requestedType) then return nil, nil end
    for i = 1, #types do
        found = inventory and inventory.getAllTypeRecurse
            and inventory:getAllTypeRecurse(types[i]) or nil
        item = found and found.size and found:size() > 0
            and found:get(0) or nil
        container = item and item.getContainer
            and item:getContainer() or nil
        if item and container then return item, container end
    end
    return nil, nil
end

local function listBandages(player)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local output = {}
    local types = Internal.BandageTypes()
    local i
    for i = 1, #types do
        local found = inventory and inventory.getAllTypeRecurse
            and inventory:getAllTypeRecurse(types[i]) or nil
        local count = found and found.size and tonumber(found:size()) or 0
        local item = count > 0 and found:get(0) or nil
        if count > 0 then
            output[#output + 1] = {
                fullType = types[i],
                count = count,
                item = item,
                name = Internal.BandageDisplayName(types[i], item),
            }
        end
    end
    return output
end

Internal.FindNPCBandage = findNPCBandage
Internal.ConsumeNPCBandage = consumeNPCBandage
Internal.FindBandage = findBandage

function Treatment.FindBandage(player, requestedType)
    return findBandage(player, requestedType)
end

function Treatment.FindNPCBandage(record)
    return findNPCBandage(record)
end

function Treatment.HasNPCBandage(record)
    return findNPCBandage(record) ~= nil
end

function Treatment.GetNPCBandagePlan(record, options)
    local policy = Treatment.GetNPCMedicalPolicy(record, options)
    local supply
    if not policy.requiresItem then
        return {
            fullType = policy.bandageType,
            displayName = policy.bandageName,
            mode = policy.mode,
            requiresItem = false,
        }
    end
    supply = findNPCBandage(record, options and options.bandageType)
    if not supply then return nil end
    supply.mode = policy.mode
    supply.requiresItem = true
    return supply
end

function Treatment.CountBandages(player)
    local count = 0
    local entries = listBandages(player)
    local i
    for i = 1, #entries do
        count = count + math.max(0, tonumber(entries[i].count) or 0)
    end
    return count
end

function Treatment.ListBandages(player)
    return listBandages(player)
end
