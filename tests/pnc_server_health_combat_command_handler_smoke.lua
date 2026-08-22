local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local player = {
    access = "",
    getAccessLevel = function(self) return self.access end,
}
local revived
local bandaged
local hit

PNC = {
    Const = {
        CMD_REVIVE = "Revive",
        CMD_BANDAGE = "Bandage",
        CMD_PLAYER_WEAPON_HIT = "PlayerWeaponHit",
    },
    Revive = {
        Try = function(receivedPlayer, id)
            revived = { player = receivedPlayer, id = id }
        end,
    },
    Treatment = {
        TryBandage = function(receivedPlayer, id, partId, options)
            bandaged = {
                player = receivedPlayer,
                id = id,
                partId = partId,
                options = options,
            }
        end,
    },
    PlayerDamage = {
        HandleClientReport = function(receivedPlayer, args)
            hit = { player = receivedPlayer, args = args }
        end,
    },
}

isServer = function() return true end

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerHealthCombatCommandHandler"

T.equal(Router.Handle("Revive", player, { id = "npc-1" }), true,
    "revive handled")
T.equal(revived.player, player, "revive player")
T.equal(revived.id, "npc-1", "revive id")

revived = nil
T.equal(Router.Handle("Revive", player, nil), true,
    "malformed revive consumed")
T.equal(revived, nil, "malformed revive invoked service")

local normalArgs = {
    id = "npc-2",
    partId = 4,
    debugFree = true,
    bandageType = "Base.Bandage",
}
T.equal(Router.Handle("Bandage", player, normalArgs), true,
    "bandage handled")
T.equal(bandaged.options.consumeItem, true,
    "non-admin debug-free bandage consumed no item")
T.equal(bandaged.options.bandageType, "Base.Bandage",
    "bandage type changed")

player.access = "AdMiN"
Router.Handle("Bandage", player, normalArgs)
T.equal(bandaged.options.consumeItem, false,
    "admin debug-free bandage consumed item")

bandaged = nil
Router.Handle("Bandage", player, { id = "npc-2" })
T.equal(bandaged, nil, "malformed bandage invoked service")

local hitArgs = { id = "npc-3", damage = 7 }
T.equal(Router.Handle("PlayerWeaponHit", player, hitArgs), true,
    "player hit handled")
T.equal(hit.player, player, "player hit player")
T.equal(hit.args, hitArgs, "player hit payload identity")

Router.Handle("PlayerWeaponHit", player, nil)
T.equal(type(hit.args), "table", "nil player hit payload not normalized")

isServer = function() return false end
isDebugEnabled = function() return true end
T.equal(Router.CanUseDebug(player), true, "SP debug flag ignored")
isDebugEnabled = nil
getCore = function()
    return { getDebug = function() return true end }
end
T.equal(Router.CanUseDebug(player), true, "SP core debug flag ignored")
T.finish("pnc_server_health_combat_command_handler_smoke")

T.finish("pnc_server_health_combat_command_handler_smoke")
