local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "server" } })

local now = 1000
local discovered = false
local sent = {}
local players = {}
local player = {
    getUsername = function() return "local-player" end,
    isDead = function() return false end,
    isSneaking = function() return true end,
}
players[1] = player

PNC = {
    Const = {
        CMD_STEALTH_DISCOVERY = "StealthDiscovery",
        STEALTH_INDICATOR_UPDATE_MS = 200,
        STEALTH_INDICATOR_HEARTBEAT_MS = 1000,
        STEALTH_INDICATOR_TIMEOUT_MS = 1500,
    },
    Core = {
        Now = function() return now end,
        ForEachPlayer = function(callback)
            for index = 1, #players do callback(players[index]) end
        end,
    },
    Network = {
        Internal = {
            PlayerKey = function(value) return value:getUsername() end,
            SendToPlayer = function(target, command, payload)
                sent[#sent + 1] = {
                    target = target, command = command, payload = payload,
                }
                return true
            end,
        },
    },
    Registry = {
        Data = {
            follower = {
                alive = true,
                tacticalClass = "colonist",
                recruited = true,
                ownerUsername = "local-player",
                orderSpec = {
                    kind = "follow",
                    ownerUsername = "local-player",
                },
            },
            roam_group = {
                alive = true,
                tacticalClass = "neutral",
                recruited = false,
                ownerUsername = "local-player",
                orderSpec = {
                    kind = "roam",
                    ownerUsername = "local-player",
                },
            },
        },
    },
    Stealth = {
        IsOwnerActuallySneaking = function() return true end,
        IsOwnerDiscovered = function()
            return discovered, discovered and "owner_seen" or "owner_hidden"
        end,
    },
}
isServer = function() return true end

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Stealth/PNC_ServerStealthDiscovery.lua"
)

local service = PNC.ServerStealthDiscovery
T.equal(service.Pump(now), 1, "initial stealth state was not sent")
T.equal(#sent, 1, "initial stealth packet count")
T.equal(sent[1].command, "StealthDiscovery", "stealth command")
T.equal(sent[1].payload.discovered, false, "hidden state")
T.equal(sent[1].payload.sneaking, true, "sneaking state")
T.equal(sent[1].payload.hasFollowingColonist, true,
    "colonist follower gate")

now = 1100
T.equal(service.Pump(now), 0, "pump ignored its update cadence")
T.equal(#sent, 1, "unchanged state sent too often")

now = 2000
T.equal(service.Pump(now), 1, "heartbeat state was not sent")
T.equal(#sent, 2, "heartbeat packet count")

discovered = true
now = 2200
T.equal(service.Pump(now), 1, "discovery transition was not sent")
T.equal(sent[3].payload.discovered, true, "discovered state")
T.equal(sent[3].payload.reason, "owner_seen", "discovery reason")

PNC.Registry.Data.follower = nil
now = 2400
T.equal(service.Pump(now), 1, "follower removal was not sent")
T.equal(sent[4].payload.hasFollowingColonist, false,
    "non-follower state")
T.equal(sent[4].payload.discovered, false,
    "non-follower discovery was not cleared")

T.finish("pnc_stealth_discovery_server_smoke")
