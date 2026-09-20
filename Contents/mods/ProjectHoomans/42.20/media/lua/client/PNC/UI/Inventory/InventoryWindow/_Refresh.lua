local Model = PNC.InventoryUIModel
local ClientState = PNC.Network.ClientState
local Identity = PNC.NPCIdentityPresentation
local InventoryWindow = PNC.InventoryWindow
local Helpers = require "PNC/UI/Inventory/InventoryWindow/_Helpers"
local inventoryNow = Helpers.inventoryNow
local tr = Helpers.tr
local INVENTORY_REFRESH_COOLDOWN_MS = Helpers.INVENTORY_REFRESH_COOLDOWN_MS
local INVENTORY_REFRESH_TIMEOUT_MS = Helpers.INVENTORY_REFRESH_TIMEOUT_MS
local INVENTORY_REFRESH_FEEDBACK_MS = Helpers.INVENTORY_REFRESH_FEEDBACK_MS

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

local function playerRowsStateSignature(rows)
    local protectedState = {}
    for index = 1, #(rows or {}) do
        local row = rows[index]
        protectedState[index] = table.concat({
            tostring(row.id or ""),
            row.favorite == true and "f" or "-",
            row.equipped == true and "e" or "-",
            tostring(row.giftPreference or ""),
            tostring(row.stack or 1),
            table.concat(row.itemIDs or { row.id or "" }, ","),
            tostring(row.stateKey or ""),
        }, "")
    end
    return table.concat(protectedState, ",")
end

local function playerGiftKnowledge(window)
    local npcID = window and window.npcId
        and tostring(window.npcId) or ""
    local snapshot = npcID ~= ""
        and ClientState.npcKnowledge
        and ClientState.npcKnowledge[npcID] or nil
    return snapshot, tonumber(snapshot and snapshot.revision) or 0
end

local function buildPlayerRows(window, containerEntry, player, playerCount)
    local knowledge, knowledgeRevision = playerGiftKnowledge(window)
    local rows = Model.BuildPlayerRows(
        containerEntry,
        player,
        window.expandedPlayerGroups,
        window.giftMode == true,
        knowledge and knowledge.giftPreferences or nil
    )
    window.playerRowsCache = rows
    window.playerRowsSignature = playerRowsStateSignature(rows)
    window.playerRowsContainer = containerEntry
        and containerEntry.container or nil
    window.playerRowsCount = playerCount
    window.playerRowsNPCID = window.npcId and tostring(window.npcId) or ""
    window.playerRowsKnowledgeRevision = knowledgeRevision
    window.playerRowsDirty = false
    return rows
end

