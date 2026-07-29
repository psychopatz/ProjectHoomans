require "ISUI/ISButton"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Inventory/PNC_InventoryUI_Model"
require "PNC/UI/Inventory/PNC_InventoryUI_List"
require "PNC/UI/Inventory/PNC_InventoryUI_ContainerList"
require "PNC/UI/Inventory/PNC_InventoryQuantityModal"

PNC = PNC or {}
PNC.InventoryWindow = PNC.InventoryWindow or {}

local InventoryWindow = PNC.InventoryWindow
local Model = PNC.InventoryUIModel
local ClientState = PNC.Network.ClientState
local Actions = PNC.InventoryActions
local QuantityModal = PNC.InventoryQuantityModal
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function absoluteBounds(control)
    local x = control.getAbsoluteX and control:getAbsoluteX() or control:getX()
    local y = control.getAbsoluteY and control:getAbsoluteY() or control:getY()
    return x, y, control:getWidth(), control:getHeight()
end

local function mouseInside(control)
    local x, y, w, h = absoluteBounds(control)
    local mx = getMouseX and getMouseX() or -1
    local my = getMouseY and getMouseY() or -1
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

ISPNCInventoryWindow = UI.Window:derive("ISPNCInventoryWindow")

function ISPNCInventoryWindow:initialise()
    UI.Window.initialise(self)
end

function ISPNCInventoryWindow:createChildren()
    UI.Window.createChildren(self)
    self.playerContainerList = ISPNCInventoryContainerList:new(
        268, 88, 40, 348, self, "player"
    )
    self.playerContainerList:initialise()
    self.playerContainerList:instantiate()
    self:addChild(self.playerContainerList)

    self.npcContainerList = ISPNCInventoryContainerList:new(
        576, 88, 40, 348, self, "npc"
    )
    self.npcContainerList:initialise()
    self.npcContainerList:instantiate()
    self:addChild(self.npcContainerList)

    self.playerList = ISPNCInventoryList:new(8, 76, 300, 360, self, "player")
    self.playerList:initialise()
    self.playerList:instantiate()
    self:addChild(self.playerList)

    self.npcList = ISPNCInventoryList:new(316, 76, 300, 360, self, "npc")
    self.npcList:initialise()
    self.npcList:instantiate()
    self:addChild(self.npcList)

    self.giveAllButton = ISButton:new(8, 440, 92, 22,
        tr("UI_PNC_Inventory_GiveAll", "Give All >"),
        self, ISPNCInventoryWindow.onGiveAll)
    self.giveAllButton:initialise()
    self.giveAllButton:instantiate()
    self:addChild(self.giveAllButton)

    self.takeAllButton = ISButton:new(316, 440, 92, 22,
        tr("UI_PNC_Inventory_TakeAll", "< Take All"),
        self, ISPNCInventoryWindow.onTakeAll)
    self.takeAllButton:initialise()
    self.takeAllButton:instantiate()
    self:addChild(self.takeAllButton)
    self:onResponsiveLayout()
    self:refreshInventory(true)
end

function ISPNCInventoryWindow:onResponsiveLayout()
    if not self.playerList or not self.npcList
        or not self.playerContainerList or not self.npcContainerList
    then
        return
    end
    local titleHeight = self:titleBarHeight()
    local top = titleHeight + 70
    local bottom = 56 + self:resizeWidgetHeight()
    local gap = 8
    local paneWidth = math.max(180, math.floor((self.width - gap * 3) / 2))
    local railWidth = 40
    local railGap = 4
    local itemWidth = math.max(132, paneWidth - railWidth - railGap)
    local listHeight = math.max(120, self.height - top - bottom)
    local buttonY = top + listHeight + 4
    local npcX = gap * 2 + paneWidth
    Layout.SetBounds(self.playerList, gap, top, itemWidth, listHeight)
    Layout.SetBounds(
        self.playerContainerList,
        gap + itemWidth + railGap,
        top,
        railWidth,
        listHeight
    )
    Layout.SetBounds(self.npcList, npcX, top, itemWidth, listHeight)
    Layout.SetBounds(
        self.npcContainerList,
        npcX + itemWidth + railGap,
        top,
        railWidth,
        listHeight
    )
    Layout.SetBounds(self.giveAllButton, gap, buttonY, 92, 22)
    Layout.SetBounds(self.takeAllButton, npcX, buttonY, 92, 22)
    self.playerPaneX = gap
    self.npcPaneX = npcX
    self.paneWidth = paneWidth
    self.headingY = titleHeight + 8
    self.containerLabelY = titleHeight + 29
    self.statusY = buttonY + 27
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
    local inventory = self:inventory()
    local ids = InventoryWindow.CollectBulkTransferIDs(self.playerList)
    if not inventory or #ids < 1 then return false end
    return PNC.Client.SendInventoryTransfer({
        id = self.npcId,
        direction = "player_to_npc",
        itemIDs = ids,
        npcContainer = self.selectedNPCContainer,
        inventoryRevision = inventory.revision,
        bulk = true,
    })
