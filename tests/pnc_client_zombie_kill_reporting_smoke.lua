local T = require "tests/support/test"

T.addPackagePaths({
    { "PsychopatzCore", "common" },
})

local handlers = {}
local sent = {}

Events = {
    OnWeaponHitCharacter = {
        Add = function(handler) handlers.hit = handler end,
    },
    OnZombieDead = {
        Add = function(handler) handlers.dead = handler end,
    },
    OnClientCommand = {
        Add = function(handler) handlers.command = handler end,
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
}

isClient = function() return true end
isServer = function() return false end
instanceof = function(value, className)
    return (className == "IsoPlayer" and value.kind == "player")
        or (className == "IsoZombie" and value.kind == "zombie")
end
getPlayer = function() return player end
getSpecificPlayer = function() return player end
getTimeInMillis = function() return 1000 end
sendClientCommand = function(receivedPlayer, module, command, args)
    sent[#sent + 1] = {
        player = receivedPlayer,
        module = module,
        command = command,
        args = args,
    }
end

PsychopatzCore = {}
local Detector = require
    "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector"
T.truthy(Detector.RegisterConsumer("retirement_test", {}),
    "core detector installs without any Hoomans client consumer")
T.truthy(handlers.hit, "core detector owns the client hit observer")
T.truthy(handlers.dead, "core detector owns the zombie death observer")

handlers.hit(player, zombie, {}, 1)
T.equal(#sent, 0, "client hit observation does not send a kill report")
handlers.dead(zombie)
T.equal(#sent, 1, "pure client sends the authoritative death report")
T.equal(sent[1].player, player, "kill report uses the local player sender")
T.equal(sent[1].module, "PsychopatzCore",
    "kill report uses the core command module")
T.equal(sent[1].command, "ZombieKillReport",
    "kill report uses the core detector command")
T.equal(sent[1].args.zombieOnlineID, 42,
    "kill report carries the zombie online ID")
T.equal(sent[1].args.bodyInstanceID, 99,
    "kill report carries the body identity")
T.equal(sent[1].args.nativeZombieKills, 12,
    "kill report carries the native kill counter")

isServer = function() return true end
handlers.dead(zombie)
T.equal(#sent, 1,
    "SP/listen authority path does not duplicate the client report")

isServer = function() return false end
zombie.getAttackedBy = function() return nil end
Detector.ClientKillReports = {}
handlers.hit(player, zombie, {}, 1)
handlers.dead(zombie)
T.equal(#sent, 2,
    "MP reports a kill when replicated attackedBy is unavailable")
T.equal(sent[2].args.killerOnlineID, 7,
    "MP fallback uses the player from the weapon-hit event")

T.finish("pnc_client_zombie_kill_reporting_smoke")