function ISPNCInventoryWindow:refreshInventory(force)
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    local endpoint = self.transferEndpoint
    if not endpoint then return end
    if force == true then self.playerRowsDirty = true end
    self:updateInventoryRefreshButton(inventoryNow())
    endpoint.selectedContainer = self.selectedNPCContainer or "root"
    endpoint.expandedGroups = self.expandedNPCGroups or {}
    local revision = endpoint:revision()
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
    local playerCount = player and player.getInventory and player:getInventory()
        and player:getInventory():getItems()
        and player:getInventory():getItems():size()
        or 0
    local playerContainer = currentPlayerContainer
        and currentPlayerContainer.container or nil
    local currentPlayerRows = self.playerRowsCache
    local _, giftKnowledgeRevision = playerGiftKnowledge(self)
    local currentNPCID = self.npcId and tostring(self.npcId) or ""
    -- prerender calls refreshInventory every frame; keep native item probing
    -- and sorting behind explicit inventory invalidation.
    if self.playerRowsDirty == true
        or type(currentPlayerRows) ~= "table"
        or self.playerRowsContainer ~= playerContainer
        or tonumber(self.playerRowsCount) ~= tonumber(playerCount)
        or self.playerRowsNPCID ~= currentNPCID
        or tonumber(self.playerRowsKnowledgeRevision)
            ~= giftKnowledgeRevision
    then
        currentPlayerRows = buildPlayerRows(
            self, currentPlayerContainer, player, playerCount
        )
    end
    local signature = table.concat({
        tostring(endpoint.kind),
        tostring(endpoint.id or ""),
        tostring(revision),
        tostring(playerCount),
        tostring(self.playerRowsSignature or ""),
        tostring(self.selectedNPCContainer),
        tostring(self.selectedPlayerContainer),
        self.readOnly and "readonly" or "writable",
        tostring(self.npcId and ClientState.snapshots
            and ClientState.snapshots[self.npcId]
            and ClientState.snapshots[self.npcId].storageCourier
            and ClientState.snapshots[self.npcId].storageCourier.revision or 0),
    }, "|")
    if not force and signature == self.contextSignature then return end
    self.contextSignature = signature

    self.playerContainers = Model.BuildPlayerContainers(player)
    if not Model.FindContainer(self.playerContainers, self.selectedPlayerContainer) then
        self.selectedPlayerContainer = "root"
    end
    local selectedPlayerContainer = Model.FindContainer(
        self.playerContainers,
        self.selectedPlayerContainer
    )
    local playerRows = currentPlayerRows
    if not selectedPlayerContainer
        or currentPlayerContainer.id ~= selectedPlayerContainer.id
        or currentPlayerContainer.container ~= selectedPlayerContainer.container
    then
        playerRows = buildPlayerRows(self, selectedPlayerContainer,
            player, playerCount)
    end
    self.npcContainers = endpoint:containers()
    if not Model.FindContainer(self.npcContainers, self.selectedNPCContainer) then
        self.selectedNPCContainer = "root"
    end
    resetList(self.playerList, playerRows)
    endpoint.selectedContainer = self.selectedNPCContainer
    resetList(self.npcList, endpoint:rows())
    if self.giveAllButton and self.giveAllButton.setEnable then
        self.giveAllButton:setEnable(
            not self.readOnly
                and #InventoryWindow.CollectBulkTransferIDs(self.playerList) > 0
        )
    end
    if self.takeAllButton and self.takeAllButton.setEnable then
        self.takeAllButton:setEnable(
            not self.readOnly and not self.giftMode
                and #InventoryWindow.CollectBulkTransferIDs(self.npcList) > 0
        )
    end
    if self.depositStorageButton and self.depositStorageButton.setEnable then
        self.depositStorageButton:setEnable(
            endpoint.kind == "npc" and not self.giftMode
                and #InventoryWindow.CollectBulkTransferIDs(self.npcList) > 0
        )
    end
    self:updateInventoryRefreshButton(inventoryNow())
    if self.takeAllButton and self.takeAllButton.setVisible then
        self.takeAllButton:setVisible(not self.giftMode)
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
    local payload = self:payload()
    local courier = payload and payload.snapshot
        and payload.snapshot.storageCourier or snapshot
            and snapshot.storageCourier or nil
    if courier and tonumber(courier.revision) ~= self.courierRevision then
        self.courierRevision = tonumber(courier.revision)
        local state = tostring(courier.state or "")
        if state == "RETURNING_HOME" then
            self.statusText = tr("UI_PNC_Storage_CourierReturning",
                "Courier is returning home to deposit all items")
        elseif state == "DEPOSITING" then
            self.statusText = tr("UI_PNC_Storage_CourierDepositing",
                "Courier arrived and is depositing items")
        elseif state == "COMPLETED" then
            self.statusText = string.format("%s (%d items)",
                tr("UI_PNC_Storage_CourierComplete",
                    "Courier job complete"),
                tonumber(courier.quantity) or 0)
        elseif state == "FAILED" or state == "CANCELLED" then
            self.statusText = tr("UI_PNC_Storage_CourierFailed",
                "Courier job ended") .. ": "
                .. tostring(courier.reason or state):gsub("_", " ")
        end
    elseif self.readOnly and not self.statusText then
        self.statusText = tr("UI_PNC_Storage_ReadOnlyAway",
            "Read only: enter the base to move stockpile items")
    end
    local npcName = endpoint.kind == "storage"
        and tostring(endpoint.displayName or "Colony Storage")
        or endpoint.kind == "local_draft"
        and tostring(endpoint.displayName or "Unique NPC Draft")
        or Identity.GetName(
            payload and payload.snapshot or snapshot or { id = self.npcId }
        )
    self.npcDisplayName = tostring(npcName)
    if self.setTitle then
        self:setTitle(tr("UI_PNC_Inventory_Title", "Inventory") .. " - " .. tostring(npcName))
    end
end

local function invalidatePlayerRows()
    local window = InventoryWindow.instance
    if not window then return end
    window.playerRowsDirty = true
    window.contextSignature = nil
end

InventoryWindow.InvalidatePlayerRows = invalidatePlayerRows

local invalidationEvents = {
    "OnContainerUpdate",
    "OnRefreshInventoryWindowContainers",
    "OnEquipPrimary",
    "OnEquipSecondary",
    "OnClothingUpdated",
}
local previousInvalidationCallback =
    InventoryWindow.playerRowsInvalidationCallback
for _, eventName in ipairs(invalidationEvents) do
    local event = Events and Events[eventName] or nil
    if event then
        if previousInvalidationCallback and event.Remove then
            event.Remove(previousInvalidationCallback)
        end
        if event.Add then event.Add(invalidatePlayerRows) end
    end
end
InventoryWindow.playerRowsInvalidationCallback = invalidatePlayerRows

return ISPNCInventoryWindow
