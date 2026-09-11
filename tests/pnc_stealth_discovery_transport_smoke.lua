local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "client" } })

local commandHandler
local now = 1000
PNC = {
    Const = {
        CMD_STEALTH_DISCOVERY = "StealthDiscovery",
        STEALTH_INDICATOR_TIMEOUT_MS = 1500,
    },
    Core = { Now = function() return now end },
    Network = { ClientState = {} },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, handler)
                T.equal(command, "StealthDiscovery", "registered command")
                commandHandler = handler
            end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "client",
    "PNC/Networking/PNC_ClientStealthDiscovery.lua"
)

T.truthy(commandHandler, "stealth command handler")
T.truthy(commandHandler({
    sneaking = true,
    hasFollowingColonist = true,
    discovered = false,
    reason = "owner_hidden",
    revision = 2,
    ttlMs = 250,
}), "initial payload accepted")
T.equal(PNC.Network.ClientState.stealthDiscovery.discovered, false,
    "hidden payload")
T.equal(PNC.Network.ClientState.stealthDiscovery.hasFollowingColonist, true,
    "follower gate payload")
T.equal(PNC.Network.ClientState.stealthDiscovery.expiresAt, 1250,
    "client-relative stealth lease")

T.falsy(commandHandler({
    sneaking = true,
    hasFollowingColonist = true,
    discovered = true,
    reason = "owner_seen",
    revision = 1,
    ttlMs = 250,
}), "stale payload accepted")
T.equal(PNC.Network.ClientState.stealthDiscovery.revision, 2,
    "stale payload replaced state")

T.truthy(commandHandler({
    sneaking = true,
    hasFollowingColonist = true,
    discovered = true,
    reason = "owner_seen",
    revision = 3,
    ttlMs = 300,
}), "new payload rejected")
T.equal(PNC.Network.ClientState.stealthDiscovery.discovered, true,
    "discovery transition")

PNC.Client.Internal.ResetStealthDiscovery()
T.equal(PNC.Network.ClientState.stealthDiscovery, nil,
    "stealth state reset")

T.finish("pnc_stealth_discovery_transport_smoke")
