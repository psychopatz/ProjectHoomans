local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local Inventory = PNC.Inventory
local ServerState = Network.ServerState

local function isLocalPlayer(player)
    local localPlayer = getSpecificPlayer and getSpecificPlayer(0) or nil
    return localPlayer ~= nil and player == localPlayer
end

local function inventoryRecipientKey(player)
    if Internal.PlayerKey then return Internal.PlayerKey(player) end
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    if player and player.getOnlineID then
        return tostring(player:getOnlineID())
    end
    return tostring(player)
end

local function inventoryRevision(payload)
    local inventory = payload and payload.inventory or nil
    return inventory and tonumber(inventory.revision
        or inventory.summary and inventory.summary.revision) or nil
end

function Network.TrackInventoryRecipient(targetPlayer, npcID, revision)
    local key
    local recipients
    local entry
    if not targetPlayer or not npcID then return false end
    key = inventoryRecipientKey(targetPlayer)
    recipients = ServerState.inventoryRecipients
    if not recipients then
        recipients = {}
        ServerState.inventoryRecipients = recipients
    end
    entry = recipients[key]
    if not entry then
        entry = { player = targetPlayer, revisions = {} }
        recipients[key] = entry
    else
        entry.player = targetPlayer
        entry.revisions = entry.revisions or {}
    end
    entry.revisions[tostring(npcID)] = tonumber(revision) or 0
    return true
end

function Network.SendCharacterPayload(targetPlayer, record)
    local payload
    local sent = false
    if not record then
        return false
    end
    if Inventory and Inventory.AdvanceFoodLifecycle then
        Inventory.AdvanceFoodLifecycle(record)
    end
    payload = Network.BuildCharacterPayload(record)
    if not payload then
        return false
    end
    if isServer and isServer() and targetPlayer and sendServerCommand then
        sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_CHARACTER_PAYLOAD, payload)
        sent = true
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_CHARACTER_PAYLOAD, payload)
        sent = true
    elseif isLocalPlayer(targetPlayer) and triggerEvent then
        -- Single-player can expose the server API without exposing the
        -- multiplayer command transport. Keep the local detail cache live.
        triggerEvent("OnServerCommand", Const.MODULE,
            Const.CMD_CHARACTER_PAYLOAD, payload)
        sent = true
    end
    if sent then
        Network.TrackInventoryRecipient(targetPlayer, payload.npcId,
            inventoryRevision(payload))
    end
    return sent
end

function Network.CanViewCharacter(player, record)
    local access
    local distance
    if not player or not record then
        return false
    end
    access = player.getAccessLevel and string.lower(tostring(player:getAccessLevel() or "")) or ""
    if access == "admin" then
        return true
    end
    if PNC.Identity and PNC.Identity.Verifier
        and PNC.Identity.Verifier.GetFactionID
        and PNC.Identity.Verifier.GetFactionID(record)
    then
        return PNC.Identity.Verifier.IsOwnedByPlayer(record, player)
    end
    if record.ownerUsername and player.getUsername and tostring(record.ownerUsername) == tostring(player:getUsername()) then
        return true
    end
    if math.floor(tonumber(player:getZ()) or 0) ~= math.floor(tonumber(record.z) or 0) then
        return false
    end
    distance = Core.Distance(player:getX(), player:getY(), record.x, record.y)
    return distance <= Const.CHARACTER_DETAIL_DISTANCE
end

function Network.SendInventoryDelta(targetPlayer, record, sinceRevision)
    local sent
    if Inventory and Inventory.AdvanceFoodLifecycle then
        Inventory.AdvanceFoodLifecycle(record)
    end
    local delta = Inventory and Inventory.BuildDeltaPayload and Inventory.BuildDeltaPayload(record, sinceRevision) or nil
    if not delta or delta.fullRequired == true then
        Network.SendCharacterPayload(targetPlayer, record)
        return false
    end
    sent = Internal.SendToPlayer(targetPlayer, Const.CMD_INVENTORY_DELTA, delta)
    if not sent and isLocalPlayer(targetPlayer) and triggerEvent then
        -- Same local-server fallback as SendCharacterPayload. This is used
        -- only for player 0, never as a server-wide broadcast.
        triggerEvent("OnServerCommand", Const.MODULE,
            Const.CMD_INVENTORY_DELTA, delta)
        sent = true
    end
    if sent then
        Network.TrackInventoryRecipient(targetPlayer, delta.npcId,
            delta.inventoryRevision)
    end
    return sent == true
end

-- Push only to clients which already have a detail payload for this NPC. The
-- inventory event bridge calls this after the current mutation stack returns,
-- so several same-tick operations become one ordered delta and a failed
-- transaction cannot expose an intermediate state to the UI.
function Network.PushInventoryDelta(record)
    local id = record and record.id and tostring(record.id) or nil
    local revision = record and record.inventory
        and tonumber(record.inventory.revision) or nil
    local recipients = ServerState.inventoryRecipients or {}
    local sent = 0
    local entry
    local since
    local key
    if not id or not revision then return 0 end
    for key, entry in pairs(recipients) do
        since = entry and entry.revisions and tonumber(entry.revisions[id])
        if entry and entry.player and since ~= nil and since < revision
            and (not Network.CanViewCharacter
                or Network.CanViewCharacter(entry.player, record) == true)
        then
            if Network.SendInventoryDelta(entry.player, record, since) then
                sent = sent + 1
            end
        elseif entry and entry.player and Network.CanViewCharacter
            and Network.CanViewCharacter(entry.player, record) ~= true
        then
            -- Keep the entry for an owner who may still view the NPC while
            -- remote, but do not send inventory data to an unauthorized view.
            recipients[key] = entry
        end
    end

    -- In single-player the API path can populate ClientState directly without
    -- passing through a server request. Reuse that local revision as the
    -- delta base instead of polling or rebuilding a full payload every frame.
    if sent == 0 and (not isServer or not isServer())
        and Network.ClientState and Network.ClientState.characterPayloads
    then
        local payload = Network.ClientState.characterPayloads[id]
        local cachedRevision = payload and payload.inventory
            and tonumber(payload.inventory.revision
                or payload.inventory.summary
                and payload.inventory.summary.revision) or nil
        local player = getSpecificPlayer and getSpecificPlayer(0) or nil
        if player and cachedRevision ~= nil and cachedRevision < revision
        then
            if Network.SendInventoryDelta(player, record, cachedRevision) then
                sent = sent + 1
            end
        end
    end
    return sent
end
