local Endpoint = PNC.InventoryTransferEndpoint
local Helpers = require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Common"
local Model = Helpers.Model
local clientState = Helpers.clientState

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
    function endpoint:requestSnapshot(forceFull)
        if PNC.Client and self.id then
            -- Inventory windows need a full item snapshot, but not the much
            -- larger detailed character snapshot used by the profile panel.
            if PNC.Client.RequestCharacterInventoryPayload then
                return PNC.Client.RequestCharacterInventoryPayload(self.id)
            end
            -- Keep compatibility with older client request modules while
            -- they are being hot-reloaded.
            if PNC.Client.RequestCharacterPayload then
                return PNC.Client.RequestCharacterPayload(
                    self.id, forceFull ~= false)
            end
        end
        return false
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

return Endpoint
