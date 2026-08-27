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

function Internal.NPCBulkSource(record)
    local inventory = PNC.Inventory.EnsureRecordInventory(record)
    local body = PNC.Registry.GetLiveZombie(record.id)
    local entries = {}
    for _, item in pairs(inventory.items or {}) do
        if not Internal.IsNPCDepositForbiddenItem(item)
            and item.fav ~= true
            and not item.equipSlot and not item.wornSlot
            and not item.attachedSlot
        then
            entries[#entries + 1] = item
        end
    end
    table.sort(entries, function(first, second)
        return tostring(first.id or "") < tostring(second.id or "")
    end)
    if #entries < 1 then return nil, "no_depositable_items" end
    local children = {}
    local total = 0
    for index = 1, #entries do
        local item = entries[index]
        local quantity = math.max(1, math.floor(tonumber(item.stack) or 1))
        local child, reason
        if body then
            child, reason = Internal.LiveNPCSource(
                record, item, quantity, body)
        else
            child = Internal.AbstractNPCSource(record, item, quantity)
        end
        if not child then return nil, reason end
        children[#children + 1] = {
            source = child,
            quantity = quantity,
            item = item,
        }
        total = total + quantity
    end
    local source = { children = children, quantity = total }
    function source:preview()
        local output = {}
        for index = 1, #self.children do
            local records, reason = self.children[index].source:preview()
            if not records then return nil, reason end
            for recordIndex = 1, #records do
                output[#output + 1] = records[recordIndex]
            end
        end
        return output
    end
    function source:remove(_, quantity)
        if quantity ~= self.quantity then return false, "quantity_mismatch" end
        local removed = { batches = {} }
        for index = 1, #self.children do
            local child = self.children[index]
            local ok, records = child.source:remove(nil, child.quantity)
            if not ok then
                self:restoreRemoved(removed)
                return false, records
            end
            removed.batches[#removed.batches + 1] = {
                source = child.source,
                records = records,
            }
            for recordIndex = 1, #records do
                removed[#removed + 1] = records[recordIndex]
            end
        end
        return true, removed
    end
    function source:restoreRemoved(removed)
        local ok = true
        for index = #(removed and removed.batches or {}), 1, -1 do
            local batch = removed.batches[index]
            if batch.source:restoreRemoved(batch.records) ~= true then
                ok = false
            end
        end
        return ok
    end
    return source, nil, entries, total
end

return Internal
