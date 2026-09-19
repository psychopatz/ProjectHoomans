-- World-discovery request and freshness transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

local function isWorldReady()
    if Internal.IsWorldReady then return Internal.IsWorldReady() end
    return (not isIngameState) or isIngameState()
end

function Client.RequestWorldDiscovery(action, options)
    local player = Internal.GetPlayer()
    local args = type(options) == "table"
        and Core.DeepCopy(options) or {}
    args.action = tostring(action or "snapshot")
    local command = args.action == "snapshot"
        and Const.CMD_WORLD_DISCOVERY_REQUEST
        or Const.CMD_WORLD_DISCOVERY_ACTION
    ClientState.lastWorldDiscoveryRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(player, Const.MODULE, command, args)
        return true, "sent"
    end
    if not PNC.WorldDiscovery or not PNC.WorldDiscovery.HandleAction then
        return false, "discovery_service_unavailable"
    end
    local payload = PNC.WorldDiscovery.HandleAction(player, args)
    if Internal.ApplyWorldDiscoverySnapshot then
        Internal.ApplyWorldDiscoverySnapshot(payload)
    end
    return payload and payload.state == "known", payload
end

function Client.IsWorldDiscoveryCurrent()
    local snapshot = ClientState.worldDiscovery
    local context = ClientState.playerContext
    if type(snapshot) ~= "table" or snapshot.state ~= "known"
        or tostring(snapshot.characterUUID or "") == ""
    then
        return false
    end
    return not context or not context.characterUUID
        or tostring(snapshot.characterUUID)
            == tostring(context.characterUUID)
end

function Client.EnsureWorldDiscovery(now, force)
    now = tonumber(now) or Core.Now()
    if Client.IsWorldDiscoveryCurrent() then return true, "current" end
    if not isWorldReady() then return false, "world_not_ready" end
    local last = tonumber(ClientState.lastWorldDiscoveryRequestAt) or 0
    if force ~= true and last > 0 and now - last < 4000 then
        return false, "throttled"
    end
    return Client.RequestWorldDiscovery("snapshot")
end

return Client
