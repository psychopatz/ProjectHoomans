require "PNC/00_PNC_Init"

PNC = PNC or {}
PNC.InventoryTransferEndpoint = PNC.InventoryTransferEndpoint or {}

local Endpoint = PNC.InventoryTransferEndpoint
local Model = PNC.InventoryUIModel
    or require "PNC/UI/Inventory/PNC_InventoryUI_Model"
local StorageModel = PNC.ColonyStorageViewModel
    or require "PNC/UI/Communities/PNC_ColonyStorageViewModel"

local ROOT_TEXTURE = getTexture
    and getTexture("media/ui/Icon_InventoryBasic.png") or nil

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

local function title(value, fallback)
    value = tostring(value or "")
    return value ~= "" and value or fallback
end

function Endpoint.NPC(npcID)
    local endpoint = {
        kind = "npc",
        role = "counterparty",
        id = npcID and tostring(npcID) or nil,
        selectedContainer = "root",
        expandedGroups = {},
    }
    function endpoint:payload()
        local state = clientState()
        return self.id and state.characterPayloads
            and state.characterPayloads[self.id] or nil
    end
    function endpoint:inventory()
        local payload = self:payload()
        return payload and payload.inventory or nil
    end
    function endpoint:revision()
        local inventory = self:inventory()
        return inventory and tonumber(inventory.revision) or -1
    end
    function endpoint:containers()
        return Model.BuildNPCContainers(self:inventory())
    end
    function endpoint:rows()
        return Model.BuildNPCRows(
            self:inventory(), self.selectedContainer, self.expandedGroups
        )
    end
    function endpoint:weight()
        return Model.GetNPCContainerWeight(
            self:inventory(), self.selectedContainer
        )
    end
    function endpoint:requestSnapshot()
        if PNC.Client and PNC.Client.RequestCharacterPayload and self.id then
            PNC.Client.RequestCharacterPayload(self.id)
        end
    end
    function endpoint:send(direction, selection, destination, options)
        options = options or {}
        if not PNC.Client or not PNC.Client.SendInventoryTransfer then
            return false
        end
        local args = {
            id = self.id,
            direction = direction == "to_target"
                and "player_to_npc" or "npc_to_player",
            itemIDs = selection.itemIDs,
            quantity = selection.quantity,
            inventoryRevision = self:revision(),
            bulk = options.bulk == true,
            gift = options.gift == true,
            conversationToken = options.conversationToken,
        }
        if direction == "to_target" then
            args.npcContainer = destination or self.selectedContainer
        else
            args.playerContainer = destination or "root"
        end
        return PNC.Client.SendInventoryTransfer(args)
    end
    return endpoint
end

function Endpoint.Storage(storageID)
    local endpoint = {
        kind = "storage",
        role = "counterparty",
        id = storageID and tostring(storageID) or nil,
        selectedContainer = "root",
        expandedGroups = {},
    }
    function endpoint:snapshot()
        local snapshot = clientState().colonyManagement
        local storage = snapshot and snapshot.storage or nil
        if storage and (not self.id or tostring(storage.storageId) == self.id) then
            self.id = tostring(storage.storageId)
            return storage
        end
        return nil
    end
    function endpoint:revision()
        local storage = self:snapshot()
        return storage and tonumber(storage.inventoryRevision) or -1
    end
    function endpoint:containers()
        return {{
            id = "root",
            label = title(self.displayName, "Stockpile"),
            texture = ROOT_TEXTURE,
        }}
    end
    function endpoint:rows()
        return StorageModel.BuildInventoryRows(
            self:snapshot(), "", "name", self.expandedGroups
        )
    end
    function endpoint:weight()
        local storage = self:snapshot()
        return StorageModel.GetTotalWeight(storage),
            StorageModel.GetCapacity(storage)
    end
    function endpoint:requestSnapshot()
        if PNC.Client and PNC.Client.RequestColonyManagement then
            PNC.Client.RequestColonyManagement()
        end
    end
    function endpoint:send(direction, selection, destination, options)
        if self.readOnly == true then return false, "read_only" end
        if not PNC.Client or not PNC.Client.TransferPlayerStorage then
            return false
        end
        local args = {
            direction = direction == "to_target" and "player_to_storage"
                or "storage_to_player",
            storageId = self.id,
            inventoryRevision = self:revision(),
            playerContainer = destination or "root",
            bulk = options and options.bulk == true,
        }
        if direction == "to_target" then
            args.itemIDs = selection.itemIDs
        else
            args.records = selection.records or {{
                recordIndex = tonumber(selection.recordIndex),
                quantity = selection.quantity,
            }}
        end
        return PNC.Client.TransferPlayerStorage(args)
    end
    return endpoint
end

function Endpoint.SelectionForRow(endpoint, row, requestedQuantity)
    local selection, reason = Model.BuildTransferSelection(row, requestedQuantity)
    if not selection then return nil, reason end
    if endpoint and endpoint.kind == "storage" then
        selection.recordIndex = tonumber(row.recordIndex or row.id)
        selection.records = {{
            recordIndex = selection.recordIndex,
            quantity = selection.quantity,
        }}
        if not selection.recordIndex then return nil, "record_unavailable" end
    end
    return selection
end

function Endpoint.BulkSelection(endpoint, list)
    local selection = { itemIDs = {}, records = {}, quantity = 0 }
    local seen = {}
    for _, entry in ipairs(list and list.items or {}) do
        local row = entry and entry.item or nil
        if row and row.groupHeader ~= true and row.favorite ~= true
            and row.equipped ~= true and row.restricted ~= true
        then
            local quantity = Model.GetRowQuantity(row)
            if endpoint and endpoint.kind == "storage" then
                local recordIndex = tonumber(row.recordIndex or row.id)
                if recordIndex and not seen[recordIndex] then
                    seen[recordIndex] = true
                    selection.records[#selection.records + 1] = {
                        recordIndex = recordIndex,
                        quantity = quantity,
                    }
                    selection.quantity = selection.quantity + quantity
                end
            else
                local rowIDs = row.itemIDs or { row.id }
                for index = 1, #rowIDs do
                    local itemID = rowIDs[index]
                    if itemID and not seen[itemID] then
                        seen[itemID] = true
                        selection.itemIDs[#selection.itemIDs + 1] = itemID
                    end
                end
                selection.quantity = selection.quantity + quantity
            end
        end
    end
    return selection
end

return Endpoint
