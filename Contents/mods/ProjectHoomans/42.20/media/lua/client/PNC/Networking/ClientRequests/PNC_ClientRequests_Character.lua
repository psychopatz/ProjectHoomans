-- Character payload and inventory hydration request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Client.RequestCharacterPayload(npcId, forceFull)
    local player = Internal.GetPlayer()
    local payload
    local cached
    local inventoryRevision
    if not npcId then
        return false
    end
    npcId = tostring(npcId)
    -- Standalone and host runtimes own the registry locally; only remote
    -- multiplayer clients need the server command round-trip.
    local multiplayerClient = Core and Core.IsClientOnly
        and Core.IsClientOnly() == true
    if not multiplayerClient and PNC.API and PNC.API.GetCharacterPayload then
        payload = PNC.API.GetCharacterPayload(npcId)
        if payload then
            ClientState.characterPayloads = ClientState.characterPayloads or {}
            ClientState.characterPayloads[npcId] = payload
            if payload.snapshot and payload.snapshot.id then
                ClientState.snapshots[tostring(payload.snapshot.id)] = payload.snapshot
                if PNC.Network.RefreshClientBodyIdentityIndex then
                    PNC.Network.RefreshClientBodyIdentityIndex()
                end
            end
            if Diagnostics and Diagnostics.InventoryAuditEnabled == true
                and Diagnostics.LogInventoryAudit
            then
                Diagnostics.LogInventoryAudit("client_local_payload_applied", {
                    "npc=" .. tostring(npcId),
                    "inventoryRevision=" .. tostring(payload.inventory
                        and payload.inventory.revision or ""),
                    "inventoryFull=" .. tostring(payload.inventoryFull == true),
                    "source=local_api",
                })
            end
            if PNC.InventoryWindow
                and PNC.InventoryWindow.OnInventoryPayloadApplied
            then
                PNC.InventoryWindow.OnInventoryPayloadApplied(
                    npcId,
                    payload.inventory and payload.inventory.revision,
                    "local_api"
                )
            end
            return true
        end
    end
    if not player or not sendClientCommand then
        return false
    end
    cached = ClientState.characterPayloads
        and ClientState.characterPayloads[npcId] or nil
    inventoryRevision = cached and cached.inventory
        and cached.inventory.summary
        and tonumber(cached.inventory.summary.revision) or nil
    sendClientCommand(player, Const.MODULE, Const.CMD_REQUEST_CHARACTER, {
        id = npcId,
        inventoryRevision = forceFull == true and nil or inventoryRevision,
        forceFull = forceFull == true,
    })
    return true
end

function Client.RequestCharacterInventoryPayload(npcId)
    local player = Internal.GetPlayer()
    local payload
    local requestID
    if not npcId then
        return false
    end
    npcId = tostring(npcId)
    ClientState.inventoryPayloadRequestSequence =
        (tonumber(ClientState.inventoryPayloadRequestSequence) or 0) + 1
    requestID = tostring(ClientState.inventoryPayloadRequestSequence)
    ClientState.pendingCharacterInventoryRequest = {
        npcId = npcId,
        requestID = requestID,
    }

    -- Standalone and host runtimes can build only the inventory section from
    -- their local registry. Remote clients request that same section from the
    -- server without constructing a detailed character snapshot.
    local multiplayerClient = Core and Core.IsClientOnly
        and Core.IsClientOnly() == true
    if not multiplayerClient and PNC.API
        and PNC.API.GetCharacterInventoryPayload
    then
        payload = PNC.API.GetCharacterInventoryPayload(npcId)
        if payload then
            payload.requestID = requestID
            if Internal.ApplyCharacterInventoryPayload then
                return Internal.ApplyCharacterInventoryPayload(
                    payload, "local_api") == true
            end
            ClientState.pendingCharacterInventoryRequest = nil
            return false
        end
    end
    if not player or not sendClientCommand then
        ClientState.pendingCharacterInventoryRequest = nil
        return false
    end
    sendClientCommand(player, Const.MODULE,
        Const.CMD_REQUEST_CHARACTER_INVENTORY, {
            id = npcId,
            requestID = requestID,
        })
    return true
end

return Client
