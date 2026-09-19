local InventoryWindow = PNC.InventoryWindow
local TransferEndpoint = PNC.InventoryTransferEndpoint
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local tr = Helpers.tr

function ISPNCInventoryWindow:onDepositAllStorage()
    if not self.npcId then return false end
    if #InventoryWindow.CollectBulkTransferIDs(self.npcList) < 1 then
        self.statusText = tr("UI_PNC_Storage_NoCourierItems",
            "No valid items to deposit")
        return false
    end
    self.statusText = tr("UI_PNC_Storage_CourierStarting",
        "Courier ordered: returning home with storage items...")
    return PNC.Client.DepositAllNPCItemsToColony(self.npcId)
end

function InventoryWindow.CollectBulkTransferIDs(list)
    local ids = {}
    local seen = {}
    for _, entry in ipairs(list and list.items or {}) do
        local row = entry and entry.item or nil
        if row and row.favorite ~= true and row.equipped ~= true
            and row.restricted ~= true
        then
            local rowIDs = row.itemIDs or { row.id }
            for index = 1, #rowIDs do
                local itemID = rowIDs[index]
                if itemID and not seen[itemID] then
                    seen[itemID] = true
                    ids[#ids + 1] = itemID
                end
            end
        end
    end
    return ids
end

function ISPNCInventoryWindow:onGiveAll()
    local ok
    local reason
    local details
    local skippedCount
    if self.readOnly then return false end
    local endpoint = self.transferEndpoint
    local selection = TransferEndpoint.BulkSelection(nil, self.playerList)
    if not endpoint or #selection.itemIDs < 1 then
        self.statusText = self.giftMode
            and "No valid gifts in this container"
            or self.statusText
        return false
    end
    ok, reason, details = endpoint:send("to_target", selection,
        endpoint.selectedContainer, {
        bulk = true,
        gift = self.giftMode == true,
        conversationToken = self.giftToken,
    })
    skippedCount = details and details.skipped and #details.skipped or 0
    if ok then
        self.statusText = string.format(
            tr("UI_PNC_Inventory_CopyComplete", "Copied %d item(s)%s"),
            tonumber(details and details.added) or selection.quantity or 0,
            skippedCount > 0 and string.format(
                tr("UI_PNC_Inventory_CopySkipped", ", skipped %d"),
                skippedCount) or ""
        )
    else
        self.statusText = tr("UI_PNC_Inventory_CopyFailed", "Copy failed")
            .. ": " .. tostring(reason or "failed"):gsub("_", " ")
    end
    return ok, reason, details
end

function ISPNCInventoryWindow:onTakeAll()
    if self.readOnly then return false end
    if self.giftMode then
        self.statusText = "Gift mode: taking items is disabled"
        return false
    end
    local endpoint = self.transferEndpoint
    local selection = TransferEndpoint.BulkSelection(endpoint, self.npcList)
    local available = endpoint and endpoint.kind == "storage"
        and #selection.records or #selection.itemIDs
    if not endpoint or available < 1 then return false end
    return endpoint:send("to_player", selection,
        self.selectedPlayerContainer, { bulk = true })
end

return ISPNCInventoryWindow
