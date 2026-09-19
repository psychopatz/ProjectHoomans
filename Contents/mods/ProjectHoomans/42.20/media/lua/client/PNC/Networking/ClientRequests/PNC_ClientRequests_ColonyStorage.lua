-- Colony storage transfer, rename, and faction request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Core = PNC.Core
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

function Client.DepositPlayerItemsToColony(itemIDs, storageId)
    return Client.RequestColonyAction("storage_player_deposit", {
        itemIDs = itemIDs,
        storageId = storageId,
    })
end

function Client.TransferPlayerStorage(options)
    options = type(options) == "table" and options or {}
    if options.direction == "player_to_storage" then
        return Client.RequestColonyAction("storage_player_deposit", options)
    end
    if options.direction == "storage_to_player" then
        return Client.RequestColonyAction("storage_player_withdraw", options)
    end
    return false, "invalid_direction"
end

function Client.DepositNPCItemToColony(npcId, itemID, quantity, revision, storageId)
    return Client.RequestColonyAction("storage_npc_deposit", {
        npcId = npcId,
        itemID = itemID,
        quantity = quantity,
        inventoryRevision = revision,
        storageId = storageId,
    })
end

function Client.DepositAllNPCItemsToColony(npcId, storageId)
    return Client.RequestColonyAction("storage_npc_deposit_all", {
        npcId = npcId,
        storageId = storageId,
    })
end

function Client.RenameColony(communityID, name)
    local player = Internal.GetPlayer()
    local args = {
        action = "rename",
        communityID = tostring(communityID or ""),
        name = tostring(name or ""),
    }
    if args.communityID == "" then return false, "invalid_community" end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_COLONY_MANAGEMENT_ACTION,
            args
        )
        return true
    end
    if not PNC.ColonyManagement
        or not PNC.ColonyManagement.RenameForPlayer
    then
        return false, "colony_management_unavailable"
    end
    local snapshot, result = PNC.ColonyManagement.RenameForPlayer(
        player,
        args
    )
    snapshot.actionResult = result
    ClientState.colonyManagement = snapshot
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
    return result and result.ok == true, result and result.reason
end

function Client.RenameFaction(name)
    return Client.RequestColonyAction("faction_rename", {
        name = tostring(name or ""),
    })
end

function Client.SetFactionEmblem(emblem)
    return Client.RequestColonyAction("faction_emblem", {
        emblem = type(emblem) == "table" and Core.DeepCopy(emblem) or emblem,
    })
end

return Client
