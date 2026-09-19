local T = require "tests/support/test"

local ready = false
local flushes = 0
local calls = {}

PNC = {
    Core = {
        Now = function() return 1000 end,
    },
    Client = {
        Internal = {
            IsWorldReady = function()
                return ready
            end,
        },
        EnsurePlayerBootstrap = function(now, forceKnowledge)
            calls[#calls + 1] = {
                name = "player",
                now = now,
                force = forceKnowledge,
            }
            return true, "sent"
        end,
        EnsureWorldDiscovery = function(now, force)
            calls[#calls + 1] = {
                name = "world",
                now = now,
                force = force,
            }
            return true, "sent"
        end,
    },
    KnowledgeInterest = {
        ConsumeFlush = function(now)
            flushes = flushes + 1
            T.equal(now, 1200, "knowledge flush used a different tick time")
            return true
        end,
    },
}

T.load(
    "ProjectHoomans",
    "client",
    "PNC/Networking/ClientRequests/PNC_ClientRequests_InitialStateTick.lua"
)

local pump = PNC.Client.Internal.PumpInitialStateRequests
local pumped, reason = pump(1100)
T.falsy(pumped, "initial-state requests ran before the world was ready")
T.equal(reason, "world_not_ready", "not-ready result was not explicit")
T.equal(flushes, 0, "not-ready tick consumed a pending knowledge flush")
T.equal(#calls, 0, "not-ready tick sent an initial-state request")

ready = true
pumped = pump(1200)
T.truthy(pumped, "ready tick did not pump initial-state requests")
T.equal(flushes, 1, "ready tick did not consume the pending knowledge flush")
T.equal(#calls, 2, "ready tick did not pump both initial-state services")
T.equal(calls[1].name, "player", "player bootstrap was not pumped first")
T.equal(calls[1].now, 1200, "player bootstrap used the wrong tick time")
T.truthy(calls[1].force, "knowledge flush did not force the player bootstrap")
T.equal(calls[2].name, "world", "world discovery was not pumped second")
T.equal(calls[2].now, 1200, "world discovery used the wrong tick time")
T.falsy(calls[2].force, "world discovery unexpectedly bypassed its retry gate")
T.equal(PNC.Client.Internal.InitialStateRequestDiagnostics.updatedAt, 1200,
    "request diagnostics did not record the shared tick timestamp")
T.equal(PNC.Client.Internal.InitialStateRequestDiagnostics.playerBootstrapReason,
    "sent", "request diagnostics lost the bootstrap result")
T.equal(PNC.Client.Internal.InitialStateRequestDiagnostics.worldDiscoveryReason,
    "sent", "request diagnostics lost the world-discovery result")
T.equal(PNC.Client.Internal.InitialStateRequestDiagnostics.playerBootstrapForcedByKnowledge,
    true, "request diagnostics lost the knowledge-flush cause")

T.finish("pnc_client_bootstrap_tick_smoke")
