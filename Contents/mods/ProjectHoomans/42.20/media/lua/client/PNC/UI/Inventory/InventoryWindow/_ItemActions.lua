local Model = PNC.InventoryUIModel
local Actions = PNC.InventoryActions
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local tr = Helpers.tr

function ISPNCInventoryWindow:showItemContext(role, row)
    local context = ISContextMenu.get(0, getMouseX(), getMouseY())
    if self.readOnly then
        local option = context:addOption(
            tr("UI_PNC_Storage_ReadOnlyAway",
                "Read only: enter the base to move stockpile items"),
            nil, nil)
        if option then option.notAvailable = true end
        return
    end
    if self.giftMode and role == "npc" then
        local option = context:addOption(
            "Gift mode: taking items is disabled",
            nil,
            nil
        )
        if option then option.notAvailable = true end
        return
    end
    if row.restricted == true then
        local option = context:addOption(
            tr("UI_PNC_Inventory_OffLimits", "Off Limits"),
            nil,
            nil
        )
        if option then option.notAvailable = true end
        return
    end
    if role == "player" then
        context:addOption(
            self.transferEndpoint and self.transferEndpoint.kind == "storage"
                and tr("UI_PNC_Storage_Deposit", "Deposit to Storage")
                or tr("UI_PNC_Inventory_Give", "Transfer to Companion"),
            self,
            function(target)
                target:requestTransfer("player_to_npc", row)
            end
        )
        if self.transferEndpoint and self.transferEndpoint.kind == "npc"
            and PNC.Client and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
        then
            context:addOption(
                tr("UI_PNC_Storage_Deposit", "Deposit to Colony Storage"),
                self,
                function(target)
                    local selection = Model.BuildTransferSelection(row)
                    if not selection then return false end
                    target.statusText = tr(
                        "UI_PNC_Storage_Depositing", "Depositing..."
                    )
                    return PNC.Client.DepositPlayerItemsToColony(
                        selection.itemIDs
                    )
                end
            )
        end
        return
    end
    local inventory = self:inventory()
    local compact = inventory and inventory.items and inventory.items[row.id] or nil
    if self.transferEndpoint and self.transferEndpoint.kind ~= "storage"
        and row.groupHeader ~= true
    then
        for _, definition in ipairs(Actions.List()) do
            if not (self.transferEndpoint.kind == "local_draft"
                and definition.id == "drop")
                and Actions.IsAvailable(definition, nil, compact)
            then
                local option = context:addOption(
                    tr(definition.labelKey, definition.label),
                    self,
                    function(target)
                        target:sendItemAction(definition.id, row.id)
                    end
                )
                if option and definition.iconTexture and getTexture then
                    option.iconTexture = getTexture(definition.iconTexture)
                end
            end
        end
    end
    context:addOption(
        self.transferEndpoint and self.transferEndpoint.kind == "storage"
            and tr("UI_PNC_Storage_Withdraw", "Withdraw to Player")
            or tr("UI_PNC_Inventory_Take", "Transfer to Player"),
        self,
        function(target)
            target:requestTransfer("npc_to_player", row)
        end
    )
end

function ISPNCInventoryWindow:sendItemAction(actionID, itemID)
    if self.giftMode then
        self.statusText = "Gift mode: item actions are disabled"
        return false
    end
    local inventory = self:inventory()
    if not inventory then return false end
    local item = inventory.items and inventory.items[tostring(itemID)] or nil
    if item and item.interactionLocked == true then return false end
    self.statusText = tr("UI_PNC_Inventory_Working", "Applying command...")
    if self.transferEndpoint and self.transferEndpoint.action then
        local ok, reason = self.transferEndpoint:action(actionID, itemID)
        self.contextSignature = nil
        self.statusText = ok
            and tr("UI_PNC_Inventory_Complete", "Transfer complete")
            or (tr("UI_PNC_Inventory_Failed", "Inventory action failed")
                .. ": " .. tostring(reason or "failed"):gsub("_", " "))
        return ok, reason
    end
    return PNC.Client.SendInventoryAction({
        id = self.npcId,
        actionID = actionID,
        itemID = itemID,
        inventoryRevision = inventory.revision,
    })
end

return ISPNCInventoryWindow
