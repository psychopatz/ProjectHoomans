local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local handlers = {}
local sent = {}
local logs = {}

Events = {
    OnWeaponHitCharacter = {
        Add = function(handler) handlers.hit = handler end,
    },
    OnZombieDead = {
        Add = function(handler) handlers.dead = handler end,
    },
}

local player = {
    kind = "player",
    getOnlineID = function() return 7 end,
    getPlayerNum = function() return 0 end,
    isLocalPlayer = function() return true end,
    getUsername = function() return "tester" end,
    getZombieKills = function() return 12 end,
}
local zombie = {
    kind = "zombie",
    getOnlineID = function() return 42 end,
    getPersistentOutfitID = function() return 99 end,
    getAttackedBy = function() return player end,
    isDead = function() return true end,
    isOnKillDone = function() return true end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}

isClient = function() return true end
isServer = function() return false end
instanceof = function(value, className)
    return (className == "IsoPlayer" and value.kind == "player")
        or (className == "IsoZombie" and value.kind == "zombie")
end
getPlayer = function() return player end
getSpecificPlayer = function() return player end
sendClientCommand = function(receivedPlayer, module, command, args)
    sent[#sent + 1] = {
        player = receivedPlayer,
        module = module,
        command = command,
        args = args,
    }
end

PNC = {
    Const = {
        MODULE = "PNC",
    },
    Core = {
        IsClientOnly = function() return true end,
        LogInfo = function(message) logs[#logs + 1] = message end,
    },
    Network = {
        GetZombieOnlineID = function(value) return value:getOnlineID() end,
    },
}

T.load("ProjectHoomans", "client", "PNC/PNC_ClientZombieKillAudit.lua")
T.truthy(handlers.hit, "client hit observer registered")
T.truthy(handlers.dead, "client death observer registered")

handlers.hit(player, zombie, {}, 1)
T.equal(#sent, 0, "client hit observation does not send a kill report")
handlers.dead(zombie)
T.equal(#sent, 1, "pure client sends the authoritative death report")
T.equal(sent[1].player, player, "kill report uses the local player sender")
T.equal(sent[1].module, "PsychopatzCore",
    "kill report uses the core command module")
T.equal(sent[1].command, "ZombieKillReport",
    "kill report uses the core detector command")
T.equal(sent[1].args.zombieOnlineID, 42, "kill report carries the zombie online ID")
T.equal(sent[1].args.bodyInstanceID, 99, "kill report carries the body identity")
T.equal(sent[1].args.nativeZombieKills, 12,
    "kill report carries the native kill counter")

isServer = function() return true end
handlers.dead(zombie)
T.equal(#sent, 1, "SP/listen authority path does not duplicate the client report")

isServer = function() return false end
zombie.getAttackedBy = function() return nil end
PsychopatzCore.ZombieKillDetector.ClientKillReports = {}
handlers.hit(player, zombie, {}, 1)
handlers.dead(zombie)
T.equal(#sent, 2, "MP reports a kill when replicated attackedBy is unavailable")
T.equal(sent[2].args.killerOnlineID, 7,
    "MP fallback uses the player from the weapon-hit event")
T.truthy(#logs >= 3, "client audit logs registration, hit, and death")

T.finish("pnc_client_zombie_kill_reporting_smoke")