end

function ISPNCInventoryWindow:onTakeAll()
    local inventory = self:inventory()
    local ids = InventoryWindow.CollectBulkTransferIDs(self.npcList)
    if not inventory or #ids < 1 then return false end
    return PNC.Client.SendInventoryTransfer({
        id = self.npcId,
        direction = "npc_to_player",
        itemIDs = ids,
        playerContainer = self.selectedPlayerContainer,
        inventoryRevision = inventory.revision,
        bulk = true,
    })
end

function ISPNCInventoryWindow:setNPC(npcId)
    self.npcId = npcId and tostring(npcId) or nil
    self.selectedNPCContainer = "root"
    self.selectedPlayerContainer = "root"
    self.expandedPlayerGroups = {}
    self.expandedNPCGroups = {}
    self.contextSignature = nil
    if PNC.Client and PNC.Client.RequestCharacterPayload and self.npcId then
        PNC.Client.RequestCharacterPayload(self.npcId)
    end
    self:refreshInventory(true)
end

function ISPNCInventoryWindow:payload()
    return self.npcId and ClientState.characterPayloads
        and ClientState.characterPayloads[self.npcId]
        or nil
end

function ISPNCInventoryWindow:inventory()
    local payload = self:payload()
    return payload and payload.inventory or nil
end

local function resetList(list, rows)
    list:clear()
    for _, row in ipairs(rows or {}) do list:addItem(row.name, row) end
end

local function resetContainerList(list, containers, selectedID)
    list:clear()
    list.selected = 1
    for index, container in ipairs(containers or {}) do
        list:addItem(container.label, container)
        if tostring(container.id) == tostring(selectedID) then
            list.selected = index
        end
    end
end

function ISPNCInventoryWindow:refreshInventory(force)
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    local inventory = self:inventory()
    local revision = inventory and tonumber(inventory.revision) or -1
    local currentPlayerContainer = Model.FindContainer(
        self.playerContainers,
        self.selectedPlayerContainer
    )
    if not currentPlayerContainer then
        currentPlayerContainer = {
            id = "root",
            container = player and player.getInventory and player:getInventory() or nil,
        }
    end
    local currentPlayerRows = Model.BuildPlayerRows(
        currentPlayerContainer,
        player,
        self.expandedPlayerGroups
    )
    local protectedState = {}
    for index = 1, #currentPlayerRows do
        local row = currentPlayerRows[index]
        protectedState[index] = table.concat({
            tostring(row.id or ""),
            row.favorite == true and "f" or "-",
            row.equipped == true and "e" or "-",
            tostring(row.stack or 1),
            table.concat(row.itemIDs or { row.id or "" }, ","),
        }, "")
    end
    local playerCount = player and player.getInventory and player:getInventory()
        and player:getInventory():getItems()
        and player:getInventory():getItems():size()
        or 0
    local signature = table.concat({
        tostring(self.npcId or ""),
        tostring(revision),
        tostring(playerCount),
        table.concat(protectedState, ","),
        tostring(self.selectedNPCContainer),
        tostring(self.selectedPlayerContainer),
    }, "|")
    if not force and signature == self.contextSignature then return end
    self.contextSignature = signature

    self.playerContainers = Model.BuildPlayerContainers(player)
    if not Model.FindContainer(self.playerContainers, self.selectedPlayerContainer) then
        self.selectedPlayerContainer = "root"
    end
    self.npcContainers = Model.BuildNPCContainers(inventory)
    if not Model.FindContainer(self.npcContainers, self.selectedNPCContainer) then
        self.selectedNPCContainer = "root"
    end
    resetList(
        self.playerList,
        Model.BuildPlayerRows(
            Model.FindContainer(self.playerContainers, self.selectedPlayerContainer),
            player,
            self.expandedPlayerGroups
        )
    )
    resetList(self.npcList, Model.BuildNPCRows(
        inventory,
        self.selectedNPCContainer,
        self.expandedNPCGroups
    ))
    if self.giveAllButton and self.giveAllButton.setEnable then
        self.giveAllButton:setEnable(
            #InventoryWindow.CollectBulkTransferIDs(self.playerList) > 0
        )
    end
    if self.takeAllButton and self.takeAllButton.setEnable then
        self.takeAllButton:setEnable(
            #InventoryWindow.CollectBulkTransferIDs(self.npcList) > 0
        )
    end
    resetContainerList(
        self.playerContainerList,
        self.playerContainers,
        self.selectedPlayerContainer
    )
    resetContainerList(
        self.npcContainerList,
        self.npcContainers,
        self.selectedNPCContainer
    )
    local snapshot = self.npcId and ClientState.snapshots
        and ClientState.snapshots[self.npcId] or nil
    local npcName = payload and payload.snapshot and (
        payload.snapshot.displayName or payload.snapshot.name
    ) or snapshot and (snapshot.displayName or snapshot.name) or "Companion"
    self.npcDisplayName = tostring(npcName)
    if self.setTitle then
        self:setTitle(tr("UI_PNC_Inventory_Title", "Inventory") .. " - " .. tostring(npcName))
    end
