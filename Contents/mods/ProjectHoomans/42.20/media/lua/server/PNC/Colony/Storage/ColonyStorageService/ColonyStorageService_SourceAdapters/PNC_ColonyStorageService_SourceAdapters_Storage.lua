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

function Internal.StorageSelectionSource(storage, selections, owner)
    local source = { revision = storage.inventory.revision, tokens = {} }
    local total = 0
    for index = 1, #(selections or {}) do
        local selection = selections[index]
        local record = storage.inventory.records[
            math.floor(tonumber(selection.recordIndex) or 0)
        ]
        local quantity = math.max(1,
            math.floor(tonumber(selection.quantity) or 1))
        if not record then
            for tokenIndex = 1, #source.tokens do
                storage.inventory:releaseReservation(source.tokens[tokenIndex])
            end
            return nil, "record_not_found"
        end
        local selectedRecord = record
        local token, reason = storage.inventory:reserve({
            typeId = selectedRecord[Internal.Constants.TYPE_ID],
            predicate = function(candidate) return candidate == selectedRecord end,
        }, quantity, owner)
        if not token then
            for tokenIndex = 1, #source.tokens do
                storage.inventory:releaseReservation(source.tokens[tokenIndex])
            end
            return nil, reason or "reservation_failed"
        end
        source.tokens[#source.tokens + 1] = token
        total = total + quantity
    end
    source.quantity = total
    function source:remove(_, quantity)
        if quantity ~= self.quantity then return false, "quantity_mismatch" end
        local removed = {}
        for index = 1, #self.tokens do
            local ok, records = storage.inventory:commitReservation(
                self.tokens[index]
            )
            if not ok then
                for pending = index + 1, #self.tokens do
                    storage.inventory:releaseReservation(self.tokens[pending])
                end
                self:restoreRemoved(removed)
                return false, records
            end
            for recordIndex = 1, #records do
                removed[#removed + 1] = records[recordIndex]
            end
        end
        return true, removed
    end
    function source:restoreRemoved(removed)
        for index = 1, #(removed or {}) do
            local ok = storage.inventory:add(removed[index])
            if not ok then return false end
        end
        return true
    end
    function source:release()
        for index = 1, #self.tokens do
            storage.inventory:releaseReservation(self.tokens[index])
        end
    end
    return source
end

return Internal

