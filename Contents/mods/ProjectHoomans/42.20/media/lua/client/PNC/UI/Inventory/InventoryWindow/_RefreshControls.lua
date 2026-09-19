local InventoryWindow = PNC.InventoryWindow
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local inventoryNow = Helpers.inventoryNow
local tr = Helpers.tr
local INVENTORY_REFRESH_COOLDOWN_MS = Helpers.INVENTORY_REFRESH_COOLDOWN_MS

function ISPNCInventoryWindow:onRefreshNPCInventory()
    local endpoint = self.transferEndpoint
    local now = inventoryNow()
    local last = tonumber(self.lastInventoryRefreshAt)
    if not endpoint or endpoint.kind ~= "npc" or not self.npcId then
        return false
    end
    if self.inventoryRefreshPending == true
        or (last ~= nil and now - last < INVENTORY_REFRESH_COOLDOWN_MS)
    then
        return false
    end
    self.lastInventoryRefreshAt = now
    self.inventoryRefreshPending = true
    self.inventoryRefreshStartedAt = now
    self.inventoryRefreshFeedback = nil
    self.inventoryRefreshFeedbackUntil = nil
    self.contextSignature = nil
    self:updateInventoryRefreshButton(now)
    self:refreshInventory(true)
    local requested = endpoint.requestSnapshot
        and endpoint:requestSnapshot(true) or false
    if requested ~= true then
        self:finishInventoryRefresh(false, inventoryNow())
        return false
    end
    return true
end

function InventoryWindow.OnInventoryPayloadApplied(npcID, revision, source)
    local window = InventoryWindow.instance
    if not window or not window.transferEndpoint
        or window.transferEndpoint.kind ~= "npc"
        or tostring(window.transferEndpoint.id or "") ~= tostring(npcID or "")
    then
        return false
    end
    window.inventoryPayloadApplyGeneration =
        (tonumber(window.inventoryPayloadApplyGeneration) or 0) + 1
    window.contextSignature = nil
    window.inventoryPayloadSource = source
    window.inventoryPayloadRevision = tonumber(revision)
    if window.inventoryRefreshPending == true
        and (source == "character_payload" or source == "local_api"
            or source == "inventory_payload")
    then
        window:finishInventoryRefresh(true, inventoryNow())
    end
    window:refreshInventory(true)
    window:updateInventoryTooltip()
    return true
end

return InventoryWindow
