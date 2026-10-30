local T = require "tests/support/test"
T.addPackagePaths()

local body = {
    getOnlineID = function() return 77 end,
}
local other = {
    getOnlineID = function() return 88 end,
}
local zombies = { other, body }
local list = {
    size = function() return #zombies end,
    get = function(_, index) return zombies[index + 1] end,
}

PNC = {
    Const = {},
    Core = {
        Now = function() return 1000 end,
        IsAuthority = function() return false end,
    },
    Network = {
        Internal = {
            SendToInterestedNPC = function() return 0 end,
            SendToPlayer = function() return false end,
        },
    },
    WorldCensus = {
        FindByOnlineID = function()
            -- Fresh remote replicas may not have entered the bounded census
            -- yet. A miss must not terminate exact online-id resolution.
            return nil
        end,
    },
}

getCell = function()
    return {
        getZombieList = function() return list end,
    }
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Networking/PNC_Network_CombatEvents.lua"
)

T.equal(PNC.Network.FindZombieByOnlineID(77), body,
    "census miss prevented exact engine-list online-id recovery")
T.equal(PNC.Network.FindZombieByOnlineID(88), other,
    "fallback selected the wrong engine replica")
T.equal(PNC.Network.FindZombieByOnlineID(99), nil,
    "missing online id returned an unrelated zombie")

-- Ambiguous engine online IDs fail closed.
zombies[#zombies + 1] = {
    getOnlineID = function() return 77 end,
}
T.equal(PNC.Network.FindZombieByOnlineID(77), nil,
    "duplicate engine online ids were guessed")

return T.finish("pnc_online_id_lookup_fallback_smoke")
