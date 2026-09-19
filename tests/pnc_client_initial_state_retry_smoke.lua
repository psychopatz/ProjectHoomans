local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local sent = {}
local warnings = {}

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_PLAYER_BOOTSTRAP_REQUEST = "PlayerBootstrapRequest",
        CMD_WORLD_DISCOVERY_REQUEST = "WorldDiscoveryRequest",
        CMD_WORLD_DISCOVERY_ACTION = "WorldDiscoveryAction",
        PRESENCE_LIVE = "live",
    },
    Core = {
        Now = function() return now end,
        IsClientOnly = function() return true end,
        LogWarn = function(message)
            warnings[#warnings + 1] = message
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
    Network = {
        ClientState = { snapshots = {} },
    },
    Client = {
        Internal = {
            IsWorldReady = function() return true end,
        },
    },
}

getSpecificPlayer = function()
    return { id = "player-1" }
end
sendClientCommand = nil

T.load("ProjectHoomans", "client", "PNC/Knowledge/PNC_KnowledgeInterest.lua")
T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientRequests/PNC_ClientRequests_Internal.lua")
T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientRequests/PNC_ClientRequests_Bootstrap.lua")
T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientRequests/PNC_ClientRequests_World.lua")
T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientRequests/PNC_ClientRequests_InitialStateTick.lua")

local Client = PNC.Client
local ClientState = PNC.Network.ClientState
local Interest = PNC.KnowledgeInterest
local pump = Client.Internal.PumpInitialStateRequests

T.truthy(Interest.Require("npc_retry", "retry_smoke"),
    "test knowledge interest was not queued")

-- A ready world may still lack its network transport during startup. The
-- failed request must leave the NPC ID pending so the bounded retry can send it.
now = 1200
T.truthy(pump(now), "ready tick stopped because transport was unavailable")
T.equal(#sent, 0, "missing transport unexpectedly sent a request")
T.equal(ClientState.bootstrapRetryAttempt, 1,
    "failed bootstrap attempt was not recorded for backoff")
T.equal(ClientState.lastWorldDiscoveryRequestAt, now,
    "failed world request did not retain its retry timestamp")
T.equal(Interest.Pending.npc_retry, "retry_smoke",
    "failed bootstrap cleared pending NPC knowledge")
T.falsy(Interest.FlushQueued,
    "tick did not consume the debounced interest flush")
local diagnostics = Client.Internal.InitialStateRequestDiagnostics
T.equal(diagnostics.updatedAt, now,
    "failed request diagnostics lost the shared tick timestamp")
T.equal(diagnostics.playerBootstrapResult, "deferred",
    "failed bootstrap was not recorded as deferred")
T.equal(diagnostics.playerBootstrapReason, "player_unavailable",
    "failed bootstrap lost its transport failure reason")
T.equal(diagnostics.playerBootstrapRequestID,
    ClientState.activeBootstrapRequestID,
    "failed bootstrap diagnostics lost its correlation ID")
T.equal(diagnostics.worldDiscoveryReason, "player_unavailable",
    "failed world-discovery lost its transport failure reason")
T.equal(diagnostics.playerBootstrapForcedByKnowledge, true,
    "diagnostics lost the knowledge-flush retry cause")
T.equal(#warnings, 2,
    "initial transport failures were not reported once per service")
T.truthy(string.find(warnings[1],
    "service=playerBootstrap result=deferred reason=player_unavailable",
    1, true), "bootstrap warning lost the safe failure reason")
T.truthy(string.find(warnings[1], "requestID=bootstrap:", 1, true),
    "bootstrap warning lost its correlation ID")
T.truthy(string.find(warnings[1], "forcedByKnowledge=true", 1, true),
    "bootstrap warning lost the flush trigger")

now = 1300
T.truthy(pump(now), "ready tick stopped during bootstrap backoff")
T.equal(#sent, 0, "request retry ignored the backoff window")
T.equal(ClientState.bootstrapRetryAttempt, 1,
    "throttled retry advanced the bootstrap attempt")
T.equal(#warnings, 2,
    "retry backoff repeated the same warning on every tick")

sendClientCommand = function(player, module, command, args)
    sent[#sent + 1] = {
        player = player,
        module = module,
        command = command,
        args = args,
    }
end
now = 5200
T.truthy(pump(now), "ready tick stopped when transport recovered")
T.equal(#sent, 2, "recovered transport did not retry both requests")
T.equal(sent[1].command, "PlayerBootstrapRequest",
    "bootstrap retry used the wrong command")
T.equal(sent[1].args.npcIDs[1], "npc_retry",
    "bootstrap retry lost the pending NPC interest")
T.equal(sent[2].command, "WorldDiscoveryRequest",
    "world-discovery retry used the wrong command")
T.equal(ClientState.bootstrapRetryAttempt, 2,
    "successful bootstrap retry was not recorded")
T.equal(diagnostics.playerBootstrapResult, "accepted",
    "recovered bootstrap was not recorded as accepted")
T.equal(diagnostics.playerBootstrapReason, "sent",
    "recovered bootstrap diagnostics lost its transport result")
T.equal(diagnostics.playerBootstrapRequestID,
    ClientState.activeBootstrapRequestID,
    "recovered bootstrap diagnostics lost its correlation ID")
T.equal(diagnostics.worldDiscoveryReason, "sent",
    "recovered world-discovery diagnostics lost its transport result")
T.falsy(diagnostics.playerBootstrapForcedByKnowledge,
    "diagnostics reported a stale knowledge-flush force")
T.equal(#warnings, 2,
    "successful retries emitted a failure warning")
T.equal(diagnostics.playerBootstrapLastWarningReason, nil,
    "successful bootstrap did not clear its warning dedupe state")
T.equal(diagnostics.worldDiscoveryLastWarningReason, nil,
    "successful discovery did not clear its warning dedupe state")

T.finish("pnc_client_initial_state_retry_smoke")
