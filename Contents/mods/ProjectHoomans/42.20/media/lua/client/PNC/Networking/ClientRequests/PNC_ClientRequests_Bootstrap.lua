-- Player identity and NPC roster/bootstrap request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local KnowledgeInterest = PNC.KnowledgeInterest
    or require "PNC/Knowledge/PNC_KnowledgeInterest"

local BOOTSTRAP_RETRY_MS = 4000
local BOOTSTRAP_RETRY_MAX_MS = 30000

local function isWorldReady()
    if Internal.IsWorldReady then return Internal.IsWorldReady() end
    return (not isIngameState) or isIngameState()
end

local function applyKnowledgeSnapshot(snapshot, reason)
    if Internal.ApplyNPCKnowledgeSnapshot then
        return Internal.ApplyNPCKnowledgeSnapshot(snapshot, reason)
    end
    return false
end

function Client.RequestPlayerBootstrap()
    local player = Internal.GetPlayer()
    local args = {
        requestID = Internal.RequestID("bootstrap"),
        scope = "interest",
        npcIDs = KnowledgeInterest.CollectNPCIDs(true),
    }
    ClientState.lastBootstrapRequestAt = Core.Now()
    ClientState.bootstrapRetryAttempt =
        (tonumber(ClientState.bootstrapRetryAttempt) or 0) + 1
    ClientState.bootstrapState = "loading"
    ClientState.activeBootstrapRequestID = args.requestID
    ClientState.completedBootstrapRequestID = nil
    ClientState.pendingBootstrap = nil
    return Internal.DispatchIdentity(player,
        Const.CMD_PLAYER_BOOTSTRAP_REQUEST, args, "HandleBootstrap")
end

function Client.IsPlayerBootstrapCurrent()
    local context = ClientState.playerContext
    return ClientState.bootstrapState == "known"
        and type(context) == "table"
        and tostring(context.characterUUID or "") ~= ""
        and #KnowledgeInterest.CollectNPCIDs(true) == 0
end

-- NPC roster replication and per-player knowledge use different authority
-- paths. A successful roster must never suppress retries for a bootstrap that
-- ran before the persistent player identity was ready during world startup.
function Client.EnsurePlayerBootstrap(now, force)
    now = tonumber(now) or Core.Now()
    if Client.IsPlayerBootstrapCurrent() then
        return true, "current"
    end
    if not isWorldReady() then
        return false, "world_not_ready"
    end
    local last = tonumber(ClientState.lastBootstrapRequestAt) or 0
    local attempt = math.max(
        1,
        tonumber(ClientState.bootstrapRetryAttempt) or 1
    )
    local retryMS = math.min(
        BOOTSTRAP_RETRY_MAX_MS,
        BOOTSTRAP_RETRY_MS * (2 ^ math.min(attempt - 1, 3))
    )
    if force ~= true and last > 0 and now - last < retryMS then
        return false, "throttled"
    end
    return Client.RequestPlayerBootstrap()
end

local function requestFullSync()
    local player = Internal.GetPlayer()
    local syncID = Internal.RequestID("roster")
    if not isWorldReady() then
        return
    end
    ClientState.lastFullSyncRequestAt = Core.Now()
    if player and sendClientCommand then
        sendClientCommand(player, Const.MODULE, Const.CMD_FULL_SYNC_REQUEST, {
            requestID = syncID,
        })
        Client.EnsurePlayerBootstrap(Core.Now(), false)
        if Client.RequestWorldDiscovery then
            Client.RequestWorldDiscovery("snapshot")
        end
        return
    end
    if PNC.Registry and PNC.Network and PNC.Network.BuildSnapshot then
        ClientState.snapshots = {}
        PNC.Registry.ForEach(function(record)
            local snapshot = PNC.Network.BuildSnapshot(record)
            ClientState.snapshots[tostring(snapshot.id)] = snapshot
        end)
        if PNC.Network.RefreshClientBodyIdentityIndex then
            PNC.Network.RefreshClientBodyIdentityIndex()
        end
        ClientState.lastSyncReceiveAt = Core.Now()
        if Client.EnsurePlayerBootstrap then
            Client.EnsurePlayerBootstrap(Core.Now(), false)
        end
        if Client.RequestWorldDiscovery then
            Client.RequestWorldDiscovery("snapshot")
        end
    end
end

Client.RequestFullSync = requestFullSync

return Client
