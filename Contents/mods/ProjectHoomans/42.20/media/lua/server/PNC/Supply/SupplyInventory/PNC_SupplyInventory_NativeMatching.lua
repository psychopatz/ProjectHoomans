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

function H.ExactRecord(item)
    return CoreInventory.encodeItem(StateCodec.pseudoItem(item), 1)
end

function H.SameState(expected, candidate)
    local encoded = CoreInventory.encodeItem(candidate, 1)
    if not encoded or not expected then return false end
    local expectedKey = ItemRecord.stackKey(expected)
    local candidateKey = ItemRecord.stackKey(encoded)
    if expectedKey or candidateKey then return expectedKey == candidateKey end
    return Util.canonical(expected) == Util.canonical(encoded)
end

function H.NativeCandidates(body, item)
    local output = {}
    local compatible = {}
    local visited = {}
    local expected = H.ExactRecord(item)
    local function visit(container)
        if not container or visited[container] then return end
        visited[container] = true
        local items = container.getItems and container:getItems() or nil
        if not items or not items.size or not items.get then return end
        for index = 0, items:size() - 1 do
            local nativeItem = items:get(index)
            local fullType = nativeItem and nativeItem.getFullType
                and nativeItem:getFullType() or nil
            if tostring(fullType or "") == tostring(item.type or "") then
                local entry = {
                    item = nativeItem,
                    container = container,
                }
                if H.SameState(expected, nativeItem) then
                    output[#output + 1] = entry
                else
                    compatible[#compatible + 1] = entry
                end
            end
            local nested = nativeItem and nativeItem.getItemContainer
                and nativeItem:getItemContainer() or nil
            if nested then visit(nested) end
        end
    end
    visit(body and body.getInventory and body:getInventory() or nil)
    for index = 1, #compatible do
        output[#output + 1] = compatible[index]
    end
    return output
end

return SupplyInventory