end

function ISPNCInventoryWindow:beginInventoryDrag(role, row)
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
    local inventory = self:inventory()
    local selection
    if not inventory or not row or row.restricted == true then return false end
    selection = Model.BuildTransferSelection(row, quantity)
    if not selection then return false end
    self.statusText = tr("UI_PNC_Inventory_Transferring", "Transferring...")
    if direction == "player_to_npc" then
        return PNC.Client.SendInventoryTransfer({
            id = self.npcId,
            direction = direction,
            itemIDs = selection.itemIDs,
            quantity = selection.quantity,
            npcContainer = destinationOverride or self.selectedNPCContainer,
            inventoryRevision = inventory.revision,
        })
    end
    return PNC.Client.SendInventoryTransfer({
        id = self.npcId,
        direction = direction,
        itemIDs = selection.itemIDs,
        quantity = selection.quantity,
        playerContainer = destinationOverride or self.selectedPlayerContainer,
        inventoryRevision = inventory.revision,
    })
end

function ISPNCInventoryWindow:requestTransfer(
    direction,
    row,
    destinationOverride
)
    local maximum = Model.GetRowQuantity(row)
    if not row or row.restricted == true then return false end
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
    local members = {}
    for _, item in ipairs(items or {}) do
        if item and item.getID then
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
    local drag = self.dragState
    self.dragState = nil
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

function ISPNCInventoryWindow:showItemContext(role, row)
    local context = ISContextMenu.get(0, getMouseX(), getMouseY())
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
            tr("UI_PNC_Inventory_Give", "Transfer to Companion"),
            self,
            function(target)
                target:requestTransfer("player_to_npc", row)
            end
        )
        return
    end
    local inventory = self:inventory()
    local compact = inventory and inventory.items and inventory.items[row.id] or nil
    if row.groupHeader ~= true then
        for _, definition in ipairs(Actions.List()) do
            if Actions.IsAvailable(definition, nil, compact) then
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
        tr("UI_PNC_Inventory_Take", "Transfer to Player"),
        self,
        function(target)
            target:requestTransfer("npc_to_player", row)
        end
    )
end

function ISPNCInventoryWindow:sendItemAction(actionID, itemID)
    local inventory = self:inventory()
    if not inventory then return false end
    local item = inventory.items and inventory.items[tostring(itemID)] or nil
    if item and item.interactionLocked == true then return false end
    self.statusText = tr("UI_PNC_Inventory_Working", "Applying command...")
    return PNC.Client.SendInventoryAction({
        id = self.npcId,
        actionID = actionID,
        itemID = itemID,
        inventoryRevision = inventory.revision,
    })
