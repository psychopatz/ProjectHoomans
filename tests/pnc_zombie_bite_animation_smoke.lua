local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/")
    .. "Networking/PNC_ClientCombatCommands.lua"
local handlers = {}
local now = 1000
local played = {}
local variables = {}
local attacker = {
    faceThisObject = function() end,
    setBumpDone = function() end,
    setBumpedChr = function() end,
    setVariable = function(_, name, value)
        variables[name] = value
    end,
}
local target = {}

PNC = {
    Const = {
        CMD_ZOMBIE_REACTION = "zombie_reaction",
        CMD_ZOMBIE_BITE = "zombie_bite",
        CMD_FIREARM_SHOT = "firearm_shot",
        ZOMBIE_BITE_APPLY_DELAY_MS = 450,
        BITE_RELEASE_TIMEOUT_MS = 650,
    },
    Core = {
        Now = function() return now end,
    },
    Network = {
        ClientState = {
            snapshots = {
                npc_animation = { id = "npc_animation", runtime = {} },
            },
        },
        FindZombieByOnlineID = function(id)
            if id == 11 then return target end
            if id == 22 then return attacker end
            return nil
        end,
    },
    ZombieAggro = {
        BiteInternal = {
            ResolveVisualBumpType = function(woundType, biteBumpType)
                if woundType == "laceration" then return "AttackKnife" end
                return biteBumpType or "Bite"
            end,
        },
    },
    Animation = {
        PlayBump = function(_, _, bumpType)
            played[#played + 1] = bumpType
            return true, "test"
        end,
    },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, callback)
                handlers[command] = callback
            end,
        },
    },
}

T.load(FILE)

handlers.zombie_bite({
    attackerOnlineID = 22,
    targetOnlineID = 11,
    npcId = "npc_animation",
    phase = "start",
    bumpType = "Bite",
})
T.equal(#played, 0,
    "client played the attack animation before the authoritative hit")
T.equal(variables.PNCZombieBitingNPC, true,
    "client bite replica did not retain the impact animation gate")

now = 1450
handlers.zombie_bite({
    attackerOnlineID = 22,
    targetOnlineID = 11,
    npcId = "npc_animation",
    phase = "impact",
    bumpType = "AttackKnife",
    woundType = "laceration",
})
T.equal(played[1], "AttackKnife",
    "client did not play the replicated laceration animation")

T.finish("pnc_zombie_bite_animation_smoke")
