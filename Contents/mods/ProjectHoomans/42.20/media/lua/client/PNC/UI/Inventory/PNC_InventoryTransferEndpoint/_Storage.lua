local Endpoint = PNC.InventoryTransferEndpoint
local Helpers = require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Common"
local StorageModel = Helpers.StorageModel
local ROOT_TEXTURE = Helpers.rootTexture
local clientState = Helpers.clientState
local title = Helpers.title

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

return Endpoint
