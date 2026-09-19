-- Character payload and inventory hydration request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
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
    if not sendClientCommand and PNC.API and PNC.API.GetCharacterPayload then
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
        return false
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

return Client