end

function ISPNCInventoryWindow:toggleInventoryGroup(role, groupKey)
    if not groupKey then return false end
    local groups = role == "player"
        and self.expandedPlayerGroups or self.expandedNPCGroups
    groups[groupKey] = groups[groupKey] ~= true
    self.contextSignature = nil
    self:refreshInventory(true)
    return true
end

function ISPNCInventoryWindow:getSelectedContainer(role)
    if role == "player" then return self.selectedPlayerContainer end
    return self.selectedNPCContainer
end

function ISPNCInventoryWindow:selectContainer(role, containerID)
    if not containerID then return false end
    if role == "player" then
        self.selectedPlayerContainer = containerID
    else
        self.selectedNPCContainer = containerID
    end
    self:refreshInventory(true)
    return true
end

function ISPNCInventoryWindow:cycleContainer(role, delta)
    local containers = role == "player" and self.playerContainers or self.npcContainers
    local current = role == "player" and self.selectedPlayerContainer or self.selectedNPCContainer
    if not containers or #containers < 2 then return end
    local nextID = delta and delta < 0
        and containers[#containers].id
        or containers[1].id
    for index = 1, #containers do
        if tostring(containers[index].id) == tostring(current) then
            if delta and delta < 0 then
                nextID = containers[((index - 2) % #containers) + 1].id
            else
                nextID = containers[(index % #containers) + 1].id
            end
            break
        end
    end
    self:selectContainer(role, nextID)
end

local function selectedContainerLabel(containers, selected)
    local entry = Model.FindContainer(containers, selected)
    return entry and entry.label or "Inventory"
end

function ISPNCInventoryWindow:prerender()
    self:refreshInventory(false)
    UI.Window.prerender(self)
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    local headingY = self.headingY or self:titleBarHeight() + 8
    local containerY = self.containerLabelY or headingY + 21
    local playerX = self.playerPaneX or 8
    local npcX = self.npcPaneX or math.floor(self.width / 2)
    local paneWidth = self.paneWidth or math.floor((self.width - 24) / 2)
    self:drawRect(playerX, headingY - 3, paneWidth, 19, 0.50, 0.10, 0.12, 0.14)
    self:drawRect(npcX, headingY - 3, paneWidth, 19, 0.50, 0.14, 0.11, 0.08)
    self:drawText(
        tr("UI_PNC_Inventory_PlayerHeading", "YOUR INVENTORY"),
        playerX + 4, headingY, 0.72, 0.86, 1.00, 1, UIFont.Small
    )
    self:drawText(
        Layout.Ellipsize(
            string.upper(tostring(self.npcDisplayName or "Companion")) .. "'S INVENTORY",
            UIFont.Small,
            paneWidth - 8
        ),
        npcX + 4, headingY, 1.00, 0.82, 0.62, 1, UIFont.Small
    )
    local inventory = self:inventory()
    local playerUsed, playerMax = Model.GetPlayerContainerWeight(
        Model.FindContainer(self.playerContainers, self.selectedPlayerContainer),
        player
    )
    local npcUsed, npcMax = Model.GetNPCContainerWeight(
        inventory,
        self.selectedNPCContainer
    )
    local playerContainerText = tr("UI_PNC_Inventory_Container", "Container") .. ": "
        .. selectedContainerLabel(self.playerContainers, self.selectedPlayerContainer)
    local npcContainerText = tr("UI_PNC_Inventory_Container", "Container") .. ": "
        .. selectedContainerLabel(self.npcContainers, self.selectedNPCContainer)
    self:drawText(
        Layout.Ellipsize(playerContainerText, UIFont.Small, paneWidth - 100),
        playerX + 4, containerY, 0.90, 0.90, 0.90, 1, UIFont.Small
    )
    self:drawTextRight(
        string.format("%.1f / %.1f", playerUsed, playerMax),
        playerX + paneWidth - 4, containerY,
        0.90, 0.90, 0.90, 1, UIFont.Small
    )
    self:drawText(
        Layout.Ellipsize(npcContainerText, UIFont.Small, paneWidth - 100),
        npcX + 4, containerY, 0.90, 0.90, 0.90, 1, UIFont.Small
    )
    self:drawTextRight(
        string.format("%.1f / %.1f", npcUsed, npcMax),
        npcX + paneWidth - 4, containerY,
        0.90, 0.90, 0.90, 1, UIFont.Small
    )
    local listY = self.playerList and self.playerList:getY() or containerY + 38
    self:drawText("Item", self.playerList:getX() + 40, listY - 19,
        0.85, 0.85, 0.85, 1, UIFont.Small)
    self:drawText("Category",
        self.playerList:getX() + math.floor(self.playerList.width * 0.64),
        listY - 19, 0.85, 0.85, 0.85, 1, UIFont.Small)
    self:drawText("Item", self.npcList:getX() + 40, listY - 19,
        0.85, 0.85, 0.85, 1, UIFont.Small)
    self:drawText("Category",
        self.npcList:getX() + math.floor(self.npcList.width * 0.64),
        listY - 19, 0.85, 0.85, 0.85, 1, UIFont.Small)
    self:drawTextCentre(
        tr("UI_PNC_Inventory_Bags", "Bags"),
        self.playerContainerList:getX() + math.floor(self.playerContainerList.width / 2),
        listY - 19, 0.85, 0.85, 0.85, 1, UIFont.Small
    )
    self:drawTextCentre(
        tr("UI_PNC_Inventory_Bags", "Bags"),
        self.npcContainerList:getX() + math.floor(self.npcContainerList.width / 2),
        listY - 19, 0.85, 0.85, 0.85, 1, UIFont.Small
    )
    if self.statusText then
        self:drawTextCentre(self.statusText, self.width / 2, self.statusY or self.height - 42,
            0.75, 0.82, 0.90, 1, UIFont.Small)
    else
        self:drawTextCentre(
            tr("UI_PNC_Inventory_DragHint",
                "Bag icons select containers. Drag between sides; right-click NPC items."),
            self.width / 2, self.statusY or self.height - 42,
            0.64, 0.64, 0.64, 1, UIFont.Small
        )
    end
    if self.dragState and self.dragState.row then
        self:drawText(
            tostring(self.dragState.row.name),
            (getMouseX() or 0) - self:getAbsoluteX() + 12,
            (getMouseY() or 0) - self:getAbsoluteY() + 12,
            1, 1, 1, 0.85, UIFont.Small
        )
    end
end

function ISPNCInventoryWindow:onMouseDown(x, y)
    if UI.Window.onMouseDown then
        return UI.Window.onMouseDown(self, x, y)
    end
    return false
end

function ISPNCInventoryWindow:close()
    if QuantityModal and QuantityModal.instance then
        QuantityModal.instance:close()
    end
    InventoryWindow.instance = nil
    UI.Window.close(self)
end

function ISPNCInventoryWindow:new(x, y, width, height, options)
    local o = UI.Window.new(self, x, y, width, height, options or {})
    o.resizable = true
    return o
end

function InventoryWindow.Open(npcId)
    local window = InventoryWindow.instance
    if not window then
        local spec = {
            width = 760, height = 520,
            minWidth = 600, minHeight = 360,
            maxWidth = 1100, maxHeight = 820,
            anchor = "center",
        }
        local bounds = Layout.ResolveWindow(spec)
        window = ISPNCInventoryWindow:new(bounds.x, bounds.y, bounds.width, bounds.height, {
            title = tr("UI_PNC_Inventory_Title", "Inventory"),
            responsiveSpec = spec,
            persistenceKey = "ProjectHoomans:InventoryWindow",
            resizable = true,
        })
        window:initialise()
        window:instantiate()
        window:addToUIManager()
        InventoryWindow.instance = window
    end
    window:setVisible(true)
    window:setNPC(npcId)
    window:bringToTop()
    return window
end

function InventoryWindow.OnResult(result)
    local window = InventoryWindow.instance
    if not window or not result or tostring(result.npcId or "") ~= tostring(window.npcId or "") then
        return
    end
    local reason = tostring(result.reason or "")
    local readable = reason:gsub("_", " ")
    window.statusText = result.success == true
        and tr("UI_PNC_Inventory_Complete", "Transfer complete")
        or (tr("UI_PNC_Inventory_Failed", "Inventory action failed") .. ": " .. readable)
    window.contextSignature = nil
end

return InventoryWindow
