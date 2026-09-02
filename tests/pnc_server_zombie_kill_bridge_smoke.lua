local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local hitCalls = 0
local deathCalls = 0
local logs = {}
local player = {
    kind = "player",
    getOnlineID = function() return 7 end,
    getUsername = function() return "tester" end,
    getZombieKills = function() return 12 end,
}
local zombie = {
    kind = "zombie",
    getOnlineID = function() return 42 end,
    getPersistentOutfitID = function() return 99 end,
    isDead = function() return true end,
    getHealth = function() return 0 end,
    getAttackedBy = function() return nil end,
}

isClient = function() return false end
isServer = function() return true end
instanceof = function(value, className)
    return (className == "IsoPlayer" and value.kind == "player")
        or (className == "IsoZombie" and value.kind == "zombie")
end

PNC = {
    Core = { LogInfo = function(message) logs[#logs + 1] = message end },
    Network = {
        GetZombieOnlineID = function() return 42 end,
        FindZombieByOnlineID = function(id) return id == 42 and zombie or nil end,
    },
    SocialEventHooks = {
        ThreatAttributions = {},
        ResolvePlayerKey = function() return "player:tester" end,
        OnPlayerWeaponHitThreat = function()
            hitCalls = hitCalls + 1
            return true, "threat_hit_recorded"
        end,
        OnThreatDied = function()
            deathCalls = deathCalls + 1
            return true, "neutralized_without_protection"
        end,
    },
    SocialEventHooksInternal = {
        IsPlayer = function(value) return value and value.kind == "player" end,
        IsZombie = function(value) return value and value.kind == "zombie" end,
        ThreatIDFor = function() return "42" end,
        WorldAgeHours = function() return 10 end,
    },
}

local Hooks = T.load("ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_ClientKill.lua")

local result, reason = Hooks.HandleClientZombieKill(player, zombie, {
    source = "client_report",
    nativeZombieKills = 12,
})
T.equal(result, true, "relationship adapter accepts a validated kill")
T.equal(reason, "neutralized_without_protection",
    "adapter returns the canonical social outcome")
T.equal(hitCalls, 1, "adapter creates attribution from the detected kill")
T.equal(deathCalls, 1, "adapter dispatches the canonical death path")

T.finish("pnc_server_zombie_kill_bridge_smoke")
