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

function H.CompactPreview(item, quantity)
    return CoreInventory.encodeItem(StateCodec.pseudoItem(item), quantity)
end

function H.MutateCompactRemoval(record, item, quantity, reason)
    local stack = math.max(1, math.floor(tonumber(item.stack) or 1))
    if quantity >= stack then
        return PNC.Inventory.RemoveItems(record, { item.id }, reason)
    end
    return PNC.Inventory.ApplyDelta(record, {{
        op = "update", itemID = item.id, stack = stack - quantity,
    }}, reason)
end

function Internal.AbstractNPCSource(record, item, quantity)
    local source = { revision = record.inventory.revision }
    function source:preview()
        local encoded, reason = H.CompactPreview(item, quantity)
        return encoded and { encoded } or nil, reason
    end
    function source:remove()
        local records, reason = self:preview()
        if not records then return false, reason end
        self.undo = PNC.Core.DeepCopy(record.inventory)
        local ok
        ok, reason = H.MutateCompactRemoval(
            record, item, quantity, "npc_to_colony_storage"
        )
        if not ok then self.undo = nil; return false, reason end
        return true, records
    end
    function source:restoreRemoved()
        if not self.undo then return false end
        record.inventory = self.undo
        PNC.Inventory.RebuildCaches(record)
        return true
    end
    return source
end

return Internal

