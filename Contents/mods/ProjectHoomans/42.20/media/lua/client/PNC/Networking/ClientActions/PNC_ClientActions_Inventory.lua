-- Inventory action transport for the client action façade.
--
-- Semantic gifts and inventory UI both use this boundary. The client may
-- enqueue a multiplayer request, while singleplayer still uses the same
-- authoritative server-side implementation and result projection.
PNC = PNC or {}
PNC.Client = PNC.Client or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

local function nextInventoryRequestID()
    ClientState.inventoryRequestSerial =
        (tonumber(ClientState.inventoryRequestSerial) or 0) + 1
    return table.concat({
        tostring(getTimeInMillis and getTimeInMillis() or Core.Now()),
        tostring(ClientState.inventoryRequestSerial),
    }, ":")
end

function Client.SendInventoryTransfer(args)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or type(args) ~= "table" or not args.id then return false end
    args.requestId = args.requestId or nextInventoryRequestID()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(player, Const.MODULE, Const.CMD_INVENTORY_TRANSFER, args)
        return true
    end
    if PNC.ServerInventory and PNC.ServerInventory.Transfer then
        local success, reason, result = PNC.ServerInventory.Transfer(player, args)
        if result and result.relationshipDelta then
            ClientState.lastConversationDelta = {
                npcID = result.npcId or args.id,
                source = result.giftEffect and "gift" or "inventory",
                delta = Core.DeepCopy(result.relationshipDelta),
                before = Core.DeepCopy(result.relationshipBefore),
                after = Core.DeepCopy(result.relationshipAfter),
                itemTypes = Core.DeepCopy(result.itemTypes),
                at = Core.Now(),
            }
            local relationship = PNC.Conversation
                and PNC.Conversation.Relationship
            if relationship and relationship.ReceiveAfter then
                relationship.ReceiveAfter(
                    result.npcId or args.id,
                    result.relationshipAfter,
                    result.relationshipDelta,
                    {
                        source = result.giftEffect and "gift"
                            or "inventory",
                        eventID = result.eventID or args.requestId,
                        revision = result.relationshipAfter
                            and result.relationshipAfter.revision,
                    }
                )
            end
        end
        Client.RequestCharacterPayload(args.id)
        if PNC.InventoryWindow and PNC.InventoryWindow.OnResult then
            result = result or {}
            result.success = success == true
            result.reason = reason
            result.npcId = args.id
            result.requestId = args.requestId
            result.gift = args.gift == true
            PNC.InventoryWindow.OnResult(result)
        end
        return success == true
    end
    return false
end

function Client.SendInventoryAction(args)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or type(args) ~= "table" or not args.id
        or not args.itemID or not args.actionID
    then
        return false
    end
    args.requestId = args.requestId or nextInventoryRequestID()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(player, Const.MODULE, Const.CMD_INVENTORY_ACTION, args)
        return true
    end
    if PNC.ServerInventory and PNC.ServerInventory.Action then
        local success, reason = PNC.ServerInventory.Action(player, args)
        Client.RequestCharacterPayload(args.id)
        if PNC.InventoryWindow and PNC.InventoryWindow.OnResult then
            PNC.InventoryWindow.OnResult({
                success = success == true,
                reason = reason,
                npcId = args.id,
                requestId = args.requestId,
            })
        end
        return success == true
    end
    return false
end

return Client
