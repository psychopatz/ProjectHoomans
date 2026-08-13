local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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

assertEqual(Router.Handle("Revive", player, { id = "npc-1" }), true,
    "revive handled")
assertEqual(revived.player, player, "revive player")
assertEqual(revived.id, "npc-1", "revive id")

revived = nil
assertEqual(Router.Handle("Revive", player, nil), true,
    "malformed revive consumed")
assertEqual(revived, nil, "malformed revive invoked service")

local normalArgs = {
    id = "npc-2",
    partId = 4,
    debugFree = true,
    bandageType = "Base.Bandage",
}
assertEqual(Router.Handle("Bandage", player, normalArgs), true,
    "bandage handled")
assertEqual(bandaged.options.consumeItem, true,
    "non-admin debug-free bandage consumed no item")
assertEqual(bandaged.options.bandageType, "Base.Bandage",
    "bandage type changed")

player.access = "AdMiN"
Router.Handle("Bandage", player, normalArgs)
assertEqual(bandaged.options.consumeItem, false,
    "admin debug-free bandage consumed item")

bandaged = nil
Router.Handle("Bandage", player, { id = "npc-2" })
assertEqual(bandaged, nil, "malformed bandage invoked service")

local hitArgs = { id = "npc-3", damage = 7 }
assertEqual(Router.Handle("PlayerWeaponHit", player, hitArgs), true,
    "player hit handled")
assertEqual(hit.player, player, "player hit player")
assertEqual(hit.args, hitArgs, "player hit payload identity")

Router.Handle("PlayerWeaponHit", player, nil)
assertEqual(type(hit.args), "table", "nil player hit payload not normalized")

isServer = function() return false end
isDebugEnabled = function() return true end
assertEqual(Router.CanUseDebug(player), true, "SP debug flag ignored")
isDebugEnabled = nil
getCore = function()
    return { getDebug = function() return true end }
end
assertEqual(Router.CanUseDebug(player), true, "SP core debug flag ignored")

print("pnc_server_health_combat_command_handler_smoke: ok")
