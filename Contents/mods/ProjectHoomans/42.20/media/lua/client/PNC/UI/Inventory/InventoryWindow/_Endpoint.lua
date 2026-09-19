local TransferEndpoint = PNC.InventoryTransferEndpoint
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local inventoryNow = Helpers.inventoryNow
local tr = Helpers.tr

function ISPNCInventoryWindow:setNPC(npcId)
    self.npcId = npcId and tostring(npcId) or nil
    self:setTransferEndpoint(TransferEndpoint.NPC(self.npcId))
end

function ISPNCInventoryWindow:setTransferEndpoint(endpoint)
    local payloadApplyGeneration
    self.transferEndpoint = endpoint
    self.npcId = endpoint and endpoint.kind == "npc" and endpoint.id or nil
    self.selectedNPCContainer = "root"
    self.selectedPlayerContainer = "root"
    self.expandedPlayerGroups = {}
    self.expandedNPCGroups = {}
    self.giftMode = false
    self.giftToken = nil
    self.giftIntent = nil
    self.contextSignature = nil
    self.lastInventoryRefreshAt = nil
    self.inventoryRefreshPending = false
    self.inventoryRefreshStartedAt = nil
    self.inventoryRefreshFeedback = nil
    self.inventoryRefreshFeedbackUntil = nil
    self.readOnly = endpoint and endpoint.readOnly == true or false
    self.courierRevision = nil
    self.statusText = self.readOnly and tr("UI_PNC_Storage_ReadOnlyAway",
        "Read only: enter the base to move stockpile items") or nil
    if self.npcList then self.npcList.role = "npc" end
    if self.npcContainerList then self.npcContainerList.role = "npc" end
    if self.giveAllButton and self.giveAllButton.setTitle then
        self.giveAllButton:setTitle(endpoint and endpoint.kind == "storage"
            and tr("UI_PNC_Storage_DepositAll", "Deposit All >")
            or tr("UI_PNC_Inventory_GiveAll", "Give All >"))
    end
    if self.takeAllButton and self.takeAllButton.setTitle then
        self.takeAllButton:setTitle(endpoint and endpoint.kind == "storage"
            and tr("UI_PNC_Storage_WithdrawAll", "< Withdraw All")
            or tr("UI_PNC_Inventory_TakeAll", "< Take All"))
    end
    if self.depositStorageButton and self.depositStorageButton.setVisible then
        self.depositStorageButton:setVisible(endpoint
            and endpoint.kind == "npc")
    end
    self:updateInventoryRefreshButton(inventoryNow())
    payloadApplyGeneration = tonumber(self.inventoryPayloadApplyGeneration) or 0
    if endpoint then endpoint:requestSnapshot() end
    -- A local API request can apply its payload synchronously, which refreshes
    -- this window from OnInventoryPayloadApplied. Remote clients still render
    -- their cached state here and refresh again when the server reply arrives.
    if (tonumber(self.inventoryPayloadApplyGeneration) or 0)
        == payloadApplyGeneration
    then
        self:refreshInventory(true)
    end
end

function ISPNCInventoryWindow:setConversationMode(mode, token, options)
    options = type(options) == "table" and options or {}
    local nextGiftMode = mode == "gift"
    local giftModeChanged = self.giftMode ~= nextGiftMode
    self.giftMode = nextGiftMode
    self.giftToken = token and tostring(token) or nil
    self.giftIntent = options.giftIntent
    self.statusText = self.giftMode
        and "Gift mode: valid gifts only | A Approval (like) / R Respect / F Familiarity"
        or self.statusText
    if self.takeAllButton and self.takeAllButton.setVisible then
        self.takeAllButton:setVisible(not self.giftMode)
    end
    if self.depositStorageButton and self.depositStorageButton.setVisible then
        self.depositStorageButton:setVisible(
            not self.giftMode and self.transferEndpoint
                and self.transferEndpoint.kind == "npc"
        )
    end
    if giftModeChanged then
        self.contextSignature = nil
        self.playerRowsDirty = true
        self:refreshInventory(true)
    end
end

function ISPNCInventoryWindow:payload()
    return self.transferEndpoint and self.transferEndpoint.payload
        and self.transferEndpoint:payload() or nil
end

function ISPNCInventoryWindow:inventory()
    return self.transferEndpoint and self.transferEndpoint.inventory
        and self.transferEndpoint:inventory() or nil
end

return ISPNCInventoryWindow
