local Model = PNC.InventoryUIModel
local TransferEndpoint = PNC.InventoryTransferEndpoint
local QuantityModal = PNC.InventoryQuantityModal
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local tr = Helpers.tr
local mouseInside = Helpers.mouseInside

function ISPNCInventoryWindow:beginInventoryDrag(role, row)
    if self.readOnly then
        self.statusText = tr("UI_PNC_Storage_ReadOnlyAway",
            "Read only: enter the base to move stockpile items")
        return false
    end
    if self.giftMode and role == "npc" then
        self.statusText = "Gift mode: taking items is disabled"
        return false
    end
    if not row or row.restricted == true then return false end
    self.dragState = { source = role, row = row }
    return true
end

function ISPNCInventoryWindow:sendTransfer(
    direction,
    row,
    destinationOverride,
    quantity
)
    local endpoint = self.transferEndpoint
    local selection
    if self.readOnly or not endpoint or not row or row.restricted == true then
        return false
    end
    if self.giftMode and direction ~= "player_to_npc" then
        self.statusText = "Gift mode: taking items is disabled"
        return false
    end
    selection = TransferEndpoint.SelectionForRow(endpoint, row, quantity)
    if not selection then return false end
    self.statusText = tr("UI_PNC_Inventory_Transferring", "Transferring...")
    return endpoint:send(
        direction == "player_to_npc" and "to_target" or "to_player",
        selection,
        destinationOverride or (direction == "player_to_npc"
            and self.selectedNPCContainer or self.selectedPlayerContainer), {
        gift = self.giftMode == true,
        conversationToken = self.giftToken,
    })
end

function ISPNCInventoryWindow:requestTransfer(
    direction,
    row,
    destinationOverride
)
    local maximum = Model.GetRowQuantity(row)
    if self.readOnly or not row or row.restricted == true then return false end
    if self.giftMode and direction ~= "player_to_npc" then
        self.statusText = "Gift mode: taking items is disabled"
        return false
    end
    if maximum <= 1 then
        return self:sendTransfer(direction, row, destinationOverride, 1)
    end
    QuantityModal.Open(
        maximum,
        tostring(row.name or tr("UI_PNC_Inventory_Item", "Item")),
        self,
        function(target, quantity)
            target:sendTransfer(
                direction,
                row,
                destinationOverride,
                quantity
            )
        end
    )
    return true
end

function ISPNCInventoryWindow:acceptVanillaItems(items)
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if self.readOnly then return false end
    local members = {}
    for _, item in ipairs(items or {}) do
        if item and item.getID
            and (not Model.GetPlayerItemTransferBlockReason
                or not Model.GetPlayerItemTransferBlockReason(item, player))
        then
            members[#members + 1] = {
                id = tostring(item:getID()),
                stack = 1,
                nativeItem = item,
            }
        end
    end
    if #members < 1 then return false end
    local first = members[1]
    local name = first.nativeItem and first.nativeItem.getDisplayName
        and first.nativeItem:getDisplayName() or "Items"
    return self:requestTransfer("player_to_npc", {
        source = "player",
        id = first.id,
        name = tostring(name),
        stack = #members,
        members = members,
    }, self.selectedNPCContainer)
end

function ISPNCInventoryWindow:completeInventoryDrop(targetRole)
    if self.readOnly then
        self.dragState = nil
        return false
    end
    local drag = self.dragState
    self.dragState = nil
    if self.giftMode and drag and drag.source == "npc" then
        self.statusText = "Gift mode: taking items is disabled"
        return false
    end
    if drag and drag.source ~= targetRole then
        return self:requestTransfer(
            drag.source == "player" and "player_to_npc" or "npc_to_player",
            drag.row
        )
    end

    if targetRole == "npc" and ISInventoryPane
        and type(ISInventoryPane.draggedItems) == "table"
        and #ISInventoryPane.draggedItems > 0
    then
        local inventory = self:inventory()
        local ids = {}
        for _, item in ipairs(ISInventoryPane.draggedItems) do
            if item and item.getID then ids[#ids + 1] = tostring(item:getID()) end
        end
        if #ids > 0 and inventory then
            local dragged = ISInventoryPane.draggedItems
            ISInventoryPane.draggedItems = {}
            return self:acceptVanillaItems(dragged)
        end
    end
    return false
end

function ISPNCInventoryWindow:completeInventoryDropAtMouse()
    if self.readOnly then
        self.dragState = nil
        return false
    end
    if self.giftMode and self.dragState and self.dragState.source == "npc" then
        self.dragState = nil
        self.statusText = "Gift mode: taking items is disabled"
        return false
    end
    if mouseInside(self.playerList) then return self:completeInventoryDrop("player") end
    if mouseInside(self.playerContainerList) then
        return self:completeInventoryDrop("player")
    end
    if mouseInside(self.npcList) then return self:completeInventoryDrop("npc") end
    if mouseInside(self.npcContainerList) then
        return self:completeInventoryDrop("npc")
    end
    if self.dragState and self.dragState.source == "npc"
        and PNC.InventoryDragBridge
        and PNC.InventoryDragBridge.ResolveVanillaDestinationAtMouse
    then
        local destination = PNC.InventoryDragBridge.ResolveVanillaDestinationAtMouse()
        if destination then
            local row = self.dragState.row
            self.dragState = nil
            return self:requestTransfer("npc_to_player", row, destination)
        end
    end
    self.dragState = nil
    return false
end

return ISPNCInventoryWindow
