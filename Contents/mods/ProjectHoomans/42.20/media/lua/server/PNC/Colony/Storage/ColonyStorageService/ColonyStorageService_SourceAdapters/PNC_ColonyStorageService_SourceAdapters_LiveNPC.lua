if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyStorageService = PNC.ColonyStorageService or {}
PNC.ColonyStorageService.Internal =
    PNC.ColonyStorageService.Internal or {}

local Internal = PNC.ColonyStorageService.Internal
Internal.SourceAdaptersInternal =
    Internal.SourceAdaptersInternal or {}
local H = Internal.SourceAdaptersInternal
local CoreInventory = Internal.CoreInventory
local ItemRecord =
    require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local StateCodec = require
    "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"

function Internal.LiveNPCSource(record, item, quantity, body)
    local container = body and body.getInventory and body:getInventory() or nil
    local physical = container and CoreInventory.wrapPhysicalInventory(container) or nil
    if not physical then return nil, "physical_inventory_unavailable" end
    local expected, reason = H.CompactPreview(item, 1)
    if not expected then return nil, reason end
    local key = ItemRecord.stackKey(expected)
    local typeQuery = { fullType = tostring(item.type or "") }
    local source = { revision = record.inventory.revision }

    local function chooseCandidates()
        local exact = {}
        local compatible = {}
        for _, nativeItem in ipairs(physical:query(typeQuery)) do
            local encoded = CoreInventory.encodeItem(nativeItem, 1)
            if key and encoded and ItemRecord.stackKey(encoded) == key then
                exact[#exact + 1] = nativeItem
            else
                compatible[#compatible + 1] = nativeItem
            end
        end
        for _, nativeItem in ipairs(compatible) do
            exact[#exact + 1] = nativeItem
        end
        return exact
    end

    function source:preview()
        local records = {}
        for index = 1, quantity do
            records[index] = ItemRecord.clone(expected, 1)
        end
        return records
    end
    function source:remove()
        local candidates = chooseCandidates()
        local physicalQuantity = math.min(#candidates, quantity)
        local selected = {}
        for index = 1, physicalQuantity do
            selected[candidates[index]] = true
        end
        local query = { predicate = function(nativeItem)
            return selected[nativeItem] == true
        end }
        self.undo = PNC.Core.DeepCopy(record.inventory)
        local removed = { physicalItems = {} }
        if physicalQuantity > 0 then
            local ok
            ok, removed = physical:remove(query, physicalQuantity)
            if not ok then self.undo = nil; return false, removed end
        end
        local shortfall = quantity - physicalQuantity
        for index = 1, shortfall do
            removed[#removed + 1] = ItemRecord.clone(expected, 1)
        end
        if shortfall > 0 then self.mirrorShortfall = shortfall end
        local mutated, why = H.MutateCompactRemoval(
            record, item, quantity, "live_npc_to_colony_storage"
        )
        if not mutated then
            if physicalQuantity > 0 then physical:restoreRemoved(removed) end
            self.undo = nil
            return false, why
        end
        return true, removed
    end
    function source:restoreRemoved(removed)
        local physicalOK = physical:restoreRemoved(removed)
        if self.undo then
            record.inventory = self.undo
            PNC.Inventory.RebuildCaches(record)
        end
        return physicalOK
    end
    return source
end

return Internal

