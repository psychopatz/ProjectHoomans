if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
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
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes =
    require "PNC/Core/Events/PNC_EventDefinitions"

function H.CollectPersonal(inv, request, required, includeItem)
    local candidates = {}
    for _, item in pairs(inv and inv.items or {}) do
        if item.interactionLocked ~= true then
            local descriptor = Utility.DescribeNPCItem(item)
            local score = Selector.Score(descriptor, request, required)
            if score then
                local candidate = {
                    itemID = item.id,
                    stack = tonumber(item.stack) or 1,
                    descriptor = descriptor,
                    score = score,
                }
                if includeItem then candidate.item = item end
                candidates[#candidates + 1] = candidate
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.descriptor.expiry ~= right.descriptor.expiry then
            return left.descriptor.expiry > right.descriptor.expiry
        end
        return tostring(left.itemID) < tostring(right.itemID)
    end)
    return candidates
end

function SupplyInventory.FindPersonal(record, request, required)
    local inv = InventoryCommands.EnsureRecordInventory(record)
    return H.CollectPersonal(inv, request, required, true)
end

function SupplyInventory.QueryPersonal(record, request, required)
    local inv = record and record.inventory or nil
    return H.CollectPersonal(inv, request, required, false)
end

SupplyInventory.Commands = SupplyInventory.Commands or {}
SupplyInventory.Queries = SupplyInventory.Queries or {}

SupplyInventory.Commands.AddCoreRecords = SupplyInventory.AddCoreRecords
SupplyInventory.Commands.CreateDestination = SupplyInventory.CreateDestination
SupplyInventory.Commands.Consume = SupplyInventory.Consume
SupplyInventory.Commands.RemoveCoreItemIds = SupplyInventory.RemoveCoreItemIds
SupplyInventory.Commands.EnsurePersonalInventory =
    InventoryCommands.EnsureRecordInventory
SupplyInventory.Queries.FindPersonal = SupplyInventory.QueryPersonal

return SupplyInventory

