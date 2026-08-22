local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Perception/PNC_Perception.lua"

PNC = {
    Const = {
        TARGET_IMMEDIATE_THREAT_RADIUS = 6,
        ZOMBIE_TARGET_RADIUS = 12,
        ROAM_TARGET_RADIUS = 12,
    },
    Core = {},
    SpatialIndex = {},
    Registry = {},
    Relationships = {},
    Stealth = {},
    Factions = {
        GetOrganizationalFactionID = function(record)
            return record
                and record.affiliation
                and record.affiliation.factionID
                or nil
        end,
    },
}

T.load(FILE)

local calls = 0
local playerTarget = {
    kind = "player",
    distSq = 4,
}
PNC.Perception.FindNearestEnemyPlayer = function()
    calls = calls + 1
    return playerTarget
end
PNC.Perception.FindNearestEnemyNPC = function() return nil end
PNC.Perception.FindBestEnemyZombie = function() return nil end

local affiliated = {
    affiliation = {
        factionID = "faction_enemy",
    },
    hostility = {
        attackPlayers = false,
        attackNPCs = false,
        attackZombies = false,
    },
}

T.truthy(
    PNC.Perception.ResolveHostileTarget(affiliated)
        == playerTarget,
    "affiliated hostile target skipped authoritative player check"
)
T.truthy(calls == 1,
    "affiliated hostile target did not evaluate players")

T.truthy(
    PNC.Perception.ResolveRoamingTarget(affiliated, 12)
        == playerTarget,
    "affiliated roaming target skipped authoritative player check"
)
T.truthy(calls == 2,
    "affiliated roaming target did not evaluate players")

local unaffiliated = {
    hostility = {
        attackPlayers = false,
        attackNPCs = false,
        attackZombies = false,
    },
}
T.truthy(
    PNC.Perception.ResolveHostileTarget(unaffiliated) == nil,
    "unaffiliated cached-neutral NPC evaluated players"
)
T.truthy(calls == 2,
    "legacy player hostility gate changed for unaffiliated NPC")
T.finish("pnc_faction_target_gate_smoke")

T.finish("pnc_faction_target_gate_smoke")
