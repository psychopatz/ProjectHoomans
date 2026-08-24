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

function Internal.PhysicalSelectionSource(items)
    local source = { revision = 0, items = items }
    function source:preview()
        local records = {}
        for index = 1, #self.items do
            local encoded, reason = CoreInventory.encodeItem(self.items[index], 1)
            if not encoded then return nil, reason end
            records[#records + 1] = encoded
        end
        return records
    end
    function source:remove(_, quantity)
        quantity = math.max(1, math.floor(tonumber(quantity) or #self.items))
        if quantity ~= #self.items then return false, "quantity_mismatch" end
        local records, reason = self:preview()
        if not records then return false, reason end
        local removed = { physicalItems = {}, physicalAdapters = {} }
        for index = 1, #self.items do
            local item = self.items[index]
            local container = item and item.getContainer and item:getContainer() or nil
            local adapter
            adapter, reason = CoreInventory.wrapPhysicalInventory(container)
            if not adapter then self:restoreRemoved(removed); return false, reason end
            if not adapter:_nativeRemove(item) then
                self:restoreRemoved(removed)
                return false, "physical_remove_failed"
            end
            removed[#removed + 1] = records[index]
            removed.physicalItems[#removed.physicalItems + 1] = item
            removed.physicalAdapters[#removed.physicalAdapters + 1] = adapter
        end
        return true, removed
    end
    function source:restoreRemoved(removed)
        for index = #(removed and removed.physicalItems or {}), 1, -1 do
            if not removed.physicalAdapters[index]:_nativeAdd(
                removed.physicalItems[index]
            ) then return false end
        end
        return true
    end
    return source
end

return Internal

